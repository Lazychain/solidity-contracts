// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { PriorityQueue } from "../../contracts/utils/PriorityQueue.sol";

contract PriorityQueueTest is Test {
    using PriorityQueue for PriorityQueue.Queue;

    PriorityQueue.Queue private pq;

    function setUp() public {
        // Initialization logic (if needed)
    }

    function testInsertAndExtractMax() public {
        address addr1 = address(0x1);
        address addr2 = address(0x2);
        address addr3 = address(0x3);

        pq.insert(addr1, 10);
        pq.insert(addr2, 20);
        pq.insert(addr3, 15);

        assertEq(pq.size(), 3, "Queue size should be 3");
        assertEq(pq.peek(), addr2, "Max element should be addr2");

        address extracted = pq.extractMax();
        assertEq(extracted, addr2, "Extracted max should be addr2");
        assertEq(pq.size(), 2, "Queue size should decrease after extraction");
    }

    function testEmptyQueueExtractReverts() public {
        vm.expectRevert("Queue is empty");
        pq.extractMax();
    }

    function testEmptyQueuePeekReverts() public {
        vm.expectRevert("Queue is empty");
        pq.peek();
    }

    function testMultipleInsertions() public {
        address[] memory addresses = new address[](5);
        addresses[0] = address(0x1);
        addresses[1] = address(0x2);
        addresses[2] = address(0x3);
        addresses[3] = address(0x4);
        addresses[4] = address(0x5);

        pq.insert(addresses[0], 10);
        pq.insert(addresses[1], 50);
        pq.insert(addresses[2], 30);
        pq.insert(addresses[3], 40);
        pq.insert(addresses[4], 20);

        assertEq(pq.size(), 5, "Queue should have 5 elements");
        assertEq(pq.peek(), addresses[1], "Max element should be addresses[1]");
    }

    function testHeapPropertyAfterMultipleOperations() public {
        pq.insert(address(0x1), 10);
        pq.insert(address(0x2), 50);
        pq.insert(address(0x3), 30);

        assertEq(pq.extractMax(), address(0x2), "First extract should be max");
        assertEq(pq.extractMax(), address(0x3), "Second extract should be next max");
        assertEq(pq.extractMax(), address(0x1), "Third extract should be last");
    }

    function testComplexInsertionScenario() public {
        uint256 count = 100;
        for (uint256 i = 0; i < count; i++) {
            address addr = address(uint160(i + 1));
            pq.insert(addr, i);
        }

        assertEq(pq.size(), count, "Queue size should match insertions");
        assertEq(pq.peek(), address(uint160(count)), "Max element should be last inserted");
    }
}
