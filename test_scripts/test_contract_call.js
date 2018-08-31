/**
 * call合约的公共方法（不需要发送交易）
 */
const config = require('../tools/config.js')
const Web3 = require('web3')
const abi = require('./abi.js')

let devChainHttpHost = config.envConfig.DEV_CHAIN_HTTP_HOST
let ddzContractAddress = '0x46db52da1cf824c57ca666274dba9709f72446e6'

let web3 = new Web3(devChainHttpHost)
let Ddz = new web3.eth.Contract(abi.ddzAbi, ddzContractAddress)

let callDdz = async function () {
  let name = web3.utils.asciiToHex('bbc')
  return await Ddz.methods.pIDxName_(name).call()
}

callDdz().then(playerId => console.log('player id is ', playerId))
