const erc20 = artifacts.require("ERC20");

contract("init", async (accounts) => {

    describe("init contract", async () => {
        it("intialize", async () => {
            let token = await erc20.deployed();
            let token_bal = await token.balanceOf(accounts[0])
            assert.equal(token_bal, BigInt(0))
        })
    })
});
