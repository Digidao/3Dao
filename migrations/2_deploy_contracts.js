const Digitrade = artifacts.require("./Digitrade.sol");
const DaoGov = artifacts.require("./DaoGov.sol");
const Operations = artifacts.require("./Operations.sol");
const Representatives = artifacts.require("./Representatives.sol");
const StakePool = artifacts.require("./StakePool.sol");

module.exports = function (deployer) {
  deployer.deploy(Digitrade);
  deployer.deploy(DaoGov);
  //deployer.deploy(Operations);
  deployer.deploy(Representatives);
  //deployer.deploy(StakePool);
};
