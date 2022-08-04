// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ERC1155 is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, UUPSUpgradeable{
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice name of the collection
    string public name;
    /// @notice symbol of the collection
    string public symbol;
    /// @notice Contract owner address
    address public owner;
    /// @notice Deployer contract address  
    address public factory;
    /// @notice Fee in percent which contract owner takes for selling NFT on Trade contract
    uint256 public percentFee;
    /// @notice Decimals of 'percentFee' number, example: 25.55% in 'percentFee' would be 2555
    uint256 constant public percentDecimals = 2;
    /// @notice Returns quantity of certain token id supply
    mapping (uint256 => uint256) public tokenIdSupply;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address owner_,
        uint256 percentFee_
    ) initializer public {
        __ERC1155_init(baseURI_);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        name = name_;
        symbol = symbol_;
        owner = owner_;
        factory = msg.sender;
        percentFee = percentFee_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, owner_);
        grantRole(ADMIN_ROLE, owner_);
        grantRole(MINTER_ROLE, owner_);
    }

    function mint(address account, uint256 id, uint256 amount) external onlyRole(MINTER_ROLE) {
        tokenIdSupply[id] += amount;
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < ids.length; i++) {
            tokenIdSupply[ids[i]] += amounts[i];
        }
        _mintBatch(to, ids, amounts, "");
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(ADMIN_ROLE) {
        _setURI(_newBaseURI);
    }

    function burn(address account, uint256 id, uint256 amount) external {
        tokenIdSupply[id] -= amount;
        _burn(account, id, amount);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external {
        for (uint i = 0; i < ids.length; i++) {
            tokenIdSupply[ids[i]] -= amounts[i];
        }
        _burnBatch(account, ids, amounts);
    }

    /// @notice Changes fee percent for NFT contract owner, available only for ADMIN_ROLE
    function changeFeePercent(uint256 _percentFee) external onlyRole(ADMIN_ROLE) {
        require(_percentFee > 0 && _percentFee <= 10000, "0 < Fee < 10000");
        percentFee = _percentFee;
    }

    function getVersion() public pure returns(uint256) {
        return 1;
    }

    function _authorizeUpgrade(address newImplementation) internal
        override
        onlyRole(ADMIN_ROLE) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}