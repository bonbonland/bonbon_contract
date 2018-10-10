let TestSelfDestruct = artifacts.require("./TestSelfDestruct.sol")

module.exports = function (deployer, network , accounts) {
  let run = async function () {
    options = {
      overwrite: true,
    }

    await deployer.deploy(TestSelfDestruct, options)

    //按照truffle的规范，一定要返会promise
    return Promise.resolve()
  }

  deployer.then(() => {
    return run()
  })
};
