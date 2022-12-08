const thesis = artifacts.require("thesis");

module.exports = function(deployer) {
  deployer.deploy(thesis, "SinoCoin", "SINC");
};