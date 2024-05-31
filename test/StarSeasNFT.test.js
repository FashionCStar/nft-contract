require('chai')
    .use(require('chai-as-promised'))
    .should()

const {assert} = require('chai')

const StarSeasNFT = artifacts.require('./NFT/StarSeasNFT.sol')
const AccessControl = artifacts.require('./AccessControl/StarSeasAccessControl.sol')
contract('StarSeasNFT', (accounts) => {
    let starSeasNFT, accessControl, res
    before(async() => {
        starSeasNFT = await StarSeasNFT.deployed()
        accessControl = await AccessControl.deployed()
    })
    it('mint NFT', async() => {
        res = await starSeasNFT.mint("token 1")
        assert.equal(res.logs[0].args.to, accounts[0], 'To address is correct')
        console.log(res.logs[0].args)
        res = await starSeasNFT.mint("token 2")
        assert.equal(res.logs[0].args.tokenId, 1, 'Token Id is correct')
        console.log(res.logs[0].args)
        res = await starSeasNFT.mint("token 3")
        console.log(res.logs[0].args)
    })
    it('set base uri', async() => {
        await starSeasNFT.setBaseURI('https://ipfs/')
        res = await starSeasNFT.tokenURI(0)
        assert.equal(res, 'https://ipfs/0', 'Token 0 URI is correct')
        res = await starSeasNFT.tokenURI(1)
        assert.equal(res, 'https://ipfs/1', 'Token 0 URI is correct')
        res = await starSeasNFT.tokenURI(2)
        assert.equal(res, 'https://ipfs/2', 'Token 0 URI is correct')
    })
    it('Access Controller Test', async() => {
        res = await starSeasNFT.accessControls.call()
        assert.equal(res, accessControl.address, 'StarSeasNFT contract has admin role')
    })
    it('burn test', async() => {
        res = await starSeasNFT.tokenAmount()
        assert.equal(res, 3, 'Amount of NFT is correct before burnning')
        await starSeasNFT.burn(0)
        res = await starSeasNFT.tokenAmount()
        assert.equal(res, 2, 'Amount of NFT is correct after burnning')
    })
    it('Is approved', async() => {
        res = await starSeasNFT.showOwners(0)
        console.log(res.toString())
    })
})