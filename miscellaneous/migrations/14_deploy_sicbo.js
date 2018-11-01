const web3 = require('web3')
const Sicbo = artifacts.require('./bet/Sicbo.sol')
const Dividend = artifacts.require('./project_a/Dividend.sol')
const config = require('../tools/config.js')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let deployedDividend = await Dividend.deployed()
    let deployedSicbo = await deployer.deploy(Sicbo, deployedDividend.address, options)

    //register game to Dividend
    await deployedDividend.register(deployedSicbo.address)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
