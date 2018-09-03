const web3 = require('web3')
const TestCaller = artifacts.require('./bonbon_storage/TestCaller.sol')
const DdzShareAccount = artifacts.require('./bonbon_storage/DdzShareAccount.sol')

let gameName = web3.utils.toHex('ddz')

module.exports = function (deployer, network , accounts) {
  let options = {
    from: accounts[1],
    overwrite: true,
  }

  deployer.deploy(DdzShareAccount, options)
    .then(function (instance) {
      //console.log('ddz account address : ' + instance.address)
      // deployer.deploy(TestCaller, gameName, instance.address, options)
      //这里注意，必须要有promise被return，不然只有第一个contract被部署，且此脚本执行会卡住
      //可以直接return deployer.deploy(), 或者自定义promise。注意不要使用await
      return deployer.deploy(TestCaller, gameName, instance.address, options)
      // return new Promise(function (resolve, reject) {
      //   resolve()
      // });
    })
};
