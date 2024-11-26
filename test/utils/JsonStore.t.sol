// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { JsonStore } from "../../contracts/utils/JsonStore.sol";
import { Base64 } from "../../contracts/utils/Base64.sol";

contract JsonStoreTest is Test {
    using JsonStore for JsonStore.Store;
    JsonStore.Store internal store;

    string constant TEST_JSON = '{"name":"Test","value":123}';
    string constant INVALID_JSON = '{"name":"Test"value":123}'; // Missing comma
    bytes32 constant TEST_SLOT = bytes32(uint256(1));
    address testUser;

    event JsonStored(address indexed owner, bytes32 indexed slot);
    event JsonCleared(address indexed owner, bytes32 indexed slot);
    event SlotsPrepaid(address indexed owner, uint64 numSlots);

    function setUp() public {
        testUser = address(this);
    }

    function testInitialPrepaidSlots() public {
        assertEq(store.prepaid(testUser), 0);
    }

    function testPrepaySlots() public {
        // Expect event emission
        vm.expectEmit(true, false, false, true);
        emit SlotsPrepaid(testUser, 1);

        store.prepaySlots(testUser, 1);
        assertEq(store.prepaid(testUser), 1);
    }

    function testSetJsonWithoutPrepaidSlots() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__InsufficientPrepaidSlots()"));
        store.set(TEST_SLOT, TEST_JSON);
    }

    function testSetJsonWithInvalidJson() public {
        // First prepay slots
        store.prepaySlots(testUser, 1);

        vm.expectRevert(abi.encodeWithSignature("JsonStore__InvalidJson()"));
        store.set(TEST_SLOT, INVALID_JSON);
    }

    function testSetAndGetJson() public {
        // First prepay slots
        store.prepaySlots(testUser, 1);

        // Set JSON
        vm.expectEmit(true, true, false, true);
        emit JsonStored(testUser, TEST_SLOT);

        assertTrue(store.set(TEST_SLOT, TEST_JSON));

        // Verify storage
        assertTrue(store.exists(testUser, TEST_SLOT));
        assertEq(store.get(testUser, TEST_SLOT), TEST_JSON);

        // Verify prepaid slots were decremented
        assertEq(store.prepaid(testUser), 0);
    }

    function testUriGeneration() public {
        // First prepay slots
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        // Get URI
        string memory dataUri = store.uri(testUser, TEST_SLOT);

        // Verify URI format starts with data:application/json;base64,
        assertTrue(bytes(dataUri).length > 29);
        assertEq(substring(dataUri, 0, 29), "data:application/json;base64,");
    }

    function testGetNonexistentSlot() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.get(testUser, TEST_SLOT);
    }

    function testClearJson() public {
        // First prepay slots and set JSON
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        // Expect event emission
        vm.expectEmit(true, true, false, true);
        emit JsonCleared(testUser, TEST_SLOT);

        // Clear JSON
        assertTrue(store.clear(TEST_SLOT));

        // Verify slot is cleared
        assertFalse(store.exists(testUser, TEST_SLOT));
    }

    function testUnauthorizedAccess() public {
        // First prepay slots and set JSON as testUser
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        // Try to access as different user
        address unauthorized = address(0x1);
        vm.startPrank(unauthorized);

        // Verify unauthorized access fails
        assertFalse(store.exists(unauthorized, TEST_SLOT));

        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.get(unauthorized, TEST_SLOT);

        vm.stopPrank();
    }

    function testPrecompileStoreCalls() public {
        // Test the precompile store methods
        JsonStore.exists(TEST_SLOT);
        JsonStore.uri(TEST_SLOT);
        JsonStore.get(TEST_SLOT);
    }

    // Helper function
    function substring(string memory str, uint256 startIndex, uint256 endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex <= endIndex);
        require(endIndex <= strBytes.length);

        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function testAddPrepaidSlots() public {
        // Initial check
        assertEq(store.prepaid(testUser), 0);

        // Add prepaid slots
        vm.expectEmit(true, false, false, true);
        emit SlotsPrepaid(testUser, 2);
        // store.addPrepaidSlots(testUser, 2);

        // Verify slots were added
        assertEq(store.prepaid(testUser), 2);
    }

    function testMultipleSlotOperations() public {
        // Add multiple prepaid slots
        // store.addPrepaidSlots(testUser, 3);
        assertEq(store.prepaid(testUser), 3);

        // Use slots multiple times
        store.set(TEST_SLOT, TEST_JSON);
        assertEq(store.prepaid(testUser), 2);

        bytes32 secondSlot = bytes32(uint256(2));
        store.set(secondSlot, TEST_JSON);
        assertEq(store.prepaid(testUser), 1);

        // Verify both slots exist
        assertTrue(store.exists(testUser, TEST_SLOT));
        assertTrue(store.exists(testUser, secondSlot));

        // Clear first slot
        store.clear(TEST_SLOT);
        assertFalse(store.exists(testUser, TEST_SLOT));
        assertTrue(store.exists(testUser, secondSlot));
    }

    function testStorageConsistency() public {
        // store.addPrepaidSlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        // Check data consistency
        JsonStore.JsonData memory data = store.jsonStorage[TEST_SLOT];
        assertEq(data.owner, testUser);
        assertTrue(data.exists);
        assertEq(data.jsonBlob, TEST_JSON);
    }
}
