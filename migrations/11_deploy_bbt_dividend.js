const web3 = require('web3')
const Dividend = artifacts.require('./project_a/Dividend.sol')
const BBT = artifacts.require('./project_a/BBT.sol')
const config = require('../tools/config.js')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let BBTAddress = BBT.address;
    console.log('bbt address is : ' + BBTAddress)
    let deployedDividend = await deployer.deploy(Dividend, BBTAddress, options)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
