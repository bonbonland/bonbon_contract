const web3 = require('web3')
const DragonCityCoin = artifacts.require('./dcl_coins/DragonCityCoin.sol')
const config = require('../tools/config.js')

let initAccount = [
  {
    address: '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c',  //account a
    amount: 1000,
  },
  {
    address: '0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C', //account b
    amount: 1500,
  },
]

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    let deployedDragonCityCoin = await deployer.deploy(DragonCityCoin, options)

    //set init vault
    for (account of initAccount) {
      await deployedDragonCityCoin.setVault(account.address, account.amount)
    }

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
