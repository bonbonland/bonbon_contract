/**
 * 使用raw transaction调用合约方法（send，需要发送交易）
 */
const config = require('../tools/config.js')
const Web3 = require('web3')
const abi = require('./abi.js')

let accountAPriKey = config.envConfig.DEV_CHAIN_ACCOUNT_A_PRI_KEY
let devChainHttpHost = config.envConfig.DEV_CHAIN_HTTP_HOST
let ddzContractAddress = '0x46db52da1cf824c57ca666274dba9709f72446e6'

let web3 = new Web3(devChainHttpHost)
//注意这里需要加上0x开头，不然转出来的地址不一样
let accountA = web3.eth.accounts.privateKeyToAccount('0x' + accountAPriKey)
let Ddz = new web3.eth.Contract(abi.ddzAbi, ddzContractAddress)

let senTransaction = async function () {
  let buyXnameParams = [  //合约的buyXname方法的参数
    web3.utils.asciiToHex(''),  //推荐人
    0,  //team0
  ]
  let buyXnameOptions = {
    from: accountA.address,
    value: web3.utils.toWei('0.1', 'ether')   //方法实际调用时如果需要传value，那么estimateGas的时候也需要传options进去
  }

  //estimateGas是异步获取的，必须使用await
  let estimatedGas = await Ddz.methods.buyXname(...buyXnameParams).estimateGas(buyXnameOptions)

  let rawTransaction = {
    //from可以不用定义，就是发送交易的account自己
    to: Ddz.options.address,
    data: Ddz.methods.buyXname(...buyXnameParams).encodeABI(),
    gas: estimatedGas,
    gasPrice: web3.utils.toWei('1', 'gwei'),
    value: buyXnameOptions.value, //这里的value应该与estimateGas的值一样
  }

  //console.log(accountA)
  //console.log(rawTransaction)

  let signedTx = await accountA.signTransaction(rawTransaction)
  let receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction)
  console.log("Transaction receipt: ", receipt)
}

senTransaction()




//todo 调用合约存在的方法

//todo 调用合约不存在的方法
