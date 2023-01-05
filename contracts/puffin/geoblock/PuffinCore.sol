import "@openzeppelin/contracts/access/Ownable.sol";
import "PuffinUser.sol";
import "PuffinClient.sol";

contract PuffinCore is Ownable{

    bool approved;
    mapping(address => bool) approvedContracts;
    mapping(address => mapping(address => bool)) contractApprovals;

    address public clientOwner;

    PuffinClient c;
    PuffinUser u;

    event NewUserApproval(address indexed user, address indexed userAccessPoint);
    event NewUserAccessPoint(address indexed userAccessPoint);
    event ProhibitCountry(uint256 _countryId);
    event PermitCountry(uint256 _countryId);

    constructor(address _puffinClient, address _puffinUsers, address _clientOwner) {
        transferOwnership(msg.sender);
        clientOwner = _clientOwner;
        u = PuffinUser(_puffinUsers);
        c = PuffinClient(_puffinClient);
    }

    function addUserAccessPoint(address _userAccessPoint) public {
        require(msg.sender == clientOwner || msg.sender == owner());
        approvedContracts[_userAccessPoint] = true;
        emit NewUserAccessPoint(_userAccessPoint);
    }

    function removeUserAccessPoint(address _userAccessPoint) public {
        require(msg.sender == clientOwner || msg.sender == owner());
        approvedContracts[_userAccessPoint] = false;
    }

    function approveUserForContract(address _user, address _clientContract) public onlyOwner {
        contractApprovals[_clientContract][_user] = true;
        emit NewUserApproval(_user, _clientContract);
    }

    function prohibitCountry(uint256 _countryId) public {
        require(msg.sender == clientOwner || msg.sender == owner());
        emit ProhibitCountry(_countryId);
    }

    function permitCountry(uint256 _countryId) public {
        require(msg.sender == clientOwner || msg.sender == owner());
        emit PermitCountry(_countryId);
    }

    function checkKYC(address _user) external view returns (bool) {
        require(approved);
        return u.checkStatus(_user) == 2;
    }

    function checkApprovedContract(address _user, address _clientContract) public view returns (bool) {
        require(approved);
        return contractApprovals[_clientContract][_user];
    }

}