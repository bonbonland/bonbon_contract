module.exports = async function (done) {
  const TestCaller = artifacts.require('./bonbon_storage/TestCaller')
  const Web3 = require('web3')
  const BN = require('bignumber.js')
  const config = require('../../tools/config.js')

  let gameName = Web3.utils.toHex('ddz')
  let ddzShareAccountAddress = '0xDD0680dB212610909DAbEcf4231a30c2fF7437B4'
  let accountA = '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'

  try {
    instance = await TestCaller.deployed()
    abi = instance.contract.abi
    web3 = new Web3(config.envConfig.DEV_CHAIN_HTTP_HOST)
    //res = await instance.shareAccountAddress.call(gameName)   //发起调用(传参)(访问的是属性，没有modifier)
    res = await instance.getShareAccount.call(gameName) //这里调用的是方法，有modifier
    console.log('current ddz share account is : ' + res)

    //set share account
    // console.log('now set ddz share account address to: ' + ddzShareAccountAddress)
    // await instance.setShareAccount(gameName, ddzShareAccountAddress, {
    //   from: accountA.toLowerCase(),
    // })  //发送transactions
    // res = await instance.getShareAccount.call(gameName)
    // console.log('current ddz share account is : ' + res)

    //测试store方法，往里面转钱
    ddzShareAccountAddressBalance = await web3.eth.getBalance(ddzShareAccountAddress)
    console.log('share account [' + ddzShareAccountAddress + '] balance is : ' + new BN(ddzShareAccountAddressBalance).div(1e18).toFixed(4))
    await instance.store({  //这里要使用await等待执行完成，不然接下来获取到的状态不准确
      value: web3.utils.toWei('0.1', 'ether')
    })
    ddzShareAccountAddressBalance = await web3.eth.getBalance(ddzShareAccountAddress)
    console.log('after store share account [' + ddzShareAccountAddress + '] balance is : ' + new BN(ddzShareAccountAddressBalance).div(1e18).toFixed(4))

    done()
  } catch (err) {
    done(err)
  }
  // TestCaller.deployed().then(function (instance) {
  //   instance.shareAccountAddress('ddz').call().then(function (res) {
  //     console.log(web3.utils.toUtf8(res))
  //
  //     done()
  //   })
  // })


}