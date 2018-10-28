const web3 = require('web3')
const DragonCityCoin = artifacts.require('./dcl_coins/DragonCityCoin.sol')
const config = require('../tools/config.js')

const accountA = "0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c"
// const accountC = "0x018649744e6e2a52fA8551749e5db938EfF11567"

contract('DragonCityCoin', async (accounts) => {
  let accountOne = accounts[0]
  let setAmount = 1100

  it("should put 1000 DragonCityCoin in accountA's vault", async () => {
    let coin = await DragonCityCoin.deployed() //必须要放在it里面才能获取到
    let vault = await coin.vaults.call(accountA)
    let coinsInVault = vault[0].toNumber()  // 只能通过数组获取，不能通过struct的key获取
    assert.equal(coinsInVault, 1000)
  })

  it("should setVault correctly", async () => {
    let coin = await DragonCityCoin.deployed()
    let coinsInVaultBeforeSet = (await coin.vaults.call(accountOne))[0].toNumber()
    assert.equal(coinsInVaultBeforeSet, 0)

    //set vault
    await coin.setVault([accountOne], [setAmount])
    let coinsInVaultAfterSet = (await coin.vaults.call(accountOne))[0].toNumber()
    assert.equal(coinsInVaultAfterSet, setAmount)
  })

  it("should acquire correctly", async () => {
    let coin = await DragonCityCoin.deployed()
    let coinsInBalanceBeforeAcquire = (await coin.balanceOf.call(accountOne)).toNumber()
    assert.equal(coinsInBalanceBeforeAcquire, 0)

    //acquire
    await coin.acquire()
    let coinsInBalanceAfterAcquire = (await coin.balanceOf.call(accountOne)).toNumber()
    assert.equal(coinsInBalanceAfterAcquire, setAmount)
  })
})