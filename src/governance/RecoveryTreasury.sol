// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin-upgradeable/contracts/governance/TimelockControllerUpgradeable.sol";

contract RecoveryTreasury is TimelockControllerUpgradeable {
    function __RecoveryTreasury_init(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors,
        address _admin
    ) public initializer {
        __TimelockController_init(_minDelay, _proposers, _executors, _admin);
    }
}
