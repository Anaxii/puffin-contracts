import "@openzeppelin/contracts/access/Ownable.sol";

contract PuffinUser is Ownable{

    struct User {
        bool created;
        uint8 status;
    }

    mapping(address => User) private userData;
    event NewUser(address indexed user);

    constructor() {
        transferOwnership(msg.sender);
    }

    function newUser(address _user, uint8 _status) public onlyOwner returns (bool) {
        require(!userData[_user].created);
        User storage u = userData[_user];
        u.status = _status;
        u.created = true;
        emit NewUser(_user);
        return u.created;
    }

    function checkStatus(address _user) external view returns (uint8) {
        return userData[_user].status;
    }


    function updateUserStatus(address _user, uint8 _status) public onlyOwner {
        User storage u = userData[_user];
        u.status = _status;
    }

}