const web3 = require('web3')
const PlayerAffiliate = artifacts.require('./bet/PlayerAffiliate.sol')
const config = require('../tools/config.js')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    await deployer.deploy(PlayerAffiliate, options)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
