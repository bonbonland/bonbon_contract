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
      let currentSnapshotId = await deployedBBT.currSnapshotId.call()
      let circulation = await deployedBBT.circulation.call()

      console.log('current snapshot id is : ' + currentSnapshotId)
      console.log('circulation is : ' + new BN(circulation).div(1e18).toFixed(4))
    }

    let testMakeSnapshot = async () => {
      console.log('staring make snapshot.')
      await deployedBBT.snapshot({
        from: accountA.toLowerCase()
      })
    }

    let testReleaseAndUnlock = async () => {
      console.log('test releaseAndUnlock.')
      await deployedBBT.releaseAndUnlock(accountA, new BN('300').mul(1e18), {
        //from: accountA.toLowerCase()  //accountA非owner，报错
        from: accountB.toLowerCase()  //accountB为owner
      })
    }

    let printCirculationAt = async (snapshot) => {
      let circulationAt = await deployedBBT.circulationAt.call(new BN(snapshot))
      console.log('circulation at snap [' + snapshot + '] is : ' + new BN(circulationAt).div(1e18).toFixed(4))
    }

    await printInfo()
    await testMakeSnapshot()
    await testReleaseAndUnlock()
    // await printInfo()
    await printCirculationAt(1)

    return done()
  }

  run().catch(err => done(err))
}