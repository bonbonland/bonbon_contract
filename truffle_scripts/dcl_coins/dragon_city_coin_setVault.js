module.exports = function(done) {
  const DragonCityCoin = artifacts.require('./dcl_coins/DragonCityCoin.sol')
  const Web3 = require('web3')
  const config =require('../../tools/config.js')
  const web3 = new Web3(config.envConfig.DEV_CHAIN_HTTP_HOST)
  const BN = require('bignumber.js')
  const accountA = '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'
  const accountB = '0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C'
  const accountC = '0x018649744e6e2a52fA8551749e5db938EfF11567'

  let run = async () => {
    let deployedDragonCityCoin = await DragonCityCoin.deployed()

    let setVault = async (account, amount) => {
      console.log(`setting [${amount}] coins to account [${account}].`)
      await deployedDragonCityCoin.setVault(account, amount)
    }

    await setVault(accountA, 1200)

    return done()
  }

  run().catch(err => done(err))
}