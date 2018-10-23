let TestDeployed = artifacts.require("./practices/TestDeployed.sol")

module.exports = function(deployer) {
  deployer.deploy(TestDeployed, {overwrite: true})
};
