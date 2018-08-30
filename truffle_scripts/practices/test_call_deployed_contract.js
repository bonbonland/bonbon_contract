module.exports = function(done) {
  const TestDeployed = artifacts.require('./practices/TestDeployed')
  const web3 = require('web3')

  TestDeployed.deployed().then(function (instance) {
    instance.foo.call().then(function (res) {
      console.log(web3.utils.toUtf8(res))

      done()
    })
  })
}