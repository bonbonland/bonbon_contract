const web3 = require('web3')
const BBT = artifacts.require('./project_a/BBT.sol')
const config = require('../tools/config.js')
const teamWalletAddress = config.envConfig.BBT_TEAM_WALLET //accountC

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let deployedBBT = await deployer.deploy(BBT, options)

    //设置teamWallet
    console.log('!!! now setting bbt team wallet to [' + teamWalletAddress + ']')
    await deployedBBT.setTeamWallet(teamWalletAddress)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
