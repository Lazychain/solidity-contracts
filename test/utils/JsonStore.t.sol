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
    string constant INVALID_JSON = "{name:Test}"; // Actually invalid JSON
    string constant EMPTY_JSON = "";
    bytes32 constant TEST_SLOT = bytes32(uint256(1));
    address testUser;
    address otherUser;

    event JsonStored(address indexed owner, bytes32 indexed slot);
    event JsonCleared(address indexed owner, bytes32 indexed slot);
    event SlotsPrepaid(address indexed owner, uint64 numSlots);

    function setUp() public {
        testUser = address(this);
        otherUser = address(0x1);
        // Pre-pay some slots for most tests
        store.prepay(testUser, 10);
    }

    function testInitialPrepaidSlots() public {
        assertEq(store.prepaid(otherUser), 0, "New user should have 0 prepaid slots");

        assertEq(store.prepaid(testUser), 10, "Test user should have 10 prepaid slots from setUp");

        store.prepay(otherUser, 5);
        assertEq(store.prepaid(otherUser), 5, "Other user should now have 5 prepaid slots");
    }

    function testPrepaySlots() public {
        vm.expectEmit(true, false, false, true);
        emit SlotsPrepaid(otherUser, 5);

        store.prepay(otherUser, 5);
        assertEq(store.prepaid(otherUser), 5);
    }

    function testPrepayMultipleSlots() public {
        store.prepay(otherUser, 3);
        store.prepay(otherUser, 2);
        assertEq(store.prepaid(otherUser), 5);
    }

    // Set Function Tests
    function testSetWithoutPrepaidSlots() public {
        vm.prank(otherUser); // Switch to unpaid user
        vm.expectRevert(abi.encodeWithSignature("JsonStore__InsufficientPrepaidSlots()"));
        store.set(TEST_SLOT, TEST_JSON);
    }

    function testSetWithInvalidJson() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__InvalidJson()"));
        store.set(TEST_SLOT, INVALID_JSON);
    }

    function testSetWithEmptyJson() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__EmptyJson()"));
        store.set(TEST_SLOT, EMPTY_JSON);
    }

    function testSetValidJson() public {
        uint64 initialPrepaid = store.prepaid(testUser);

        vm.expectEmit(true, true, false, true);
        emit JsonStored(testUser, TEST_SLOT);

        assertTrue(store.set(TEST_SLOT, TEST_JSON));
        assertEq(store.prepaid(testUser), initialPrepaid - 1);
    }

    function testSetExistingSlot() public {
        store.set(TEST_SLOT, TEST_JSON);
        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotAlreadyExists()"));
        store.set(TEST_SLOT, TEST_JSON);
    }

    // Exists Function Tests
    function testExistsWithOwner() public {
        store.set(TEST_SLOT, TEST_JSON);
        assertTrue(store.exists(testUser, TEST_SLOT));
        assertFalse(store.exists(otherUser, TEST_SLOT));
    }

    function testExistsWithoutOwner() public {
        store.set(TEST_SLOT, TEST_JSON);
        assertTrue(store.exists(TEST_SLOT));
    }

    // Get Function Tests
    function testGetWithOwner() public {
        store.set(TEST_SLOT, TEST_JSON);
        assertEq(store.get(testUser, TEST_SLOT), TEST_JSON);
    }

    function testGetWithoutOwner() public {
        store.set(TEST_SLOT, TEST_JSON);
        assertEq(store.get(TEST_SLOT), TEST_JSON);
    }

    function testGetNonexistentSlot() public {
        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.get(TEST_SLOT);

        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.get(testUser, TEST_SLOT);
    }

    // URI Function Tests
    function testUriWithOwner() public {
        store.set(TEST_SLOT, TEST_JSON);
        string memory uri = store.uri(testUser, TEST_SLOT);
        assertEq(substring(uri, 0, 29), "data:application/json;base64,");
    }

    function testUriWithoutOwner() public {
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

    // Clear Function Tests
    function testClearExistingSlot() public {
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
        store.set(TEST_SLOT, TEST_JSON);

        vm.prank(otherUser);
        vm.expectRevert(abi.encodeWithSignature("JsonStore__SlotDoesNotExist()"));
        store.clear(TEST_SLOT);
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
