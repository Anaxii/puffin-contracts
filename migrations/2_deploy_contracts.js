const erc20 = artifacts.require("ERC20");

module.exports = async (deployer, network) => {
    await deployer.deploy(erc20, "test", "test")
    let token = await erc20.deployed()
};
