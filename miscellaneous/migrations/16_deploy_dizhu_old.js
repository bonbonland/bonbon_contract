const web3 = require('web3')
const PlayerBook = artifacts.require('./ddz/PlayerBook.sol')
const DIZHU = artifacts.require('./ddz/DIZHU.sol')
const config = require('../tools/config.js')

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let deployedPlayerBook = await PlayerBook.deployed()

    //部署ddz合约
    // console.log('deploying ddz...')
    let deployedDIZHU = await deployer.deploy(DIZHU, deployedPlayerBook.address, options)

    //激活ddz
    console.log('activating ddz...')
    await deployedDIZHU.activate()

    //注册game到playbook
    console.log('add game to playbook...')
    await deployedPlayerBook.addGame(deployedDIZHU.address, 'DIZHU')

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
