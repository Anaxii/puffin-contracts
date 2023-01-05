import "@openzeppelin/contracts/access/Ownable.sol";
import "PuffinClient.sol";
import "PuffinUser.sol";

contract PuffinCore is Ownable{

    bool approved;
    uint8 geotier;
    mapping(uint256 => bool) approvedCountries;
    mapping(address => bool) approvedContracts;
    mapping(address => mapping(address => bool)) contractApprovals;

    address public clientOwner;

    PuffinClient c;
    PuffinUsers u;

    event NewUserApproval(address indexed user, address indexed userAccessPoint);
    event NewUserAccessPoint(address indexed userAccessPoint);

    constructor(address _puffinClient, address _puffinUsers, address _clientOwner) {
        transferOwnership(msg.sender);
        clientOwner = _clientOwner;
        u = PuffinUsers(_puffinUsers);
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

    function prohibitCountry(uint256 _countryID) public {
        require(msg.sender == clientOwner || msg.sender == owner());
        approvedCountries[_countryID] = true;
    }

    function permitCountry(uint256 _countryID) public {
        require(msg.sender == clientOwner || msg.sender == owner());
        approvedCountries[_countryID] = false;
    }

    function approveUserForContract(address _user, address _clientContract) external {
        require(approved);
        require(approvedContracts[msg.sender]);
        require(!approvedCountries(u.getGeo(_user)));
        contractApprovals[_clientContract][_user] = true;
        emit NewUserApproval(_user, _clientContract);
    }

    function authorize(address _user) external view returns (bool) {
        require(approved);
        require(approvedContracts[msg.sender]);
        return u.checkStatus(_user);
    }

}