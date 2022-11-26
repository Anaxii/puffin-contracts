const TestToken = artifacts.require("TestToken");
const PuffinApprovals = artifacts.require("PuffinApprovals");
const PuffinMainnetBridge = artifacts.require("PuffinMainnetBridge");

contract("PuffinKYC Mainnet", async (accounts) => {
    describe("init test token", async () => {
        it("owner can add approvers", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.allowApprove(accounts[0])
            let isApproved = await approvals.canApprove(accounts[0])
            assert.equal(isApproved, true)
        })
        it("owner can approve users", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.approve(accounts[0])
            let isApproved = await approvals.isApproved(accounts[0])
            assert.equal(isApproved, true)
        })
        it("owner can remove users", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.remove(accounts[0])
            let isApproved = await approvals.isApproved(accounts[0])
            assert.equal(isApproved, false)
        })
        it("owner can remove approvers", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.removeApprove(accounts[0])
            let isApproved = await approvals.canApprove(accounts[0])
            assert.equal(isApproved, false)
        })
        it("unauthorized user cant add approvers", async () => {
            let approvals = await PuffinApprovals.deployed();
            try {
                await approvals.allowApprove(accounts[0])
                assert.equal(false, true)

            } catch {
                assert.equal(true, true)
            }
        })
        it("unauthorized user cant approve users", async () => {
            let approvals = await PuffinApprovals.deployed();
            try {
                await approvals.approve(accounts[0])
                assert.equal(false, true)

            } catch {
                assert.equal(true, true)
            }
        })
        it("unauthorized user cant remove users", async () => {
            let approvals = await PuffinApprovals.deployed();
            try {
                await approvals.remove(accounts[0])
                assert.equal(false, true)

            } catch {
                assert.equal(true, true)
            }
        })
        it("unauthorized user cant remove approvers", async () => {
            let approvals = await PuffinApprovals.deployed();
            try {
                await approvals.removeApprove(accounts[0])
                assert.equal(false, true)
            } catch {
                assert.equal(true, true)
            }
        })
    })
});

contract("PuffinMainnetBridge", async (accounts) => {

    describe("init test token", async () => {
        it("intialize token", async () => {
            let token = await TestToken.deployed();
            let token_bal = await token.balanceOf(accounts[0])
            assert.equal(token_bal, BigInt(10**20))
        })
    })
    describe("approve token and user", async () => {
        it("add approver to approved assets", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.allowApprove(accounts[0])
        })
        it("add token to approved assets", async () => {
            let approvals = await PuffinApprovals.deployed();
            let token = await TestToken.deployed();
            await approvals.approve(token.address)
        })
        it("add user to approved assets", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.approve(accounts[0])
        })
    })
    describe("initialize bridge and set addresses", async () => {
        it("set kyc address", async () => {
            let bridge = await PuffinMainnetBridge.deployed();
            let approvals = await PuffinApprovals.deployed();
            await bridge.setKYC(approvals.address)
            let val = await bridge.puffinKYC()
            assert.equal(val, approvals.address)
        })
        it("set assets address", async () => {
            let bridge = await PuffinMainnetBridge.deployed();
            let approvals = await PuffinApprovals.deployed();
            await bridge.setAssets(approvals.address)
            let val = await bridge.puffinAssets()
            assert.equal(val, approvals.address)
        })
        it("set warm wallet address", async () => {
            let bridge = await PuffinMainnetBridge.deployed();
            await bridge.setAssets(accounts[0])
            let val = await bridge.puffinWarmWallet()
            assert.equal(val, accounts[0])
        })
    })
});
