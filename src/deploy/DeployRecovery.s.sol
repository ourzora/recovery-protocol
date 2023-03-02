// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../RecoveryRegistry.sol";
import "../upgradeability/RecoveryProxy.sol";
import "../governance/RecoveryGovernor.sol";
import "../governance/RecoveryTreasury.sol";
import "../token/RecoveryCollection.sol";

contract DeployRecovery is Script {
    function run() public {
        uint256 key = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(key);

        // address treasuryImpl = address(new RecoveryTreasury());
        // address governorImpl = address(new RecoveryGovernor());
        // address collectionImpl = address(new RecoveryCollection());
        // address registryImpl = address(new RecoveryRegistry(collectionImpl, governorImpl, treasuryImpl));

        address treasuryImpl = 0xF1920AB234a18A900a1c56fDE39D99885a729184;
        address governorImpl = 0xD62f59e09e4B46fCeBDFABC93b4690e3decd911B;
        address collectionImpl = 0x623b80baa20261589e5390C4a63f0c3Dd6293F1e;
        address registryImpl = 0x0d1d726B9Ab81C95b443f77c3088886874871CbD;
        address registry = address(
            new RecoveryProxy(
                registryImpl,
                abi.encodeWithSignature("initialize(address)", 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6)
            )
        );

        vm.stopBroadcast();
    }
}
