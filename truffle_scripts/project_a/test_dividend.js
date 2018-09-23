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

  let run = async () => {
    let deployedBBT = await BBT.deployed()
    let deployedDividend = await Dividend.deployed()

    let printInfo = async () => {
      let accountABalance = new BN(await deployedBBT.balanceOf.call(accountA)).div(1e18).toFixed(4)
      let accountBBalance = new BN(await deployedBBT.balanceOf.call(accountB)).div(1e18).toFixed(4)
      let currentSnapshotId = await deployedBBT.currSnapshotId.call()
      let circulation = await deployedBBT.circulation.call()

      console.log('accountA balance is : ' + accountABalance)
      console.log('accountB balance is : ' + accountBBalance)
      console.log('current snapshot id is : ' + currentSnapshotId)
      console.log('circulation is : ' + new BN(circulation).div(1e18).toFixed(4))
    }

    let printCirculationAt = async (snapshot) => {
      let circulationAt = await deployedBBT.circulationAt.call(new BN(snapshot))
      console.log('circulation at snap [' + snapshot + '] is : ' + new BN(circulationAt).div(1e18).toFixed(4))
    }

    let testTransfer = async () => {
      console.log('starting test transfer.')
      await deployedBBT.transfer(accountB, new BN('100').times(1e18).toString(), {
        from: accountA.toLowerCase(),
      })
    }

    let deposit = async (round) => {
      let inWhiteList = await deployedDividend.whitelist.call(accountA)
      if (!inWhiteList) {
        console.log('accountA is not in whitelist. now adding it.')
        await deployedDividend.addAddressToWhitelist(accountA, {
          //from: accountA.toLowerCase()  //这里测试Owner修饰, accountB才是默认创建合约的地址(owner)
          from: accountB.toLowerCase()
        })
      }
      console.log('!!! starting test dividend deposit.')
      await deployedDividend.deposit(round, {
        from: accountA.toLowerCase(),
        value: web3.utils.toWei('0.1', 'ether')
      })
    }

    let distribute = async (round) => {
      console.log('!!! starting test distribute')
      await deployedDividend.distribute(round, {
        from: accountA.toLowerCase(),
      })
    }

    let printDividendContractInfo = async () => {
      let balance = await web3.eth.getBalance(deployedDividend.address)
      console.log('dividend contract balance is : ' + new BN(balance).div(1e18).toFixed(4))
      let [roundId, dividend, isEnded] = await deployedDividend.currentRound_()
      console.log('dividend currentRound_ info :', 'round : ' + new BN(roundId).toString(), 'dividend : ' + new BN(dividend).div(1e18).toFixed(4), isEnded)
      let cumulativeDividend = await deployedDividend.cumulativeDividend()
      console.log('cumulativeDividend is : ' + new BN(cumulativeDividend).div(1e18).toFixed(4))
      let currentSnapshotId = await deployedBBT.currSnapshotId.call()
      console.log('current snapshot id is : ' + currentSnapshotId)
      let roundsCount = await deployedDividend.getRoundsCount.call()
      console.log('rounds count is : ' + roundsCount)
    }

    let printRoundInfo = async (round) => {
      let [snapshotId, dividend] = await deployedDividend.roundsInfo_(round)
      console.log('roundInfo [' + round + ']', 'snapshotId : ' + new BN(snapshotId).toString(), 'dividend : ' + new BN(dividend).div(1e18).toFixed(4))
    }

    let printPlayerDividend = async (account) => {
      let totalDividend = await deployedDividend.getPlayerTotalDividend.call(account)
      let leftDividend = await deployedDividend.getPlayerLeftDividend.call(account)
      console.log('total dividend is : ' + new BN(totalDividend).div(1e18).toFixed(4) + '. left dividend is : ' + new BN(leftDividend).div(1e18).toFixed(4))
    }

    let printPlayerRoundDividend = async (account, round) => {
      // let playerBalanceAt = new BN(await deployedBBT.balanceOfAt.call(account, 5)).div(1e18).toFixed(4)
      let dividend = new BN(await deployedDividend.getPlayerRoundDividend(account, round)).div(1e18).toFixed(4)
      console.log(`plyr round dividend round[${round}] is ${dividend}`)
      // console.log('ply balance at snapshot 5 is ' + playerBalanceAt)
    }

    let printPlayerBalanceRatio = async (account) => {
      let balance = new BN(await deployedBBT.balanceOf.call(account)).div(1e18).toFixed(4)
      let circulation = new BN(await deployedBBT.circulation.call()).div(1e18).toFixed(4)
      let ratio = balance / circulation;
      console.log(`balance is ${balance}, circulation is ${circulation}, ratio is ${ratio}`)
    }

    // await printInfo()
    // await testTransfer()
    // await printInfo()

    //test deposit and distribute
    // await printDividendContractInfo()
    // // await deposit(1)  //round = 1
    // // await deposit(4)
    // await distribute(1)
    // // await printRoundInfo(3)
    // await printDividendContractInfo()

    //test player dividend data and withdraw
    await printRoundInfo(1)
    await printPlayerRoundDividend(accountA, 1)
    // await printPlayerDividend(accountA)
    // await printPlayerBalanceRatio(accountA)

    return done()
  }

  run().catch(err => done(err))
}