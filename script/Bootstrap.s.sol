// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/RecoveryRegistry.sol";
import "../src/upgradeability/RecoveryProxy.sol";
import "../src/governance/RecoveryGovernor.sol";
import "../src/governance/RecoveryTreasury.sol";
import "../src/token/RecoveryCollection.sol";
import "../src/utils/IIndexMarkerV2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Bootstrap is Script {
    function run() public {
        IIndexMarker marker = IIndexMarker(0x047ad77640ff6b52664881D787659c79910375CA);

        RecoveryTreasury treasuryImpl = RecoveryTreasury(payable(0xeDe73f943F951Df539526f908cE11d6Bbfa183Bb));
        RecoveryGovernor governorImpl = RecoveryGovernor(payable(0x7e34A3DcBAC51547F91438E346bffE11BA4D046b));
        RecoveryCollection collectionImpl = RecoveryCollection(0x0FFc2a2b6a6B5071a19A47Fb51Cd07f2A0C20Bd2);
        RecoveryRegistry registry = RecoveryRegistry(payable(0xB1b17D12a669ab36250f5F55EF9a03790991bC2A));

        IERC721 beacon = IERC721(0x40406e790b6c04fCc9047945a577b99fE00BAe83);

        vm.startBroadcast(0x9aaC8cCDf50dD34d06DF661602076a07750941F6);

        registry.registerParentCollection(address(beacon), address(marker), 1, 50400, 172800, 0, 0, false, true, 10);
        for (uint256 i = 1; i < 36; i++) {
            registry.createRecoveryCollectionForParentToken(address(beacon), i, address(marker));
        }

        RecoveryRegistry.RecoveryCollectionAddresses memory addresses =
            registry.getRecoveryAddressesForParentToken(address(beacon), 4);
        RecoveryCollection collection = RecoveryCollection(addresses.collection);
        RecoveryGovernor governor = RecoveryGovernor(addresses.governor);

        address[] memory targets = new address[](1);
        targets[0] = address(collection);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature(
            "safeMint(address,string)", 0x9aaC8cCDf50dD34d06DF661602076a07750941F6, "https://test.com"
        );
        governor.propose(targets, values, calldatas, "");

        vm.stopBroadcast();
    }
}
