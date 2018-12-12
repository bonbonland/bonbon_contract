const web3 = require('web3')
const PlayerBook = artifacts.require('./ddz/PlayerBook.sol')
const config = require('../tools/config.js')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    console.log('deploying playbook...')
    await deployer.deploy(PlayerBook, options)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
