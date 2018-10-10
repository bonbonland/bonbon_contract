module.exports = function(done) {
  const config = require('../../tools/config.js')
  const TestSelfDestruct = artifacts.require('./practices/TestSelfDestruct')
  const Web3 = require('web3')
  const BN = require('bignumber.js')
  const web3 = new Web3(config.envConfig.DEV_CHAIN_HTTP_HOST)
  const accountA = '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'
  const accountB = '0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C'

  let run = async () => {
    let deployedTestSelfDestruct = await TestSelfDestruct.deployed()
    let contractAddress = deployedTestSelfDestruct.address

    let printContractInfo = async () => {
      let contractBalance = web3.utils.fromWei(await web3.eth.getBalance(contractAddress), 'ether')
      let num = await deployedTestSelfDestruct.getNum.call()
      let owner = await deployedTestSelfDestruct.owner.call()
      console.log('contract address is : ' + contractAddress, 'balance is ' + contractBalance)
      console.log('owner is : ' + owner)
      console.log('num is ' + num)
    }

    let sendEth2Contract = async () => {
      console.log('starting transfer eth to contract...')
      await deployedTestSelfDestruct.transfer({
        value: web3.utils.toWei('1', 'ether'),
      })
    }

    let printToBalance = async (_to) => {
      let toBalance = web3.utils.fromWei(await web3.eth.getBalance(_to), 'ether')
      console.log('to balance is ' + toBalance)

    }

    let testSelfDestruct = async (_to) => {
      console.log('starting test self destruct...')
      await deployedTestSelfDestruct.kill(_to)
    }

    //只能在合约内部调用
    let callSelfDestructDirectly = async (_to) => {
      console.log('starting call selfdestruct func outside the contract...')
      await deployedTestSelfDestruct.selfdestruct(_to)
    }

    await printContractInfo()

    // await sendEth2Contract()
    // await printContractInfo()

    // await printToBalance(accountA)
    await testSelfDestruct(accountA)
    // await printToBalance(accountA)
    await printContractInfo()

    // await printToBalance(accountA)
    // await callSelfDestructDirectly(accountA)
    // await printToBalance(accountA)
    // await printContractInfo()

    return done()
  }

  run().catch(err => done(err))
}