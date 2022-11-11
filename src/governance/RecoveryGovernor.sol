// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/contracts/governance/GovernorUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../common/RecoveryChildV1.sol";

contract RecoveryGovernor is
    Initializable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    GovernorTimelockControlUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    RecoveryChildV1
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVotesUpgradeable _token,
        TimelockControllerUpgradeable _timelock,
        string calldata _governorName,
        uint256 _initialVotingDelay,
        uint256 _initialVotingPeriod,
        uint256 _initialProposalThreshold,
        address _recoveryParentTokenContract,
        uint256 _recoveryParentTokenId
    ) public initializer {
        __Governor_init(_governorName);
        __GovernorSettings_init(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(4);
        __GovernorTimelockControl_init(_timelock);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __RecoveryChildV1_init(_recoveryParentTokenContract, _recoveryParentTokenId);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public onlyRole(CANCELLER_ROLE) returns (uint256) {
        return _cancel(targets, values, calldatas, descriptionHash);
    }

    function votingDelay() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(GovernorUpgradeable, IGovernorUpgradeable) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, GovernorUpgradeable, GovernorTimelockControlUpgradeable, RecoveryChildV1)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
