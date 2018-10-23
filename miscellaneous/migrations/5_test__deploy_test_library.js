const web3 = require('web3')
const TestLibrary = artifacts.require('./practices/TestLibrary.sol')

module.exports = function (deployer, network , accounts) {
  let options = {
    from: accounts[1],
    overwrite: true,
  }

  let run = async function () {
    let deployedTestLibrary = await deployer.deploy(TestLibrary, options)

    console.log('test add func: 1 + 2 = ' + await deployedTestLibrary.add.call('1', '2'))

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
