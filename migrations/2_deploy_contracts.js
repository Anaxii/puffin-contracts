const erc20 = artifacts.require("ERC20");
const PuffinApprovals = artifacts.require("PuffinApprovals");

module.exports = async (deployer, network) => {
    await deployer.deploy(erc20, "test", "test")
    let token = await erc20.deployed()
    await deployer.deploy(PuffinApprovals)
};
