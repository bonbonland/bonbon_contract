let Migrations = artifacts.require("./Migrations.sol")

module.exports = function(deployer) {
  deployer.deploy(Migrations, {overwrite: false,})  //default overwrite is true
};
