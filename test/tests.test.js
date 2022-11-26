const TestToken = artifacts.require("TestToken");
const PuffinApprovals = artifacts.require("PuffinApprovals");

contract("PuffinKYC Mainnet", async (accounts) => {
    describe("init test token", async () => {
        it("can add approvers", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.allowApprove(accounts[0])
            let isApproved = await approvals.canApprove(accounts[0])
            assert.equal(isApproved, true)
        })
        it("can approve users", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.approve(accounts[0])
            let isApproved = await approvals.isApproved(accounts[0])
            assert.equal(isApproved, true)
        })
        it("can remove users", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.remove(accounts[0])
            let isApproved = await approvals.isApproved(accounts[0])
            assert.equal(isApproved, false)
        })
        it("can remove approvers", async () => {
            let approvals = await PuffinApprovals.deployed();
            await approvals.removeApprove(accounts[0])
            let isApproved = await approvals.canApprove(accounts[0])
            assert.equal(isApproved, false)
        })
    })
});

// contract("PuffinMainnetBridge", async (accounts) => {
//
//     describe("init test token", async () => {
//         it("intialize", async () => {
//             let token = await TestToken.deployed();
//             let token_bal = await token.balanceOf(accounts[0])
//             assert.equal(token_bal, BigInt(10**20))
//         })
//     })
// });
