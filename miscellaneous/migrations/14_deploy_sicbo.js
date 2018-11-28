const web3 = require('web3')
const Sicbo = artifacts.require('./bet/Sicbo.sol')
const Dividend = artifacts.require('./project_a/Dividend.sol')
const PlayerAffiliate = artifacts.require('./bet/PlayerAffiliate.sol')
const config = require('../tools/config.js')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let deployedDividend = await Dividend.deployed()
    let deployedPlayerAffiliate = await PlayerAffiliate.deployed()
    let deployedSicbo = await deployer.deploy(Sicbo, deployedDividend.address, deployedPlayerAffiliate.address, options)

    //register game to Dividend
    console.log('registering sicbo to dividend...')
    await deployedDividend.register(deployedSicbo.address)

    //register game to PlayerAffiliate
    console.log('registering sicbo to player_affiliate...')
    await deployedPlayerAffiliate.registerGame(deployedSicbo.address)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
