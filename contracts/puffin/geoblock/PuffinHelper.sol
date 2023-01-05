import "PuffinCore.sol";

contract PuffinHelper {
    PuffinCore p;
    uint256 public test;

    function approve() public {
        p.approveUserForContract(msg.sender, address(this));
    }

    function up() public {
        //requires only contract approval and kyc approval
        require(p.isApproved(msg.sender));
        test++;
    }

    function down() public {
        //requires contract approval, kyc approval and geotier approval
        require(p.isApprovedWithGeo(msg.sender));
        test--;
    }

    function change(address _puffincore) public {
        p = PuffinCore(_puffincore);
    }


}