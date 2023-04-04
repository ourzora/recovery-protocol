// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/governance/TimelockControllerUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/StringsUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./governance/RecoveryGovernor.sol";
import "./governance/RecoveryTreasury.sol";
import "./token/RecoveryCollection.sol";
import "./upgradeability/RecoveryProxy.sol";
import "./utils/IERC173.sol";

contract RecoveryRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address public immutable collectionImpl;
    address public immutable governorImpl;
    address public immutable treasuryImpl;

    mapping(address => RecoveryParentCollectionDefaultSettings) internal recoverySettingsForParentCollection;
    mapping(address => mapping(uint256 => RecoveryCollectionAddresses))
        internal recoveryCollectionAddressesForParentToken;

    struct RecoveryParentCollectionDefaultSettings {
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 proposalThreshold;
        uint256 timelockDelay;
        address votingToken;
        uint96 defaultParentHolderFeeBps;
        address governorImpl;
        uint32 recoveryParentTokenOwnerVotingWeight;
        bool allowAnyVotingToken;
        bool parentOwnerCanSetERC173Owner;
    }

    struct RecoveryCollectionAddresses {
        address collection;
        address payable governor;
        address payable treasury;
    }

    event RecoveryParentCollectionRegistered(
        address collection,
        RecoveryParentCollectionDefaultSettings defaultSettings
    );

    event RecoveryParentCollectionSettingsUpdated(
        address collection,
        RecoveryParentCollectionDefaultSettings defaultSettings
    );

    event RecoveryCollectionCreated(
        address collection,
        address payable governor,
        address payable treasury,
        address parentCollection,
        uint256 parentTokenId
    );

    constructor(address _collectionImpl, address _governorImpl, address _treasuryImpl) initializer {
        collectionImpl = _collectionImpl;
        governorImpl = _governorImpl;
        treasuryImpl = _treasuryImpl;
    }

    function __RecoveryRegistry_init() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function registerParentCollection(
        address parentCollection,
        address votingToken,
        address alternativeGovernorImpl,
        uint256 votingDelay, // delay before voting starts in blocks
        uint256 votingPeriod, // voting period in blocks
        uint256 timelockDelay, // delay before timelock can be executed in seconds
        uint256 proposalThreshold,
        uint96 defaultParentHolderFeeBps,
        bool allowAnyVotingToken,
        bool parentOwnerCanSetERC173Owner,
        uint32 recoveryParentTokenOwnerVotingWeight
    ) public {
        require(parentCollection != address(0), "RecoveryRegistry: collection cannot be zero address");
        require(
            votingToken != address(0) || allowAnyVotingToken,
            "RecoveryRegistry: voting token cannot be zero address unless any voting token is allowed"
        );
        require(votingPeriod > 0, "RecoveryRegistry: voting period must be greater than zero");
        require(
            IERC165Upgradeable(parentCollection).supportsInterface(type(IERC721Upgradeable).interfaceId),
            "RecoveryRegistry: collection does not support ERC721"
        );
        require(_msgSender() == IERC173(parentCollection).owner(), "RecoveryRegistry: caller not collection owner");
        require(
            defaultParentHolderFeeBps <= 10000,
            "RecoveryRegistry: default parent holder fee bps cannot exceed 10000"
        );

        RecoveryParentCollectionDefaultSettings storage settings = recoverySettingsForParentCollection[
            parentCollection
        ];

        require(settings.votingToken == address(0), "RecoveryRegistry: collection already registered");

        if (alternativeGovernorImpl != address(0)) {
            settings.governorImpl = alternativeGovernorImpl;
        } else {
            settings.governorImpl = governorImpl;
        }

        settings.votingToken = votingToken;
        settings.votingDelay = votingDelay;
        settings.votingPeriod = votingPeriod;
        settings.timelockDelay = timelockDelay;
        settings.proposalThreshold = proposalThreshold;
        settings.defaultParentHolderFeeBps = defaultParentHolderFeeBps;
        settings.allowAnyVotingToken = allowAnyVotingToken;
        settings.parentOwnerCanSetERC173Owner = parentOwnerCanSetERC173Owner;
        settings.recoveryParentTokenOwnerVotingWeight = recoveryParentTokenOwnerVotingWeight;

        emit RecoveryParentCollectionRegistered(parentCollection, settings);
    }

    function updateParentCollectionDefaultSettings(
        address parentCollection,
        address votingToken,
        address alternativeGovernorImpl,
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 timelockDelay,
        uint256 proposalThreshold,
        uint96 defaultParentHolderFeeBps,
        bool allowAnyVotingToken,
        bool parentOwnerCanSetERC173Owner,
        uint32 recoveryParentTokenOwnerVotingWeight
    ) public {
        require(parentCollection != address(0), "RecoveryRegistry: collection cannot be zero address");
        require(
            votingToken != address(0) || allowAnyVotingToken,
            "RecoveryRegistry: voting token cannot be zero address unless any voting token is allowed"
        );
        require(votingPeriod > 0, "RecoveryRegistry: voting period must be greater than zero");
        require(_msgSender() == IERC173(parentCollection).owner(), "RecoveryRegistry: caller not collection owner");
        require(
            defaultParentHolderFeeBps <= 10000,
            "RecoveryRegistry: default parent holder fee bps cannot exceed 10000"
        );

        RecoveryParentCollectionDefaultSettings storage settings = recoverySettingsForParentCollection[
            parentCollection
        ];

        require(parentCollectionIsRegistered(parentCollection), "RecoveryRegistry: collection already registered");

        if (alternativeGovernorImpl != address(0)) {
            settings.governorImpl = alternativeGovernorImpl;
        } else {
            settings.governorImpl = governorImpl;
        }

        settings.votingToken = votingToken;
        settings.votingDelay = votingDelay;
        settings.votingPeriod = votingPeriod;
        settings.timelockDelay = timelockDelay;
        settings.proposalThreshold = proposalThreshold;
        settings.defaultParentHolderFeeBps = defaultParentHolderFeeBps;
        settings.allowAnyVotingToken = allowAnyVotingToken;
        settings.parentOwnerCanSetERC173Owner = parentOwnerCanSetERC173Owner;
        settings.recoveryParentTokenOwnerVotingWeight = recoveryParentTokenOwnerVotingWeight;

        emit RecoveryParentCollectionSettingsUpdated(parentCollection, settings);
    }

    function parentCollectionIsRegistered(address collection) public view returns (bool) {
        return recoverySettingsForParentCollection[collection].votingPeriod > 0;
    }

    function getRecoveryParentCollectionDefaultSettings(address collection)
        public
        view
        returns (RecoveryParentCollectionDefaultSettings memory)
    {
        require(parentCollectionIsRegistered(collection), "RecoveryRegistry: collection not registered");
        return recoverySettingsForParentCollection[collection];
    }

    function createRecoveryCollectionForParentToken(
        address parentTokenContract,
        uint256 parentTokenId,
        address _votingToken
    ) public {
        require(
            parentCollectionIsRegistered(parentTokenContract),
            "RecoveryRegistry: parent collection not registered"
        );
        require(
            !recoveryCollectionExistsForParentToken(parentTokenContract, parentTokenId),
            "RecoveryRegistry: recovery already exists"
        );
        require(
            _msgSender() == IERC721Upgradeable(parentTokenContract).ownerOf(parentTokenId) ||
                _msgSender() == IERC173(parentTokenContract).owner(),
            "RecoveryRegistry: caller not token owner or collection owner"
        );

        RecoveryParentCollectionDefaultSettings memory settings = recoverySettingsForParentCollection[
            parentTokenContract
        ];

        address votingToken = _votingToken;
        if (votingToken == address(0)) {
            require(settings.votingToken != address(0), "RecoveryRegistry: voting token not set");
            votingToken = settings.votingToken;
        }
        if (votingToken != settings.votingToken) {
            require(settings.allowAnyVotingToken, "RecoveryRegistry: voting token not allowed");
        }

        RecoveryCollectionAddresses storage addresses = recoveryCollectionAddressesForParentToken[parentTokenContract][
            parentTokenId
        ];

        addresses.collection = address(new RecoveryProxy(collectionImpl, ""));
        addresses.governor = payable(address(new RecoveryProxy(settings.governorImpl, "")));
        addresses.treasury = payable(address(new RecoveryProxy(treasuryImpl, "")));

        address[] memory empty = new address[](0);
        RecoveryTreasury(addresses.treasury).__RecoveryTreasury_init(
            settings.timelockDelay,
            empty,
            empty,
            address(this)
        );

        RecoveryCollection(addresses.collection).__RecoveryCollection_init(
            string.concat(
                IERC721MetadataUpgradeable(parentTokenContract).name(),
                "-",
                StringsUpgradeable.toString(parentTokenId),
                "-Recovery"
            ),
            string.concat(
                IERC721MetadataUpgradeable(parentTokenContract).symbol(),
                "-",
                StringsUpgradeable.toString(parentTokenId),
                "-RECOVERY"
            ),
            parentTokenContract,
            parentTokenId,
            settings.defaultParentHolderFeeBps,
            settings.parentOwnerCanSetERC173Owner
        );

        RecoveryGovernor(addresses.governor).__RecoveryGovernor_init(
            votingToken,
            TimelockControllerUpgradeable(addresses.treasury),
            string.concat(
                IERC721MetadataUpgradeable(parentTokenContract).name(),
                "-",
                StringsUpgradeable.toString(parentTokenId),
                "-RecoveryGovernor"
            ),
            settings.votingDelay,
            settings.votingPeriod,
            settings.proposalThreshold,
            parentTokenContract,
            parentTokenId,
            settings.recoveryParentTokenOwnerVotingWeight
        );

        // roles
        RecoveryTreasury(addresses.treasury).grantRole(
            RecoveryTreasury(addresses.treasury).PROPOSER_ROLE(),
            addresses.governor
        );
        RecoveryTreasury(addresses.treasury).grantRole(
            RecoveryTreasury(addresses.treasury).EXECUTOR_ROLE(),
            address(0)
        );
        RecoveryTreasury(addresses.treasury).grantRole(
            RecoveryTreasury(addresses.treasury).CANCELLER_ROLE(),
            addresses.governor
        );
        RecoveryTreasury(addresses.treasury).renounceRole(
            RecoveryTreasury(addresses.treasury).TIMELOCK_ADMIN_ROLE(),
            address(this)
        );
        RecoveryGovernor(addresses.governor).transferOwnership(addresses.treasury);
        RecoveryCollection(addresses.collection).grantRole(
            RecoveryCollection(addresses.collection).ADMIN_ROLE(),
            addresses.treasury
        );
        RecoveryCollection(addresses.collection).renounceRole(
            RecoveryCollection(addresses.collection).DEFAULT_ADMIN_ROLE(),
            address(this)
        );

        emit RecoveryCollectionCreated(
            addresses.collection,
            addresses.governor,
            addresses.treasury,
            parentTokenContract,
            parentTokenId
        );
    }

    function recoveryCollectionExistsForParentToken(address parentTokenContract, uint256 parentTokenId)
        public
        view
        returns (bool)
    {
        return recoveryCollectionAddressesForParentToken[parentTokenContract][parentTokenId].collection != address(0);
    }

    function getRecoveryAddressesForParentToken(address parentTokenContract, uint256 parentTokenId)
        public
        view
        returns (RecoveryCollectionAddresses memory)
    {
        require(
            recoveryCollectionExistsForParentToken(parentTokenContract, parentTokenId),
            "RecoveryRegistry: recovery does not exist"
        );
        return recoveryCollectionAddressesForParentToken[parentTokenContract][parentTokenId];
    }

    // extra storage
    uint256[50] private __gap;
}
