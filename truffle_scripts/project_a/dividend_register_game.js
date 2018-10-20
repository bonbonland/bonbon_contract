module.exports = function(done) {
  const BBT = artifacts.require('./project_a/BBT.sol')
  const Dividend = artifacts.require('./project_a/Dividend.sol')
  const Web3 = require('web3')
  const config =require('../../tools/config.js')
  const web3 = new Web3(config.envConfig.DEV_CHAIN_HTTP_HOST)
  const BN = require('bignumber.js')
  const accountA = '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'
  const accountB = '0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C'
  const accountC = '0x018649744e6e2a52fA8551749e5db938EfF11567'

  let args = process.argv
  let whitelistAddress = args.pop()

  let checkArgAddress = () => {
    if (! web3.utils.isAddress(whitelistAddress)) {
      console.log(whitelistAddress + ' is not a valid address.')
      process.exit(1)
    }
  }

  let run = async () => {
    //let deployedBBT = await BBT.deployed()
    let deployedDividend = await Dividend.deployed()

    let register = async (account) => {
      let ifRegistered = await deployedDividend.hasRegistered.call(account)
      if (!ifRegistered) {
        console.log(account + ' has not register. now register it.')
        await deployedDividend.register(account, {
          from: accountB.toLowerCase()
        })
      } else {
        console.log(account + ' already registered.')
      }
    }

    await register(whitelistAddress)

    return done()
  }

  checkArgAddress()
  run().catch(err => done(err))
}