const MangoToken = artifacts.require("./MangoToken.sol");
const FruitSupplyChain = artifacts.require("./FruitSupplyChain.sol");

module.exports = function(deployer) {
    deployer.deploy(MangoToken, 10000, "Mango", 18, "MGN");
    deployer.deploy(FruitSupplyChain);
};x