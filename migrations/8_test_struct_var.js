const web3 = require('web3')
const TestGetStructVar = artifacts.require('./practices/TestGetStructVar.sol')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let deployedTestGetStructVar = await deployer.deploy(TestGetStructVar, options)

    let struct = await deployedTestGetStructVar.testStruct();
    // let structA = await deployedTestGetStructVar.testStruct('a'); //无法通过struct的key获取值

    console.log('strcut is', struct)  //返回的是一个数组
    //[ { [String: '123'] s: 1, e: 2, c: [ 123 ] }, 'test', true ]
    // console.log('struct a is', structA)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
