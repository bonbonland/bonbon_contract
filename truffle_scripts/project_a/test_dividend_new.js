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
    // let deployedBBT = await BBT.deployed()
    let deployedDividend = await Dividend.deployed()

    let printBalance = async (account) => {
      let balance = new BN(await web3.eth.getBalance(account)).div(1e18).toFixed(4)
      console.log(account + ' balance is : ' + balance)
      return balance
    }

    let withdraw = async (gameId, fromAccount) => {
      console.log(`starting withdraw gameId : ${gameId} to account : ${fromAccount}`)
      await deployedDividend.withdraw(gameId, {
        from: fromAccount.toLowerCase(),
      })
    }

    let getPlyLeftDividend = async (gameId, account) => {
      let leftDividend = new BN(await deployedDividend.getPlayerLeftDividend.call(gameId, account)).div(1e18).toFixed(4)
      console.log(`${account} gameId : ${gameId} left dividend : ${leftDividend}`)
    }

    let getPlyWithdrew = async (gameId, account) => {
      let withdrewDividend = new BN(await deployedDividend.playersWithdrew_.call(gameId, account)).div(1e18).toFixed(4)
      console.log(`${account} gameId : ${gameId} withdrew dividend : ${withdrewDividend}`)
    }

    // await printBalance(accountA)
    // await withdraw(2, accountA)
    // await printBalance(accountA)
    await getPlyLeftDividend(2, accountA)
    await getPlyWithdrew(2, accountA)

    return done()
  }

  run().catch(err => done(err))
}