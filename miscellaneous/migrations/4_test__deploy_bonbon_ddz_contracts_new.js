const web3 = require('web3')
const BonBonStorage = artifacts.require('./bonbon_storage/BonBonStorage.sol')
const TestCallerNew = artifacts.require('./bonbon_storage/TestCallerNew.sol')
const DdzShareAccount = artifacts.require('./bonbon_storage/DdzShareAccount.sol')

let gameName = web3.utils.toHex('ddz')

module.exports = function (deployer, network , accounts) {
  let options = {
    from: accounts[1],
    overwrite: true,
  }

  let run = async function () {
    //创建shareAccount合约
    let deployedDdzShareAccount = await deployer.deploy(DdzShareAccount, options)
    //创建Storage合约
    let deployedBonBonStorage = await deployer.deploy(BonBonStorage, options)
    // console.log('ddz share account address is: ' + deployedDdzShareAccount.address)
    // console.log('ddz bonbonStorage address is: ' + deployedBonBonStorage.address)
    //设置game的分红账号合约地址
    await deployedBonBonStorage.setShareAccount(gameName, deployedDdzShareAccount.address, {
      from: accounts[1],  //只有owner可以调用此方法
    })
    //创建TestCaller合约(业务合约)
    return deployer.deploy(TestCallerNew, gameName, deployedBonBonStorage.address, options)

    //按照truffle的规范，一定要返会promise
    // return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
