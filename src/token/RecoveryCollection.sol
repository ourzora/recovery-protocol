// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";
import "../utils/IOperatorFilterRegistry.sol";
import "../utils/IERC173.sol";
import "../common/RecoveryChildV1.sol";

contract RecoveryCollection is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    EIP712Upgradeable,
    ERC721VotesUpgradeable,
    UUPSUpgradeable,
    ERC2981Upgradeable,
    RecoveryChildV1,
    IERC173
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address payable public constant DEFAULT_PARENT_OWNER_ADDRESS = payable(0x1111111111111111111111111111111111111111);
    IOperatorFilterRegistry public constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    address public constant marketFilterDAOAddress = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    address public erc173Owner;
    bool public parentOwnerCanSetERC173Owner;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _recoveryParentTokenContract,
        uint256 _recoveryParentTokenId,
        uint96 _defaultFeeNumerator,
        bool _parentOwnerCanSetERC173Owner
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __EIP712_init(_name, "1");
        __ERC721Votes_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();
        __RecoveryChildV1_init(_recoveryParentTokenContract, _recoveryParentTokenId);

        _setDefaultRoyalty(DEFAULT_PARENT_OWNER_ADDRESS, _defaultFeeNumerator);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        parentOwnerCanSetERC173Owner = _parentOwnerCanSetERC173Owner;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId, string memory uri) public onlyRole(ADMIN_ROLE) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function burn(uint256 tokenId) public onlyRole(ADMIN_ROLE) {
        _burn(tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address, uint256) {
        (address receiver, uint256 amount) = super.royaltyInfo(_tokenId, _salePrice);
        if (receiver == address(DEFAULT_PARENT_OWNER_ADDRESS)) {
            receiver = parentTokenOwner();
        }
        return (receiver, amount);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyRole(ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        if (from != _msgSender() && address(operatorFilterRegistry).code.length > 0) {
            require(operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender), "operator not allowed");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function owner() external view returns (address) {
        if (erc173Owner != address(0)) {
            return erc173Owner;
        }
        return parentTokenOwner();
    }

    function transferOwnership(address _newManager) public {
        require(_msgSender() == parentTokenOwner() || hasRole(ADMIN_ROLE, _msgSender()), "only parent owner or admin");
        if (_msgSender() == parentTokenOwner()) {
            require(parentOwnerCanSetERC173Owner, "parent owner cannot set ERC 173 owner");
        }

        emit OwnershipTransferred(erc173Owner, _newManager);

        erc173Owner = _newManager;
    }

    function setParentOwnerCanSetErc173Owner(bool can) public onlyRole(ADMIN_ROLE) {
        parentOwnerCanSetERC173Owner = can;
    }

    function updateMarketFilterSettings(bytes calldata args) external onlyRole(ADMIN_ROLE) returns (bytes memory) {
        (bool success, bytes memory ret) = address(operatorFilterRegistry).call(args);
        require(success, "failed to update market settings");
        return ret;
    }

    function manageMarketFilterDAOSubscription(bool enable) external onlyRole(ADMIN_ROLE) {
        address self = address(this);
        if (!operatorFilterRegistry.isRegistered(self) && enable) {
            operatorFilterRegistry.registerAndSubscribe(self, marketFilterDAOAddress);
        } else if (enable) {
            operatorFilterRegistry.subscribe(self, marketFilterDAOAddress);
        } else {
            operatorFilterRegistry.unsubscribe(self, false);
            operatorFilterRegistry.unregister(self);
        }
    }

    function parentTokenOwner() public view returns (address) {
        return IERC721Upgradeable(recoveryParentTokenContract).ownerOf(recoveryParentTokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721VotesUpgradeable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControlUpgradeable,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC2981Upgradeable,
            RecoveryChildV1
        )
        returns (bool)
    {
        return interfaceId == type(IERC173).interfaceId || super.supportsInterface(interfaceId);
    }
}
