// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/RecoveryRegistry.sol";
import "../src/upgradeability/RecoveryProxy.sol";
import "../src/governance/RecoveryGovernor.sol";
import "../src/governance/RecoveryTreasury.sol";
import "../src/token/RecoveryCollection.sol";

contract DeployRecovery is Script {
    function run() public {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);

        address treasuryImpl = address(new RecoveryTreasury());
        address governorImpl = address(new RecoveryGovernor());
        address collectionImpl = address(new RecoveryCollection());
        address registryImpl = address(new RecoveryRegistry(collectionImpl, governorImpl, treasuryImpl));
        RecoveryProxy registry = new RecoveryProxy(registryImpl, abi.encodeWithSignature("__RecoveryRegistry_init()"));

        vm.stopBroadcast();
    }
}
