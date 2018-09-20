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
      let currentSnapshotId = await deployedBBT.currSnapshotId.call()
      //let circulation = await deployedBBT.circulation.call()

      console.log('current snapshot id is : ' + currentSnapshotId)
      console.log('accountA balance is : ' + accountABalance)
      console.log('accountB balance is : ' + accountBBalance)
      //console.log('circulation is : ' + circulation)
    }

    let printSnapshotInfo = async (snapshotId) => {
      let accountABalanceAt = new BN(await deployedBBT.balanceOfAt.call(accountA, new BN(snapshotId))).div(1e18).toFixed(4)
      let accountBBalanceAt = new BN(await deployedBBT.balanceOfAt.call(accountB, new BN(snapshotId))).div(1e18).toFixed(4)

      console.log('accountA balance at snap [' + snapshotId + '] is : ' + accountABalanceAt)
      console.log('accountB balance at snap [' + snapshotId + '] is : ' + accountBBalanceAt)
    }

    let testTransfer = async () => {
      console.log('starting test transfer.')
      await deployedBBT.transfer(accountB, new BN('100').mul(1e18), {
        from: accountA.toLowerCase(),
      })
    }

    let testMakeSnapshot = async () => {
      console.log('staring make snapshot.')
      await deployedBBT.snapshot({
        from: accountA.toLowerCase()
      })
    }

    await printInfo()
    // await testTransfer()
    // await printInfo()
    await testMakeSnapshot()
    // await testTransfer()
    // await printInfo()
    await printSnapshotInfo(1)

    return done()
  }

  run().catch(err => done(err))
}