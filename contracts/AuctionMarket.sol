// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT/IStarSeasNFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AuctionMarket is Context{
    using SafeMath for uint256;
    uint256 feePlus = 108;
    IStarSeasNFT public StarSeasNFT;
    IERC20 public SGE;
    enum Currency {
        ETH, 
        SGE
    }
    struct Auction {
        Currency currency;
        uint256 auctionPrice;
        address creater;
        uint256 startTime;
        uint256 endTime;
    }
    mapping(uint256 => Auction) public auctions;
    struct HighestBid {
        uint256 bidPrice;
        address bidder;
        uint256 bidTime;
    }
    mapping(uint256 => HighestBid) public highestBids;
    event AuctionCreated(uint256 tokenId, Currency currency_, uint256 auctionPrice_, uint256 start_, uint256 end_, address creator_);
    event Bid(uint256 tokenId_, uint256 bidPrice_, address bidder_);
    event WithdrewBid(uint256 tokenId_, address bidder_);
    event CompletedAuction(uint256 tokenId_, address winner_, Currency currency_, uint256 bidPrice_);
    event CanceledAuction(uint256 tokenId_);
    constructor(address nftAddr_, address sgeAddr_) {
        StarSeasNFT = IStarSeasNFT(nftAddr_);
        SGE = IERC20(sgeAddr_);
    }
    function createAuction(uint256 tokenId_, Currency currency_, uint256 auctionPrice_, uint256 startTime_, uint256 endTime_) public {
        require(StarSeasNFT.exists(tokenId_), "Auction.createAuction: TokenID does not exist");
        require(StarSeasNFT.ownerOf(tokenId_) == _msgSender(), "Auction.createAuction: Sender has to be the owner of token");
        require(auctions[tokenId_].auctionPrice == 0, "Auction.createAuction: NFT is already in auction list");
        auctions[tokenId_] = Auction({
            currency: currency_,
            auctionPrice: auctionPrice_,
            creater: _msgSender(),
            startTime: startTime_,
            endTime: endTime_
        });
        emit AuctionCreated(tokenId_, currency_, auctionPrice_, startTime_, endTime_, _msgSender());
    }
    function Bidding(uint256 tokenId_, uint256 bidPrice_) public {
        require(StarSeasNFT.exists(tokenId_), "Auction.Bidding: TokenID does not exist");
        require(StarSeasNFT.ownerOf(tokenId_) != _msgSender(), "Auction.Bidding: Owner can not bid on auction created by himself.");
        require(auctions[tokenId_].auctionPrice != 0, "Auction.Bidding: NFT is not in auction list");
        HighestBid storage highestBid = highestBids[tokenId_];
        require(bidPrice_ > highestBid.bidPrice, "Auction.Bidding: New bid price has to be greater than the highest bid price");
        highestBids[tokenId_].bidPrice = bidPrice_;
        highestBids[tokenId_].bidder = _msgSender();
        highestBids[tokenId_].bidTime = block.timestamp;
        emit Bid(tokenId_, bidPrice_, _msgSender());
    }
    function WithdrawBid(uint256 tokenId_) public {
        require(StarSeasNFT.exists(tokenId_), "Auction.WithdrawBid: TokenID does not exist");
        require(_msgSender() == highestBids[tokenId_].bidder, "Auction.WithdrawBid: Only highest bidder can withdraw his own bid.");
        Auction storage auction = auctions[tokenId_];
        require(block.timestamp < auction.endTime, "Auction.WithdrawBid: Auction is already finished.");
        highestBids[tokenId_].bidPrice = auction.auctionPrice;
        highestBids[tokenId_].bidder = address(0);
        highestBids[tokenId_].bidTime = block.timestamp;
        emit WithdrewBid(tokenId_, _msgSender());
    }
    function completeAuction(uint256 tokenId_) public payable{
        require(StarSeasNFT.exists(tokenId_), "Auction.completeAuction: TokenID does not exist");
        require(auctions[tokenId_].auctionPrice > 0, "Auction.completeAuction: This auction does not exist");
        Auction storage auction = auctions[tokenId_];
        // require(block.timestamp > auction.endTime, "Auction.completeAuction: Now is not yet auction ending time.");
        require(highestBids[tokenId_].bidPrice > auction.auctionPrice, "Auction.completeAuction: Nobody bidded this auction.");
        HighestBid storage highestBid = highestBids[tokenId_];
        if(auction.currency == Currency.SGE) {
            require(SGE.allowance(highestBid.bidder, address(this)) >= highestBid.bidPrice.mul(feePlus).div(100), "Auction.completeAuction: SGE token allowance is less than bid price.");
            SGE.transferFrom(highestBid.bidder, auction.creater, highestBid.bidPrice.mul(feePlus).div(100));
        } else {
            require(msg.value >= highestBid.bidPrice.mul(feePlus).div(100), "Auction.completeAuction: Bidder paid less than bid price.");
            payable(auction.creater).transfer(highestBid.bidPrice.mul(feePlus).div(100));
        }
        StarSeasNFT.safeTransferFrom(auction.creater, highestBid.bidder, tokenId_);
        
        auctions[tokenId_].auctionPrice = 0;
        auctions[tokenId_].creater = address(0);
        auctions[tokenId_].startTime = 0;
        auctions[tokenId_].endTime = 0;

        highestBids[tokenId_].bidPrice = 0;
        highestBids[tokenId_].bidder = address(0);
        highestBids[tokenId_].bidTime = 0;
        emit CompletedAuction(tokenId_, highestBid.bidder, auction.currency, highestBid.bidPrice);
    }
    function CancelAuction(uint256 tokenId_) public {
        require(StarSeasNFT.exists(tokenId_), "Auction.CancelAuction: TokenID does not exist");
        require(auctions[tokenId_].auctionPrice > 0, "Auction.CancelAuction: This auction does not exist");
        Auction storage auction = auctions[tokenId_];
        require(_msgSender() == auction.creater, "Auction.CancelAuction: Only auction creator can cancel his own auction.");
        require(block.timestamp < auction.endTime, "Auction.CancelAuction: Auction is already ended.");

        HighestBid storage highestBid = highestBids[tokenId_];
        if(highestBid.bidPrice > auctions[tokenId_].auctionPrice) {
            highestBids[tokenId_].bidPrice = 0;
            highestBids[tokenId_].bidder = address(0);
            highestBids[tokenId_].bidTime = 0;
        }

        auctions[tokenId_].auctionPrice = 0;
        auctions[tokenId_].creater = address(0);
        auctions[tokenId_].startTime = 0;
        auctions[tokenId_].endTime = 0;

        emit CanceledAuction(tokenId_);
    }
}   