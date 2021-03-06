/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() {
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>')
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */

const web3 = require('web3')
const HDWalletProvider = require('truffle-hdwallet-provider-privkey')
const config = require('./tools/config.js')

const localAccountAPrivateKey = config.envConfig.LOCAL_ACCOUNT_A_PRI_KEY
const localAccountBPrivateKey = config.envConfig.LOCAL_ACCOUNT_B_PRI_KEY
const localPrivateKeys = [localAccountAPrivateKey, localAccountBPrivateKey]

const AccountAPrivateKey = config.envConfig.DEV_CHAIN_ACCOUNT_A_PRI_KEY
const AccountBPrivateKey = config.envConfig.DEV_CHAIN_ACCOUNT_B_PRI_KEY
const privateKeys = [AccountBPrivateKey, AccountAPrivateKey]  //第一个账户为默认帐号
const devChainHttpHost = config.envConfig.DEV_CHAIN_HTTP_HOST
const devChainHttpNetId = config.envConfig.DEV_CHAIN_NET_ID

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!

  compilers: {
    solc: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      // version: "0.4.24",
      version: "0.5.0",
    },
  },

  networks: {
    local: {
      host: 'localhost',
      port: 8545,
      gas: 10000000,
      network_id: '*',   // Match any network id
      provider: function() {
        return new HDWalletProvider(localPrivateKeys, "http://127.0.0.1:8545/");
      },
    },
    development: {  //default network hard-coded to 'development'
      provider: () =>
        //caution! first arg is array
        new HDWalletProvider(privateKeys, devChainHttpHost),
      network_id: devChainHttpNetId,
      gas: 8000000,
    },
    ropsten: {
      provider: () =>
        new HDWalletProvider(privateKeys, "https://ropsten.infura.io/"),
      network_id: '3',
      gas: 7000000,
      gasPrice: web3.utils.toWei('5', 'gwei'),
    },
  },
}
