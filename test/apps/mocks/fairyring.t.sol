// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { MockFairyRing } from "../../../contracts/apps/mocks/fairyring.sol";

contract MockFairyRingTest is Test {
    MockFairyRing public mockFairyRing;
    address public operator;
    address public alice;
    address public bob;

    // Events to test
    event RandomnessRevealed(address indexed operator, bytes32 indexed commitment, uint256 indexed blockHeight);
    event RandomnessCommited(address indexed operator, bytes32 indexed randomness, uint256 indexed blockHeight);

    function setUp() public {
        // Set up addresses
        operator = makeAddr("operator");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy contract as operator
        vm.prank(operator);
        mockFairyRing = new MockFairyRing();
    }

    function testInitialState() public view {
        assertEq(mockFairyRing.operator(), operator);
        assertEq(mockFairyRing.latestHeight(), 0);

        (bytes32 randomHash, uint256 randomNumber) = mockFairyRing.latestRandomness();
        assertEq(randomHash, bytes32(0));
        assertEq(randomNumber, 0);

    }

    function testCommitRandomness() public {
        // Create commitment
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 secret = bytes32(uint256(456));
        bytes32 commitment = keccak256(abi.encodePacked(randomValue, secret));

        // Expect event to be emitted
        vm.expectEmit(true, true, true, true);
        emit RandomnessCommited(alice, commitment, block.number);

        // Commit as alice
        vm.prank(alice);
        mockFairyRing.commitRandomness(commitment);

        // Verify commitment was stored
        (bytes32 storedCommitment, , , ) = mockFairyRing.operatorCommitment(alice);
        assertEq(storedCommitment, commitment);
    }

    function testRevealRandomness() public {
        // First commit
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 secret = bytes32(uint256(456));
        bytes32 commitment = keccak256(abi.encodePacked(randomValue, secret));

        vm.prank(alice);
        mockFairyRing.commitRandomness(commitment);
        uint256 commitBlock = block.number;

        // Expect event on reveal
        vm.expectEmit(true, true, true, true);
        emit RandomnessRevealed(alice, randomValue, commitBlock);

        // Reveal
        vm.prank(alice);
        mockFairyRing.revealRandomness(randomValue, secret);

        // Verify state changes

        (bytes32 randomHash, uint256 randomNumber) = mockFairyRing.latestRandomness();
        assertEq(randomHash, randomValue);

        assertEq(mockFairyRing.latestHeight(), commitBlock);

        // Verify commitment was marked as revealed
        (, , , bool isRevealed) = mockFairyRing.operatorCommitment(alice);
        assertTrue(isRevealed);
    }

    function testCommitRandomness_MultipleUsers() public {
        bytes32 randomValue1 = bytes32(uint256(123));
        bytes32 secret1 = bytes32(uint256(456));
        bytes32 commitment1 = keccak256(abi.encodePacked(randomValue1, secret1));

        bytes32 randomValue2 = bytes32(uint256(789));
        bytes32 secret2 = bytes32(uint256(101112));
        bytes32 commitment2 = keccak256(abi.encodePacked(randomValue2, secret2));

        // Alice commits
        vm.prank(alice);
        mockFairyRing.commitRandomness(commitment1);

        // Bob commits
        vm.prank(bob);
        mockFairyRing.commitRandomness(commitment2);

        // Verify both commitments were stored correctly
        (bytes32 storedCommitment1, , , ) = mockFairyRing.operatorCommitment(alice);
        (bytes32 storedCommitment2, , , ) = mockFairyRing.operatorCommitment(bob);

        assertEq(storedCommitment1, commitment1);
        assertEq(storedCommitment2, commitment2);
    }

    function testRevertWhen_CommitWithUnrevealedCommitment() public {
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 secret = bytes32(uint256(456));
        bytes32 commitment = keccak256(abi.encodePacked(randomValue, secret));

        // First commitment
        vm.prank(alice);
        mockFairyRing.commitRandomness(commitment);

        // Try to commit again without revealing
        bytes32 newCommitment = bytes32(uint256(789));
        vm.expectRevert(MockFairyRing.MockFairyRing__UnRevealedCommitmentExist.selector);
        vm.prank(alice);
        mockFairyRing.commitRandomness(newCommitment);
    }

    function testRevertWhen_RevealWithoutCommitment() public {
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 secret = bytes32(uint256(456));

        vm.expectRevert(MockFairyRing.MockFairyRing__NoCommitmentFound.selector);
        vm.prank(alice);
        mockFairyRing.revealRandomness(randomValue, secret);
    }

    function testRevertWhen_RevealWithWrongSecret() public {
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 correctSecret = bytes32(uint256(456));
        bytes32 wrongSecret = bytes32(uint256(789));
        bytes32 commitment = keccak256(abi.encodePacked(randomValue, correctSecret));

        // Commit
        vm.prank(alice);
        mockFairyRing.commitRandomness(commitment);

        // Try to reveal with wrong secret
        vm.expectRevert(MockFairyRing.MockFairyRing__InvalidCommitment.selector);
        vm.prank(alice);
        mockFairyRing.revealRandomness(randomValue, wrongSecret);
    }

    function testRevertWhen_RevealTwice() public {
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 secret = bytes32(uint256(456));
        bytes32 commitment = keccak256(abi.encodePacked(randomValue, secret));

        // Commit and reveal first time
        vm.startPrank(alice);
        mockFairyRing.commitRandomness(commitment);
        mockFairyRing.revealRandomness(randomValue, secret);

        // Try to reveal again
        vm.expectRevert(MockFairyRing.MockFairyRing__CommitmentAlreadyRevealed.selector);
        mockFairyRing.revealRandomness(randomValue, secret);
        vm.stopPrank();
    }

    function testLatestRandomnessWithHeight() public {
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 secret = bytes32(uint256(456));
        bytes32 commitment = keccak256(abi.encodePacked(randomValue, secret));

        // Commit and reveal
        vm.startPrank(alice);
        mockFairyRing.commitRandomness(commitment);
        uint256 commitBlock = block.number;
        mockFairyRing.revealRandomness(randomValue, secret);
        vm.stopPrank();

        // Check latest values
        (bytes32 latestRandom, uint256 latestHeight) = mockFairyRing.latestRandomnessWithHeight();
        assertEq(latestRandom, randomValue);
        assertEq(latestHeight, commitBlock);
    }

    function testGetLatestRandomness() public {
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 secret = bytes32(uint256(456));
        bytes32 commitment = keccak256(abi.encodePacked(randomValue, secret));

        // Commit and reveal
        vm.startPrank(alice);
        mockFairyRing.commitRandomness(commitment);
        mockFairyRing.revealRandomness(randomValue, secret);
        vm.stopPrank();

        (bytes32 randomHash, uint256 randomNumber) = mockFairyRing.latestRandomness();
        assertEq(randomHash, randomValue);

    }

    function testGetRandomnessByHeight() public {
        bytes32 randomValue = bytes32(uint256(123));
        bytes32 secret = bytes32(uint256(456));
        bytes32 commitment = keccak256(abi.encodePacked(randomValue, secret));

        // Commit and reveal
        vm.startPrank(alice);
        mockFairyRing.commitRandomness(commitment);
        mockFairyRing.revealRandomness(randomValue, secret);
        vm.stopPrank();

        assertEq(mockFairyRing.getRandomnessByAddress(alice), uint256(randomValue));
    }

    function testSequentialCommitsAndReveals() public {
        // First commit and reveal
        bytes32 randomValue1 = bytes32(uint256(123));
        bytes32 secret1 = bytes32(uint256(456));
        bytes32 commitment1 = keccak256(abi.encodePacked(randomValue1, secret1));

        vm.startPrank(alice);
        mockFairyRing.commitRandomness(commitment1);
        mockFairyRing.revealRandomness(randomValue1, secret1);
        vm.stopPrank();

        assertEq(mockFairyRing.getRandomnessByAddress(alice), uint256(randomValue1));

        // Second commit and reveal
        bytes32 randomValue2 = bytes32(uint256(789));
        bytes32 secret2 = bytes32(uint256(101112));
        bytes32 commitment2 = keccak256(abi.encodePacked(randomValue2, secret2));

        vm.startPrank(alice);
        mockFairyRing.commitRandomness(commitment2);
        mockFairyRing.revealRandomness(randomValue2, secret2);
        vm.stopPrank();

        assertEq(mockFairyRing.getRandomnessByAddress(alice), uint256(randomValue2));

        (bytes32 randomHash, uint256 randomNumber) = mockFairyRing.latestRandomness();
        assertEq(randomHash, randomValue2);

    }
}
