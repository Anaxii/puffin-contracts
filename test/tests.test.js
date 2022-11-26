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

    beforeEach(async () => {
        let token = await TestToken.deployed();
        let approvals = await PuffinApprovals.deployed();
        await approvals.allowApprove(accounts[0])
        await approvals.approve(token.address)
        await approvals.approve(accounts[0])

        let bridge = await PuffinMainnetBridge.deployed();
        await bridge.setKYC(approvals.address)
        await bridge.setAssets(approvals.address)
        await bridge.addVoter(accounts[0])
    });
    describe("can bridge in", async () => {
        it("call bridgeIn()", async () => {
            let bridge = await PuffinMainnetBridge.deployed();
            let token = await TestToken.deployed();
            await token.approve(bridge.address, 100)
            await bridge.bridgeIn(10, token.address)
            let bal = await token.balanceOf(accounts[0])
            assert.equal(bal, (10**20) - 10)
        })
        it("call proposeOut()", async () => {
            let bridge = await PuffinMainnetBridge.deployed();
            let token = await TestToken.deployed();
            await bridge.proposeOut(
              token.address,
              accounts[0],
              10,
              "0x736ead9873f4e3f6d220de36484ef816da816a649db54fd842d4e9323616ccec",
              43114
            )
            let bal = await token.balanceOf(accounts[0])
            assert.equal(bal, 10**20)
        })
    })
});
