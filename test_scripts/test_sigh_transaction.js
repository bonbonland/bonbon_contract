/**
 * 测试通过私钥创建account对象发送raw transaction
 */
const config = require('../tools/config.js')
const Web3 = require('web3')

let accountAPriKey = config.envConfig.DEV_CHAIN_ACCOUNT_A_PRI_KEY
let devChainHttpHost = config.envConfig.DEV_CHAIN_HTTP_HOST

let addressA = '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'
let addressB = '0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C'

let web3 = new Web3(devChainHttpHost)
//注意这里需要加上0x开头，不然转出来的地址不一样
let accountA = web3.eth.accounts.privateKeyToAccount('0x' + accountAPriKey)

let rawTransaction = {
  "from": addressA, //测试下来改了这个from地址无效，因为signTrans的是AccountA对象
  "to": addressB,
  "value": web3.utils.toWei("0.001", "ether"),
  "gas": 200000,
}

// web3.eth.getBalance(addressA)
//   .then(res => console.log(res))

console.log(accountA)

accountA.signTransaction(rawTransaction)
  .then(signedTx => {
    web3.eth.sendSignedTransaction(signedTx.rawTransaction)
      .then(receipt => console.log("Transaction receipt: ", receipt))

  })
  .catch(err => console.error(err))


//todo 调用合约存在的方法

//todo 调用合约不存在的方法
