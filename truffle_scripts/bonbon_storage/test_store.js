module.exports = async function (done) {
  const TestCaller = artifacts.require('./bonbon_storage/TestCaller')
  const DdzShareAccount = artifacts.require('./bonbon_storage/DdzShareAccount')
  const Web3 = require('web3')
  const BN = require('bignumber.js')
  const config = require('../../tools/config.js')

  let gameName = Web3.utils.toHex('ddz')

  try {
    DeployedTestCaller = await TestCaller.deployed()
    DeployedDdzAccount = await DdzShareAccount.deployed()
    abi = DeployedTestCaller.contract.abi
    web3 = new Web3(config.envConfig.DEV_CHAIN_HTTP_HOST)
    currentDdzShareAddount = await DeployedTestCaller.getShareAccount.call(gameName) //这里调用的是方法，有modifier
    console.log('current ddz share account is : ' + currentDdzShareAddount)

    //测试store方法，往里面转钱
    let getBalance = async function () {
      currentDdzShareAddount = await DeployedTestCaller.getShareAccount.call(gameName) //这里调用的是方法，有modifier
      shareAccountTotalBalance = await web3.eth.getBalance(currentDdzShareAddount)
      console.log('share account [' + currentDdzShareAddount + '] total balance is : ' + new BN(shareAccountTotalBalance).div(1e18).toFixed(4))
      testCallerTransferedAmount = await DeployedDdzAccount.amountOf.call(DeployedTestCaller.address)
      console.log('testcaller account [' + TestCaller.address + '] transfer amount is : ' + new BN(testCallerTransferedAmount).div(1e18).toFixed(4))
      lastDepositSender = await DeployedDdzAccount.lastMsgSender.call()
      console.log('share account last deposit sender is : ' + lastDepositSender)
    }

    let setShareAccount = async function () {
      await DeployedTestCaller.setShareAccount(gameName, '0x8fde55b27790902de6cf5ad66a1dfd789a7f6ddb', {
          from: '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'.toLowerCase(), //必须要合约的owner执行
      })
    }

    await getBalance()

    await DeployedTestCaller.store({  //这里要使用await等待执行完成，不然接下来获取到的状态不准确
      value: web3.utils.toWei('0.1', 'ether')
    })

    await getBalance()

    // 测试切换账号
    // console.log('changed share account!')
    // await setShareAccount()
    //
    // await getBalance()
    //
    // await DeployedTestCaller.store({  //这里要使用await等待执行完成，不然接下来获取到的状态不准确
    //   value: web3.utils.toWei('0.1', 'ether')
    // })
    //
    // await getBalance()

    //测试转账方法
    // await DeployedDdzAccount.transferTo('0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C', web3.utils.toWei('0.5', 'ether'), {
    //   from: '0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c'.toLowerCase(), //必须要合约的owner执行
    // })
    // await getBalance()

    done()
  } catch (err) {
    done(err)
  }
}