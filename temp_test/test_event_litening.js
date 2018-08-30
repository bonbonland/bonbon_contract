/**
 * 测试使用websocket provider监听事件
 */
const config = require('../tools/config.js')
const Web3 = require('web3')
const abi = require('./abi.js')
const BN = require('bignumber.js')

let devChainWxHost = config.envConfig.DEV_CHAIN_WX_HOST
let ddzContractAddress = '0x46db52da1cf824c57ca666274dba9709f72446e6'

let web3 = new Web3(new Web3.providers.WebsocketProvider(devChainWxHost))

web3.eth.net.isListening()   //pre 1.0版本使用web3.isConnected()来判断
  .then(function (res) {
    console.log('wx server connected.')
  })
  .catch(function (err) {
    console.log('[ERROR] web3 not connected.')
    process.exit(1)
  })

let Ddz = new web3.eth.Contract(abi.ddzAbi, ddzContractAddress)

Ddz.events.onWithdraw({}, function (error, event) {
  console.log('on withdraw: ', event.returnValues)
  let playerName = web3.utils.toUtf8(event.returnValues.playerName)
  let playerAddress = event.returnValues.playerAddress
  let ethOut = new BN(event.returnValues.ethOut).div(1e18).toFixed(4)
  console.log(`${playerName} [${playerAddress}] had withdrew ${ethOut}eth out.`)
})

Ddz.events.onEndTx({}, function (error, event) {
  console.log('end Tx: ', event.returnValues)
  let playerName = web3.utils.toUtf8(event.returnValues.playerName)
  let playerAddress = event.returnValues.playerAddress
  let ethIn = new BN(event.returnValues.ethIn).div(1e18).toFixed(4)
  let keysBought = new BN(event.returnValues.keysBought).div(1e18).toFixed(4)
  console.log(`${playerName} [${playerAddress}] had bought ${keysBought}keys with ${ethIn}eth.`)
})