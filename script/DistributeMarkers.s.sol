// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../src/RecoveryRegistry.sol";
import "../src/upgradeability/RecoveryProxy.sol";
import "../src/governance/RecoveryGovernor.sol";
import "../src/governance/RecoveryTreasury.sol";
import "../src/token/RecoveryCollection.sol";
import "../src/utils/IIndexMarkerV2.sol";

contract DistributeMarkers is Script {
    function run() public {
        IIndexMarker marker = IIndexMarker(0x047ad77640ff6b52664881D787659c79910375CA);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 3;
        tokenIds[1] = 4;
        address[] memory owners = new address[](2);
        owners[0] = address(0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407);
        owners[1] = address(0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407);

        vm.startBroadcast(0x9aaC8cCDf50dD34d06DF661602076a07750941F6);
        marker.adminMint(tokenIds, owners);
        vm.stopBroadcast();
    }
}
