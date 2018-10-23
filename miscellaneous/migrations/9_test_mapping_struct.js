const web3 = require('web3')
const TestMappingStruct = artifacts.require('./practices/TestMappingStruct.sol')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let deployedTestMappingStruct = await deployer.deploy(TestMappingStruct, options)

    let mappingStruct1 = await deployedTestMappingStruct.testMappingStruct(1);
    // let mappingStruct = await deployedTestMappingStruct.testMappingStruct();
    //Error: Invalid number of arguments to Solidity function  //需要指定mapping key获取
    let mappingStruct6 = await deployedTestMappingStruct.testMappingStruct(6);  //获取不存在的key

    console.log('mappingStruct1 is', mappingStruct1)  //返回的是指定元素的struct数组
    //[ { [String: '2'] s: 1, e: 0, c: [ 2 ] }, '2', true ]

    // console.log('mappingStruct is', mappingStruct)

    console.log('mappingStruct6 is', mappingStruct6)  //也可以返回结果，只不过结果是默认值
    //[ { [String: '0'] s: 1, e: 0, c: [ 0 ] }, '', false ]

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
