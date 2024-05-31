// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl/StarSeasAccessControl.sol";
import "./NFT/IStarSeasNFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Marketplace is Context {
    using SafeMath for uint256;
    enum Currency {
        ETH, 
        SGE
    }
    struct Offer {
        Currency currency;
        uint256 salePrice;
        address seller;
        uint256 startTime;
        uint256 endTime;
    }
    mapping(uint256 => Offer) public offers;
    IStarSeasNFT public StarSeasNFT;
    IERC20 public SGE;
    uint256 feePlus = 108;
    event setSelling(uint256 indexed tokenId);
    event sellingCanceled( uint256 indexed tokenId );
    event boughtNFT(uint256 indexed tokenId);
    constructor(address nftAddr_, address sgeAddr_) {
        StarSeasNFT = IStarSeasNFT(nftAddr_);
        SGE = IERC20(sgeAddr_);
    }
    function sellingNFT(uint256 tokenId_, Currency currency_,  uint256 salePrice_, uint256 startTime_, uint256 endTime_) public {
        require(StarSeasNFT.exists(tokenId_), "Marketplace.sellingNFT: TokenID does not exist");
        require(StarSeasNFT.ownerOf(tokenId_) == _msgSender(), "Marketplace.sellingNFT: Sender has to be the owner of token");
        require(offers[tokenId_].startTime == 0, "NFTMarketplace.sellingNFT: Cannot duplicate current offer");
        offers[tokenId_] = Offer({
            currency: currency_,
            salePrice: salePrice_,
            seller: _msgSender(),
            startTime: startTime_,
            endTime: endTime_
        });
        emit setSelling(tokenId_);
    }
    function buyingNFT(uint256 tokenId_) public payable {
        require(StarSeasNFT.exists(tokenId_), "Marketplace.buyingNFT: TokenID does not exist.");
        require(offers[tokenId_].salePrice != 0, "Marketplace.buyingNFT: Token is not in sale list.");
        require(StarSeasNFT.ownerOf(tokenId_) != msg.sender, "Marketplace.buyingNFT: Owner of nft can not buy his own nft.");
        Offer storage offer = offers[tokenId_];
        if(offer.currency == Currency.SGE) {
            require(SGE.allowance(_msgSender(), address(this)) >=  offer.salePrice.mul(feePlus).div(100), "Marketplace.confirmOffer: ERC20 token allowance is less than selling price.");
            SGE.transferFrom(msg.sender, offer.seller, offer.salePrice.mul(feePlus).div(100));
        } else {
            require(msg.value >= offer.salePrice.mul(feePlus).div(100), "Marketplace.buyingNFT: Buyer paid less than nft price." );
            payable(offer.seller).transfer(offer.salePrice.mul(feePlus).div(100));
        }
        StarSeasNFT.safeTransferFrom(StarSeasNFT.ownerOf(tokenId_), msg.sender, tokenId_);
        offers[tokenId_].salePrice = 0;
        offers[tokenId_].startTime = 0;
        offers[tokenId_].endTime = 0;
        emit boughtNFT(tokenId_);
    }
    function cancelSell(uint256 tokenId_) public {
        require(StarSeasNFT.exists(tokenId_), "Marketplace.cancelSell: TokenID does not exist.");
        require(offers[tokenId_].salePrice != 0, "Marketplace.cancelSell: Token is not in sale list.");
        require(_msgSender() == StarSeasNFT.ownerOf(tokenId_), "Marketplace.cancelSell: Only owner can cancel selling.");
        offers[tokenId_].salePrice = 0;
        offers[tokenId_].startTime = 0;
        offers[tokenId_].endTime = 0;
        emit sellingCanceled(tokenId_);
    }
}