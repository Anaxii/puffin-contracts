import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "PuffinCore.sol";

contract PuffinClient is Ownable {

    address public payToAddress;
    address public usdc;

    uint256 public epoch;
    uint256 public usdcPerUser;

    mapping(uint256 => uint256) public epochUsers;
    mapping(uint256 => bool) epochClaimable;

    event NewEpoch(uint256 epoch, uint256 timestamp, uint256 users, uint256 _usdcPerUser);
    event NewPayment(uint256 epoch, uint256 timestamp, uint256 users, uint256 _usdcPerUser, uint256 totalPaid, uint256 remainingBalance);


    constructor(address _payToAddress, address _usdc, uint256 _usdcPerUser) {
        payToAddress = _payToAddress;
        usdc = _usdc;
        usdcPerUser = _usdcPerUser;
    }

    function nextEpoch() public onlyOwner{
        epoch++;
        epochUsers[epoch] = epochUsers[epoch - 1] - epochUsers[epoch];
        epochClaimable[epoch - 1] = true;
        emit NewEpoch(epoch, block.timestamp, epochUsers[epoch], usdcPerUser);
    }

    function newUser(address _user) public onlyOwner{
        epochUsers[epoch] = epochUsers[epoch] + 1;
    }

    function delUser() public onlyOwner {
        epochUsers[epoch + 1] = epochUsers[epoch + 1] + 1;
    }

    function payout() public onlyOwner{
        require(epoch > 0);
        require(epochClaimable[epoch - 1]);
        epochClaimable[epoch - 1] = false;
        uint256 amount = calculatePayout();
        IERC20(usdc).transfer(payToAddress, amount);
        emit NewPayment(epoch - 1, block.timestamp, epochUsers[epoch - 1], usdcPerUser, amount, IERC20(usdc).balanceOf(address(this)));
    }

    function calculatePayout() public view returns (uint256) {
        require(epoch > 0);
        return usdcPerUser * epochUsers[epoch - 1];
    }

    function changeUSDPerUser(uint256 _usdPerUser) public onlyOwner () {
        usdcPerUser = _usdPerUser;
    }

    function changeUSDC(address _usdc) public onlyOwner {
        usdc = _usdc;
    }

    function changePayToAddress(address _payToAddress) public onlyOwner {
        payToAddress = _payToAddress;
    }
    
    function isCurrent() public view returns (bool) {
        return calculatePayout() >= IERC20(usdc).balanceOf(address(this));
    }

}