module.exports = function(done) {
  const BBT = artifacts.require('./project_a/BBT.sol')
  const web3 = require('web3')
  const BN = require('bignumber.js')
  const accountA = '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'
  const accountB = '0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C'
  const accountC = '0x018649744e6e2a52fA8551749e5db938EfF11567'

  let run = async () => {
    let deployedBBT = await BBT.deployed()

    let setTeamAccount = async () => {
      let teamAccount = await deployedBBT.teamWallet.call()
      if (teamAccount === '0x0000000000000000000000000000000000000000') {
        console.log('team wallet is not set. now setting it to accountC.')
        await deployedBBT.setTeamWallet(accountC)
      } else {
        let teamAccountBalance = new BN(await deployedBBT.balanceOf.call(teamAccount)).div(1e18).toFixed(4)
        console.log('team wallet is : ' + teamAccount + ', balance is : ' + teamAccountBalance)
      }
    }

    let printInfo = async () => {
      let owner = await deployedBBT.owner.call()
      let circulation = new BN(await deployedBBT.circulation.call()).div(1e18).toFixed(4)
      let totalSupply = new BN(await deployedBBT.totalSupply.call()).div(1e18).toFixed(4)

      console.log('owner is : ' + owner)
      console.log('circulation is : ' + circulation + ', total supply is : ' + totalSupply)

      balanceOfAccountA = new BN(await deployedBBT.balanceOf.call(accountA)).div(1e18).toFixed(4)
      console.log('accountA [' + accountA + '] balance is : ' + balanceOfAccountA)
    }

    let testMine = async () => {
      inWhiteList = await deployedBBT.whitelist.call(accountA)
      if (!inWhiteList) {
        console.log('accountA is not in whitelist. now adding it.')
        await deployedBBT.addAddressToWhitelist(accountA, {
          //from: accountA.toLowerCase()  //这里测试Owner修饰, accountB才是默认创建合约的地址(owner)
          from: accountB.toLowerCase()
        })
      } else {
        console.log('accountA is in whitelist. now start test mine func.')
        await deployedBBT.mine(accountA, new BN('100').mul(1e18), {
          from: accountA.toLowerCase()  //accountA被添加进白名单了
        })
      }
    }

    let testRelease = async () => {
      console.log('test release.')
      await deployedBBT.release(accountA, new BN('200').mul(1e18), {
        //from: accountA.toLowerCase()  //accountA非owner，报错
        from: accountB.toLowerCase()  //accountB为owner
      })
    }

    let testReleaseAndUnlock = async () => {
      console.log('test releaseAndUnlock.')
      await deployedBBT.releaseAndUnlock(accountA, new BN('300').mul(1e18), {
        //from: accountA.toLowerCase()  //accountA非owner，报错
        from: accountB.toLowerCase()  //accountB为owner
      })
    }

    await setTeamAccount()
    await printInfo()
    //await testMine()
    // await testRelease()
    await testReleaseAndUnlock()
    await printInfo()

    //监听事件
    // let event = deployedBBT.UnlockTeamBBT()
    // event.watch(function (err, res) {
    //   console.log('event unlock', new BN(res.args.amount).div(1e18).toFixed(4))
    // })

    return done()
  }

  run().catch(err => done(err))
}