// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IGovernorUpgradeable } from "@openzeppelin-upgradeable/contracts/governance/IGovernorUpgradeable.sol";

contract VoteAggregator {
    function castVotes(
        address[] memory _contracts,
        uint256[] memory _proposalIds,
        uint8[] memory _supportOptions,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    ) public {
        for (uint256 i = 0; i < _contracts.length; i++) {
            IGovernorUpgradeable(_contracts[i]).castVoteBySig(_proposalIds[i], _supportOptions[i], _v[i], _r[i], _s[i]);
        }
    }
}
