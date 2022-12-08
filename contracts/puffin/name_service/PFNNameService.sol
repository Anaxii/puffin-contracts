// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts@4.2.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.2.0/access/Ownable.sol";

interface IAllowList {
    // Set [addr] to have the admin role over the precompile.
    function setAdmin(address addr) external;

    // Set [addr] to be enabled on the precompile contract.
    function setEnabled(address addr) external;

    // Set [addr] to have no role the precompile contract.
    function setNone(address addr) external;

    // Read the status of [addr].
    function readAllowList(address addr) external view returns (uint256 role);
}

interface IPuffinERC20Deployer {
    function isGlobalPaused() external view returns (bool);
    function isUserPaused(address user) external view returns (bool);
    function isTokenPaused(address user) external view returns (bool);
}

contract PFNNameService is Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public paymentToken;
    address public puffinERC20;

    mapping(address => uint256) private primaryDomain;
    mapping(uint256 => address) private primaryDomainUser;
    mapping(address => bool) private primaryDomainType;
    mapping(uint256 => uint256) public domainCost;

    mapping(address => uint256) subDomainIndex;

    uint256 public baseCost;
    uint256 public subDomainCost;
    uint256 public contractCost;
    uint256 public expirationLength;

    mapping(bytes => uint256) public domainTokenId;

    mapping(uint256 => domainInformation) public domainInfo;

    struct domainInformation {
        uint256 expirationDate;
        uint256 graceDate;
        uint128 numberOfCreatedSubdomains;
        uint128 numberOfActiveSubdomains;
        bytes domainName;
        address owner;
        mapping(address => bool) authorizedSubdomainUsers;
        mapping(uint256 => bytes) subDomains;
        mapping(bytes => bool) isActive;
    }

    constructor() ERC721("PFN Name Service", "PFNNameService") {
        expirationLength = 31536000;
        contractCost = 5e18;
        baseCost = 5e17;
        subDomainCost = 5e17;
        // domainCost[1] = 10e18;
        // domainCost[2] = 10e18;
        // domainCost[3] = 5e18;
        // domainCost[4] = 3e18;
        // domainCost[5] - 1e18;
    }

    function createDomain(string memory _domainName, uint256 _months) external {
        bytes memory _domain = bytes(_domainName);
        require(_domain.length > 0, "PFNNameSerivce: Length too small");

        uint256 oldId = domainTokenId[_domain];

        if (oldId != 0) {
            domainInformation storage dOld = domainInfo[oldId];
            if (dOld.owner != address(0)) {
                require(block.timestamp > dOld.graceDate, "PFNNameSerivce: Cannot claim used domain before grace period");
            }
            if (dOld.owner == msg.sender) {
                extendDomain(oldId, _months);
                return;
            }
            primaryDomain[dOld.owner] = 0;
        }

        _tokenIds.increment();
        uint256 itemId = _tokenIds.current();

        uint256 _cost = (calculateDomainCost(_domainName) / 12) * _months;
        // IERC20(paymentToken).transferFrom(msg.sender, address(this), _cost);

        domainTokenId[_domain] = itemId;

        domainInformation storage d = domainInfo[itemId];
        d.expirationDate = block.timestamp + (_months * (30 days));
        d.graceDate = d.expirationDate + (30 days);
        d.numberOfCreatedSubdomains = 0;
        d.numberOfActiveSubdomains = 0;
        d.domainName = _domain;
        d.owner = msg.sender;

        _mint(msg.sender, itemId);
    }

    function createSubDomain(uint256 itemId, string memory _subDomainName) external {
        domainInformation storage d = domainInfo[itemId];
        require(block.timestamp < d.expirationDate, "PFNNameService: Domain expired");
        require(msg.sender == d.owner || d.authorizedSubdomainUsers[msg.sender], "PFNNameService: User is not authorized");
        bytes memory _subDomain = bytes(_subDomainName);
        require(_subDomain.length > 0, "PFNNameSerivice: Length too small");
        require(!d.isActive[_subDomain], "PFNNameService: Subaccount name already active");
        d.subDomains[d.numberOfCreatedSubdomains] = _subDomain;
        d.isActive[_subDomain] = true;
        d.numberOfCreatedSubdomains++;
        d.numberOfActiveSubdomains++;

        uint256 _cost = subDomainCost * (d.expirationDate - block.timestamp) / (30 days);
        // IERC20(paymentToken).transferFrom(msg.sender, address(this), _cost);

    }

    function removeSubDomain(uint256 itemId, uint256 subDomainId) external {
        domainInformation storage d = domainInfo[itemId];
        require(msg.sender == d.owner || d.authorizedSubdomainUsers[msg.sender], "PFNNameService: User is not authorized");
        require(keccak256(d.subDomains[subDomainId]) == keccak256(""), "PFNNameService: Invalid subdomain ID");

        d.numberOfActiveSubdomains--;
        d.isActive[d.subDomains[subDomainId]] = false;
        d.subDomains[subDomainId] = "";

        // create credit system for removing subdomain
    }

    function getSubDomain(uint256 itemId, uint256 subDomainId) external view returns (string memory _domain) {
        domainInformation storage d = domainInfo[itemId];
        _domain = string.concat(string(d.domainName), ".pfn");
        string memory sub = string.concat(string(d.subDomains[subDomainId]), ".");
        _domain = string.concat(sub, _domain);
        return _domain;
    }

    function calculateDomainCost(string memory _domainName) public view returns (uint256) {
        uint256 _cost = domainCost[bytes(_domainName).length];
        if (_cost == 0)
            return baseCost;
        return _cost;
    }

    function extendDomain(uint256 itemId, uint256 _months) public {
        domainInformation storage d = domainInfo[itemId];
        require(d.domainName.length > 0, "PFNNameSerivce: Length too small");
        require(keccak256(d.domainName) != keccak256(""), "PFNNameService: Invalid domain");
        uint256 _cost = (calculateDomainCost(string(d.domainName)) / 12) * _months + (subDomainCost * d.numberOfActiveSubdomains);
        // IERC20(paymentToken).transferFrom(msg.sender, address(this), _cost);

        d.expirationDate = d.expirationDate + (_months * 2592000);
    }

    function setPrimaryAsDomain(uint256 itemId) external {
        domainInformation storage d = domainInfo[itemId];
        require(ownerOf(itemId) == msg.sender, "PFNNameService: User does not own token");

        address currentUser = primaryDomainUser[itemId];
        if (currentUser != address(0))
            primaryDomain[currentUser] = 0;

        primaryDomainType[msg.sender] = false;

        primaryDomain[msg.sender] = itemId;
        primaryDomainUser[itemId] = msg.sender;
    }

    function setPrimaryAsSubdomain(uint256 itemId, uint256 domainIndex) external {
        domainInformation storage d = domainInfo[itemId];
        require(d.owner == msg.sender || d.authorizedSubdomainUsers[msg.sender], "PFNNameService: User not authorized");
        require(keccak256(d.subDomains[domainIndex]) != keccak256(""), "PFNNameService: Invalid domain");
        primaryDomainType[msg.sender] = true;
        primaryDomain[msg.sender] = itemId;
        subDomainIndex[msg.sender] = domainIndex;
    }

    function setContractDomain(address _contract, string memory _domainName) external {
        bytes memory _domain = bytes(_domainName);
        require(Ownable(_contract).owner() == msg.sender, "PFNNameService: User is not the owner");
        uint256 _tokenId = domainTokenId[_domain];
        require(primaryDomainUser[_tokenId] == address(0), "PFNNameService: Domain already used");
        require(ownerOf(_tokenId) == msg.sender, "PFNNameService: User does not own token");
        primaryDomain[_contract] = _tokenId;
        primaryDomainUser[_tokenId] = _contract;
    }

    function domain(address user) public view returns (string memory _domain) {
        bool _type = primaryDomainType[user];
        domainInformation storage d = domainInfo[primaryDomain[user]];
        if (block.timestamp > d.expirationDate)
            return "";
        _domain = string.concat(string(d.domainName), ".pfn");
        if (_type) {
            string memory sub = string.concat(string(d.subDomains[subDomainIndex[msg.sender]]), ".");
            _domain = string.concat(sub, _domain);
        }
    }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 id,
    //     uint256 amount,
    //     bytes memory data
    // ) public virtual override {
    //     require(
    //         from == _msgSender() || isApprovedForAll(from, _msgSender()),
    //         "ERC1155: caller is not token owner or approved"
    //     );
    //     require(IAllowList(0x0200000000000000000000000000000000000002).readAllowList(to) > 0, "PuffinERC20: User unauthorized");
    //     require(!IPuffinERC20Deployer(puffinERC20).isGlobalPaused(), "PuffinERC20: Global Pause");
    //     require(!IPuffinERC20Deployer(puffinERC20).isUserPaused(_msgSender()), "PuffinERC20: User Pause");
    //     _safeTransferFrom(from, to, id, amount, data);
    // }

    // function safeBatchTransferFrom(
    //     address from,
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) public virtual override {
    //     require(
    //         from == _msgSender() || isApprovedForAll(from, _msgSender()),
    //         "ERC1155: caller is not token owner or approved"
    //     );
    //     require(IAllowList(0x0200000000000000000000000000000000000002).readAllowList(to) > 0, "PuffinERC20: User unauthorized");
    //     require(!IPuffinERC20Deployer(puffinERC20).isGlobalPaused(), "PuffinERC20: Global Pause");
    //     require(!IPuffinERC20Deployer(puffinERC20).isUserPaused(_msgSender()), "PuffinERC20: User Pause");
    //     _safeBatchTransferFrom(from, to, ids, amounts, data);
    // }
}
