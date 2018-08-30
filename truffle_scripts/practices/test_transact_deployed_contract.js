module.exports = function(done) {
  const TestDeployed = artifacts.require('./practices/TestDeployed')
  const web3 = require('web3')
  const accountA = '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'
  const accountB = '0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C'

  TestDeployed.deployed().then(function (instance) {
    // instance.setFoo(web3.utils.toHex('bbb'), {
    //   // from: '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c',
    //   // gasPrice: web3.utils.toWei('1', 'gwei'),
    //   // gas: 5000000,
    //   // value: 0, //send eth
    // })
    instance.sendTransaction({
      //from这里的地址要转为小写，不然报错"TypeError: private key should be a Buffer"
      //account必须是truffle.js配置文件中已经导入了私钥配置好的address，不然无法签名
      from: accountB.toLowerCase(),
      // gasPrice: web3.utils.toWei('1', 'gwei'),
      // gas: 5000000,
      value: web3.utils.toWei('0.01', 'ether'), //send eth
    })
      .then(function (res) {
        console.log('transaction is finished, the tx_has is : ' + res.tx)
        done()
      })
      .catch(err => done(err))
  })
}