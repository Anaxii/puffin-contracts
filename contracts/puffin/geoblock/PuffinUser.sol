import "@openzeppelin/contracts/access/Ownable.sol";

contract PuffinUsers is Ownable{

    struct User {
        bool created;
        uint8 status;
        uint8 geotier;
    }

    mapping(address => User) private userData;
    event NewUser(address indexed user);


    function newUser(address _user, uint8 _geoTier, uint8 _status) public onlyOwner returns (bool) {
        require(!userData[_user].created);
        User storage u = userData[_user];
        u.status = _status;
        u.geotier = _geoTier;
        u.created = true;
        emit NewUser(_user);
        return u.created;
    }

    function checkStatus(address _user) external view returns (uint8) {
        return userData[_user].status;
    }

    function getGeo(address _user) external view returns (uint8) {
        return userData[_user].geotier;
    }

    function updateUserStatus(address _user, uint8 _status) public onlyOwner {
        User storage u = userData[_user];
        u.status = _status;
    }

    function updateUserGeotier(address _user, uint8 _geotier) public onlyOwner {
        User storage u = userData[_user];
        u.geotier = _geotier;
    }

}