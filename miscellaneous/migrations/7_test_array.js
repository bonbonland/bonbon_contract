const web3 = require('web3')
const TestArray = artifacts.require('./practices/TestArray.sol')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let deployedTestArray = await deployer.deploy(TestArray, options)

    //获取array所有元素
    for (let i=0; i < await deployedTestArray.getAddressesCount(); i++) {
      console.log(await deployedTestArray.addresses(i))
    }

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
