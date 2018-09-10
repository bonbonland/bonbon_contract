const web3 = require('web3')
const LibSafeMath = artifacts.require('./practices/LibSafeMath.sol')
const TestLibraryNew = artifacts.require('./practices/TestLibraryNew.sol')

module.exports = function (deployer, network , accounts) {
  let options = {
    from: accounts[1],
    overwrite: true,
  }

  let run = async function () {
    await deployer.deploy(LibSafeMath)

    //link library
    deployer.link(LibSafeMath, TestLibraryNew)
    let deployedTestLibraryNew = await deployer.deploy(TestLibraryNew, options)

    console.log('test add func: 1 + 2 = ' + await deployedTestLibraryNew.add.call('1', '2'))

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
