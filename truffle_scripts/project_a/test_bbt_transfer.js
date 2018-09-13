module.exports = function(done) {
  const BBT = artifacts.require('./project_a/BBT.sol')
  const web3 = require('web3')
  const BN = require('bignumber.js')
  const accountA = '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'
  const accountB = '0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C'
  const accountC = '0x018649744e6e2a52fA8551749e5db938EfF11567'

  let run = async () => {
    let deployedBBT = await BBT.deployed()

    let printInfo = async () => {
      let accountABalance = new BN(await deployedBBT.balanceOf.call(accountA)).div(1e18).toFixed(4)
      let accountBBalance = new BN(await deployedBBT.balanceOf.call(accountB)).div(1e18).toFixed(4)

      console.log('accountA balance is : ' + accountABalance)
      console.log('accountB balance is : ' + accountBBalance)
    }

    let testTransfer = async () => {
      console.log('starting test transfer.')
      await deployedBBT.transfer(accountB, new BN('100').mul(1e18), {
        from: accountA.toLowerCase(),
      })
    }

    await printInfo()
    await testTransfer()
    await printInfo()

    return done()
  }

  run().catch(err => done(err))
}