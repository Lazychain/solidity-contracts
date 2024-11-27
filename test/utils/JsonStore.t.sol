// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { Base64 } from "../../contracts/utils/Base64.sol";
import { JsonStore } from "../../contracts/utils/JsonStore.sol";

contract JsonStoreTest is Test {
    using JsonStore for JsonStore.Store;
    JsonStore.Store internal store;

    // Test constants
    string constant TEST_JSON = '{"name":"Test","value":123}';
    string constant INVALID_JSON = '{"name":"Test"value":123}'; // Missing comma
    string constant EMPTY_JSON = "";
    bytes32 constant TEST_SLOT = bytes32(uint256(1));
    address testUser;
    address otherUser;

    // Events
    event JsonStored(address indexed owner, bytes32 indexed slot);
    event JsonCleared(address indexed owner, bytes32 indexed slot);
    event SlotsPrepaid(address indexed owner, uint64 numSlots);

    function setUp() public {
        testUser = address(this);
        otherUser = address(0x1);
    }

    // Test Prepaid Slots Functions
    function testInitialPrepaidSlots() public {
        assertEq(store.prepaid(testUser), 0);
        assertEq(store.prepaid(), 0); // Test the msg.sender version
    }

    function testPrepaySlots() public {
        vm.expectEmit(true, false, false, true);
        emit SlotsPrepaid(testUser, 5);

        store.prepaySlots(testUser, 5);
        assertEq(store.prepaid(testUser), 5);
    }

    function testPrepayMultipleSlots() public {
        store.prepaySlots(testUser, 3);
        store.prepaySlots(testUser, 2);
        assertEq(store.prepaid(testUser), 5);
    }

    // Test Set Function
    function testSetWithoutPrepaidSlots() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__InsufficientPrepaidSlots()"));
        store.set(TEST_SLOT, TEST_JSON);
    }

    function testSetWithInvalidJson() public {
        store.prepaySlots(testUser, 1);

        vm.expectRevert(abi.encodeWithSignature("JsonStore__InvalidJson()"));
        store.set(TEST_SLOT, INVALID_JSON);
    }

    function testSetWithEmptyJson() public {
        store.prepaySlots(testUser, 1);

        vm.expectRevert(abi.encodeWithSignature("JsonStore__EmptyJson()"));
        store.set(TEST_SLOT, EMPTY_JSON);
    }

    function testSetValidJson() public {
        store.prepaySlots(testUser, 1);

        vm.expectEmit(true, true, false, true);
        emit JsonStored(testUser, TEST_SLOT);

        assertTrue(store.set(TEST_SLOT, TEST_JSON));
        assertEq(store.prepaid(testUser), 0);
    }

    function testSetExistingSlot() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotAlreadyExists()"));
        store.set(TEST_SLOT, TEST_JSON);
    }

    // Test Exists Functions
    function testExistsWithOwner() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        assertTrue(store.exists(testUser, TEST_SLOT));
        assertFalse(store.exists(otherUser, TEST_SLOT));
    }

    function testExistsWithoutOwner() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        assertTrue(store.exists(TEST_SLOT));
    }

    // Test Get Functions
    function testGetWithOwner() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        assertEq(store.get(testUser, TEST_SLOT), TEST_JSON);
    }

    function testGetWithoutOwner() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        assertEq(store.get(TEST_SLOT), TEST_JSON);
    }

    function testGetNonexistentSlot() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.get(TEST_SLOT);

        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.get(testUser, TEST_SLOT);
    }

    // Test URI Functions
    function testUriWithOwner() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        string memory uri = store.uri(testUser, TEST_SLOT);
        assertEq(substring(uri, 0, 29), "data:application/json;base64,");
    }

    function testUriWithoutOwner() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        string memory uri = store.uri(TEST_SLOT);
        assertEq(substring(uri, 0, 29), "data:application/json;base64,");
    }

    function testUriNonexistentSlot() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.uri(TEST_SLOT);

        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.uri(testUser, TEST_SLOT);
    }

    // Test Clear Function
    function testClearExistingSlot() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        vm.expectEmit(true, true, false, true);
        emit JsonCleared(testUser, TEST_SLOT);

        assertTrue(store.clear(TEST_SLOT));
        assertFalse(store.exists(TEST_SLOT));
    }

    function testClearNonexistentSlot() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.clear(TEST_SLOT);
    }

    function testClearUnauthorized() public {
        store.prepaySlots(testUser, 1);
        store.set(TEST_SLOT, TEST_JSON);

        vm.startPrank(otherUser);
        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.clear(TEST_SLOT);
        vm.stopPrank();
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
}
