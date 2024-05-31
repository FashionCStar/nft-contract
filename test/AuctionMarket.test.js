require('chai')
    .use(require('chai-as-promised'))
    .should()

const {assert} = require('chai')

const StarSeasNFT = artifacts.require('./NFT/StarSeasNFT.sol')
const AuctionMarket = artifacts.require('./AuctionMarket.sol')
const SGEToken = artifacts.require("./SGE.sol")

contract('AuctionMarket contract', (accounts) => {
    let auctionMarket, starSeasNFT, sge, res
    let current
    let pre1, pre2, next1, next2
    before(async() => {
        auctionMarket = await AuctionMarket.deployed()
        starSeasNFT = await StarSeasNFT.deployed()
        sge = await SGEToken.deployed()
        pre1 = 1641408507 // Wed Jan 05 2022 18:48:27 GMT+0000
        pre2 = 1641494907 // Thu Jan 06 2022 18:48:27 GMT+0000
        current = Date.now()
        next1 = 1641840507 // Mon Jan 10 2022 18:48:27 GMT+0000
        next2 = 1641926907 // Tue Jan 11 2022 18:48:27 GMT+0000

        sge.transfer(accounts[0], web3.utils.toWei('1000', 'ether'))
        sge.transfer(accounts[1], web3.utils.toWei('1000', 'ether'))
        sge.transfer(accounts[2], web3.utils.toWei('1000', 'ether'))
    })
    it('mint token', async() => {
        await starSeasNFT.mint("token 0", {from: accounts[0]})
        await starSeasNFT.mint("token 1", {from: accounts[1]})
        await starSeasNFT.mint("token 2", {from: accounts[2]})
    })
    it('Create Auction', async() => {
        await auctionMarket.createAuction(0, 0, web3.utils.toWei('10', 'ether'), pre1, next1)
        await starSeasNFT.approve(auctionMarket.address, 0, {from: accounts[0]})
        await auctionMarket.createAuction(1, 1, web3.utils.toWei('15', 'ether'), pre1, next1, {from: accounts[1]})
        await starSeasNFT.approve(auctionMarket.address, 1, {from: accounts[1]})
        await auctionMarket.createAuction(2, 0, web3.utils.toWei('20', 'ether'), pre1, next1, {from: accounts[2]})
        await starSeasNFT.approve(auctionMarket.address, 2, {from: accounts[2]})
    })
    it('Bid Auction', async() => {

        await auctionMarket.Bidding(0, web3.utils.toWei('12', 'ether'), {from: accounts[1]})
        await auctionMarket.Bidding(0, web3.utils.toWei('13', 'ether'), {from: accounts[2]})
        res = await auctionMarket.auctions(0)
        if(res.currency.toString() == '1') {
            sge.approve(auctionMarket.address, web3.utils.toWei('50', 'ether'), {from: accounts[1]})
            sge.approve(auctionMarket.address, web3.utils.toWei('50', 'ether'), {from: accounts[2]})
        }
        await auctionMarket.Bidding(1, web3.utils.toWei('17', 'ether'), {from: accounts[2]})
        await auctionMarket.Bidding(1, web3.utils.toWei('18', 'ether'), {from: accounts[0]})
        res = await auctionMarket.auctions(1)
        if(res.currency.toString() == '1') {
            sge.approve(auctionMarket.address, web3.utils.toWei('50', 'ether'), {from: accounts[0]})
            sge.approve(auctionMarket.address, web3.utils.toWei('50', 'ether'), {from: accounts[2]})
        }
        await auctionMarket.Bidding(2, web3.utils.toWei('24', 'ether'), {from: accounts[0]})
        await auctionMarket.Bidding(2, web3.utils.toWei('25', 'ether'), {from: accounts[1]})
    })
    it('Withdraw Bid', async() => {
        await auctionMarket.WithdrawBid(0, {from: accounts[2]})
    })
    it('Complete Auction', async() => {
        await auctionMarket.completeAuction(1)
    })
    it('Cancel auction', async() => {
        await auctionMarket.CancelAuction(2, {from: accounts[2]})
    })
})