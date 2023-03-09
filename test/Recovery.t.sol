// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { GovernorCountingSimple } from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";

import { RecoveryProxy } from "../src/upgradeability/RecoveryProxy.sol";
import { RecoveryRegistry } from "../src/RecoveryRegistry.sol";
import { RecoveryCollection } from "../src/token/RecoveryCollection.sol";
import { RecoveryGovernor } from "../src/governance/RecoveryGovernor.sol";
import { RecoveryTreasury } from "../src/governance/RecoveryTreasury.sol";
import { MockVoting721 } from "./mocks/MockVoting721.sol";

contract RecoveryTest is Test {
    RecoveryRegistry registry;
    MockVoting721 tomb;
    MockVoting721 indexMarker;

    address registryAdmin = address(0x1);
    address tombDeployer = address(0x2);
    address tombHolder = address(0x3);
    address voter = address(0x4);

    function setUp() external {
        address collectionImpl = address(new RecoveryCollection());
        address governorImpl = address(new RecoveryGovernor());
        address treasuryImpl = address(new RecoveryTreasury());
        address registryImpl = address(new RecoveryRegistry(collectionImpl, governorImpl, treasuryImpl));
        vm.prank(registryAdmin);
        registry = RecoveryRegistry(address(new RecoveryProxy(registryImpl, abi.encodeWithSignature("initialize()"))));

        vm.startPrank(tombDeployer);
        tomb = new MockVoting721();
        tomb.mint(tombHolder);
        indexMarker = new MockVoting721();
        indexMarker.mint(tombHolder);
        indexMarker.mint(voter);
        indexMarker.mint(voter);
        vm.stopPrank();

        vm.prank(tombHolder);
        indexMarker.delegate(tombHolder);

        vm.prank(voter);
        indexMarker.delegate(voter);

        vm.roll(block.number + 1);
    }

    function test_Flow() external {
        vm.prank(tombDeployer);
        registry.registerParentCollection(address(tomb), address(indexMarker), 1, 50400, 172800, 1, 0, false, true, 10);

        vm.prank(tombHolder);
        registry.createRecoveryCollectionForParentToken(address(tomb), 0, address(indexMarker));

        RecoveryRegistry.RecoveryCollectionAddresses memory addresses = registry.getRecoveryAddressesForParentToken(
            address(tomb),
            0
        );
        RecoveryCollection collection = RecoveryCollection(addresses.collection);
        RecoveryGovernor governor = RecoveryGovernor(addresses.governor);
        RecoveryTreasury treasury = RecoveryTreasury(addresses.treasury);

        address[] memory targets = new address[](1);
        targets[0] = address(collection);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("safeMint(address,uint256,string)", tombHolder, 0, "https://test.com");
        vm.startPrank(tombHolder);
        uint256 proposalId = governor.propose(targets, values, calldatas, "");
        vm.roll(block.number + 2);
        governor.castVote(proposalId, uint8(GovernorCountingSimple.VoteType.For));
        vm.stopPrank();

        vm.prank(voter);
        governor.castVote(proposalId, uint8(GovernorCountingSimple.VoteType.For));

        vm.roll(block.number + 50400);
        assertGt(block.number, governor.proposalDeadline(proposalId));
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));

        vm.prank(tombDeployer);
        // governor.execute(targets, values, calldatas, keccak256(bytes("")));
        governor.queue(targets, values, calldatas, keccak256(bytes("")));
        vm.warp(block.timestamp + 172800);
        governor.execute(targets, values, calldatas, keccak256(bytes("")));

        assertEq(collection.balanceOf(tombHolder), 1);
        assertEq(collection.tokenURI(0), "https://test.com");

        assertEq(abi.encodeWithSignature("initialize()"), bytes(""));
    }
}
