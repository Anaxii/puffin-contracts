const TestToken = artifacts.require("TestToken");
const PuffinApprovals = artifacts.require("PuffinApprovals");
const MainnetBridge = artifacts.require("PuffinMainnetBridge");
const SubnetBridge = artifacts.require("PuffinSubnetBridge");
const PuffinERC20Deployer = artifacts.require("PuffinERC20Deployer");

module.exports = async (deployer, network) => {
    await deployer.deploy(TestToken)
    await deployer.deploy(PuffinApprovals)
    await deployer.deploy(MainnetBridge, 43113)
    await deployer.deploy(SubnetBridge, 43114)
    await deployer.deploy(PuffinERC20Deployer)
};
