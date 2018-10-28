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

    //把分红合约加入到bbt的snapshot白名单中去
    let deployedBBT = await BBT.deployed()
    console.log('adding dividend contract address to BBT snapshot whitelist.')
    await deployedBBT.addAddressToWhitelist(deployedDividend.address)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
