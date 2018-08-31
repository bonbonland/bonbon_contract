/**
 * 使用raw transaction触发合约的fallback方法
 */
const config = require('../tools/config.js')
const Web3 = require('web3')
const abi = require('./abi.js')
const BN =require('bignumber.js')

let accountAPriKey = config.envConfig.DEV_CHAIN_ACCOUNT_A_PRI_KEY
let devChainHttpHost = config.envConfig.DEV_CHAIN_HTTP_HOST
let testContractWithFallbackAddress = '0x6076a20adee11063f5037eb9a7df3f51e4a53cda'
// let testContractWithoutFallbackAddress = '0x6076a20adee11063f5037eb9a7df3f51e4a53cda'

let web3 = new Web3(devChainHttpHost)
//注意这里需要加上0x开头，不然转出来的地址不一样
let accountA = web3.eth.accounts.privateKeyToAccount('0x' + accountAPriKey)
let TestDeployed = new web3.eth.Contract(abi.testDeployedWithFallback, testContractWithFallbackAddress)

let senTransaction = async function () {
  let rawTransaction = {
    //from可以不用定义，就是发送交易的account自己
    to: TestDeployed.options.address,
    data: '', //留空触发fallback, (不能直接使用encodeAbi形式，会报方法不存在）
    gas: 5000000,
    gasPrice: web3.utils.toWei('1', 'gwei'),
    value: web3.utils.toWei('0.01', 'ether'),
  }

  //console.log(accountA)
  //console.log(rawTransaction)

  let signedTx = await accountA.signTransaction(rawTransaction)
  let receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction)
  console.log("Transaction receipt: ", receipt.transactionHash)
}

let getShare = async function () {
  let share = await TestDeployed.methods.share(accountA.address).call()
  console.log(accountA.address + ' share is ' + new BN(share).div(1e18).toFixed(4))
}

getShare()
  .then(senTransaction()
    .then(getShare))
