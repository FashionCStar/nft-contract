require('chai')
    .use(require('chai-as-promised'))
    .should()

const {assert} = require('chai')

const StarSeasNFT = artifacts.require('./NFT/StarSeasNFT.sol')
const Marketplace = artifacts.require('./Marketplace.sol')
const SGEToken = artifacts.require("./SGE.sol")

contract('Marketplace Contract', (accounts) => {
    let endTime = 1741720242092
    let marketplace, starSeasNFT, sge, res
    before(async() => {
        starSeasNFT = await StarSeasNFT.deployed()
        marketplace = await Marketplace.deployed()
        sge = await SGEToken.deployed()
    })
    it('mint token', async() => {
        await starSeasNFT.mint("token 0", {from: accounts[0]})
        await starSeasNFT.mint("token 1", {from: accounts[1]})
        await starSeasNFT.mint("token 2", {from: accounts[2]})
    })
    it('Create Offer', async() => {
        await starSeasNFT.approve(marketplace.address, 0, {from: accounts[0]})
        await marketplace.sellingNFT(0, 0, web3.utils.toWei('10', 'ether'), Date.now(), endTime, {from: accounts[0]})

        await starSeasNFT.approve(marketplace.address, 1, {from: accounts[1]})
        await marketplace.sellingNFT(1, 1, web3.utils.toWei('10', 'ether'), Date.now(), endTime, {from: accounts[1]})

        await starSeasNFT.approve(marketplace.address, 2, {from: accounts[2]})
        await marketplace.sellingNFT(2, 0, web3.utils.toWei('20', 'ether'), Date.now(), endTime, {from: accounts[2]})
    })
    it('Cancel Selling Offer', async() => {
        await marketplace.cancelSell(0)
        res = await marketplace.offers(0)
    })
    it('Try buying selling-canceled token', async() => {
        await marketplace.buyingNFT(0)
    })
    it('Buying NFT', async() => {
        let offer = await marketplace.offers(1)
        res = await sge.balanceOf(accounts[0])
        console.log('Accounts[0] SGE Balance: ', res.toString())
        await sge.approve(marketplace.address, offer.salePrice)
        await marketplace.buyingNFT(1)
        res = await marketplace.offers(1)
        console.log('bought nft price: ', res.salePrice.toString())
        console.log('bought nft start time: ', res.startTime.toString())
        console.log('bought nft end time: ', res.endTime.toString())

        res = await marketplace.offers(2)
        console.log('selling nft price: ', res.salePrice.toString())
        console.log('selling nft start time: ', res.startTime.toString())
        console.log('selling nft end time: ', res.endTime.toString())
    })
})