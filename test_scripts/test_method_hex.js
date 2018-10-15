const Web3 = require('web3')
let a = Web3.utils.soliditySha3('createOrder(address,uint256,uint256,uint256)').substring(0,10)
//中间没有逗号
console.log(a)