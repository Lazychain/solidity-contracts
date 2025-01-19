// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { PriorityQueue } from "../../contracts/utils/PriorityQueue.sol";

contract PriorityQueueTest is Test {
    using PriorityQueue for PriorityQueue.Queue;

    PriorityQueue.Queue private pq;

    function setUp() public {}

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
        vm.expectRevert(PriorityQueue.PriorityQueue__QueueIsEmpty.selector);
        pq.extractMax();
    }

    function testEmptyQueuePeekReverts() public {
        vm.expectRevert(PriorityQueue.PriorityQueue__QueueIsEmpty.selector);
        pq.peek();
    }

    function testSingleElementQueue() public {
        address addr1 = address(0x1);
        pq.insert(addr1, 10);

        assertEq(pq.size(), 1, "Queue size should be 1");
        assertEq(pq.peek(), addr1, "Peek should return single element");

        address extracted = pq.extractMax();
        assertEq(extracted, addr1, "Should extract single element");
        assertEq(pq.size(), 0, "Queue should be empty after extraction");
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

        assertTrue(pq.size() == 0, "Queue should be empty after extracting all elements");
    }

    function testBubbleUpWithEqualPriorities() public {
        address addr1 = address(0x1);
        address addr2 = address(0x2);
        address addr3 = address(0x3);

        // Insert elements with equal priorities
        pq.insert(addr1, 10);
        pq.insert(addr2, 10);
        pq.insert(addr3, 10);

        assertEq(pq.size(), 3, "Queue size should be 3");
        // First inserted element should stay at root for equal priorities
        assertEq(pq.peek(), addr1, "First element should remain at root");
    }

    function testComplexBubbleUpScenario() public {
        // Insert elements that require multiple bubble-up operations
        pq.insert(address(0x1), 10);
        pq.insert(address(0x2), 20);
        pq.insert(address(0x3), 30);
        pq.insert(address(0x4), 40);
        pq.insert(address(0x5), 50); // Should bubble up to root

        assertEq(pq.peek(), address(0x5), "Highest priority should bubble to root");

        // Insert a lower priority element
        pq.insert(address(0x6), 15);
        assertEq(pq.peek(), address(0x5), "Root should not change");
    }

    function testComplexBubbleDownScenario() public {
        // Setup a heap that will require multiple bubble-down operations
        pq.insert(address(0x1), 50); // Root
        pq.insert(address(0x2), 40);
        pq.insert(address(0x3), 45);
        pq.insert(address(0x4), 30);
        pq.insert(address(0x5), 35);

        address[] memory expectedOrder = new address[](5);
        expectedOrder[0] = address(0x1); // 50
        expectedOrder[1] = address(0x3); // 45
        expectedOrder[2] = address(0x2); // 40
        expectedOrder[3] = address(0x5); // 35
        expectedOrder[4] = address(0x4); // 30

        // Extract all and verify order
        for (uint256 i = 0; i < expectedOrder.length; i++) {
            address extracted = pq.extractMax();
            assertEq(
                extracted,
                expectedOrder[i],
                string.concat("Incorrect extraction order at position ", vm.toString(i))
            );
        }
    }

    function testEdgeCasePriorities() public {
        // Test with extreme priority values
        pq.insert(address(0x1), type(uint256).max);
        pq.insert(address(0x2), type(uint256).min);
        pq.insert(address(0x3), type(uint256).max - 1);

        assertEq(pq.peek(), address(0x1), "Max uint256 priority should be at root");
        assertEq(pq.extractMax(), address(0x1), "Should extract max uint256 priority first");
        assertEq(pq.extractMax(), address(0x3), "Should extract max-1 priority second");
        assertEq(pq.extractMax(), address(0x2), "Should extract min priority last");
    }

    function testComplexInsertionScenario() public {
        uint256 count = 100;
        address[] memory addresses = new address[](count);
        uint256[] memory priorities = new uint256[](count);

        // Insert with various priority patterns
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = address(uint160(i + 1));
            // Create an interesting priority pattern
            if (i % 2 == 0) {
                priorities[i] = i * 2; // Even indexes get doubled
            } else {
                priorities[i] = count - i; // Odd indexes get reversed
            }
            pq.insert(addresses[i], priorities[i]);
        }

        assertEq(pq.size(), count, "Queue size should match insertions");

        // Find expected maximum priority and corresponding address
        uint256 maxPriority = 0;
        address expectedMax;
        for (uint256 i = 0; i < count; i++) {
            if (priorities[i] > maxPriority) {
                maxPriority = priorities[i];
                expectedMax = addresses[i];
            }
        }

        assertEq(pq.peek(), expectedMax, "Max element should match calculated maximum");
    }

    function testCopyQueue() public {
        // Insert elements with various priorities
        address addr1 = address(0x1);
        address addr2 = address(0x2);
        address addr3 = address(0x3);

        pq.insert(addr1, 10);
        pq.insert(addr2, 20);
        pq.insert(addr3, 15);

        // Create a copy
        PriorityQueue.Queue memory copiedQueue = pq.copy();

        // Verify the copy has the same length
        assertEq(copiedQueue.heap.length, 3, "Copied queue should have same length");

        // Verify all elements and priorities are copied correctly
        assertEq(copiedQueue.heap[0].value, addr2, "First element should be addr2");
        assertEq(copiedQueue.heap[0].priority, 20, "First element should have priority 20");

        // Verify the entire structure
        for (uint256 i = 0; i < pq.size(); i++) {
            assertEq(
                copiedQueue.heap[i].priority,
                pq.heap[i].priority,
                string.concat("Priority mismatch at index ", vm.toString(i))
            );
            assertEq(
                copiedQueue.heap[i].value,
                pq.heap[i].value,
                string.concat("Value mismatch at index ", vm.toString(i))
            );
        }
    }

    // function testAssemblyCopy() public {
    //     // Test with empty queue
    //     PriorityQueue.Queue memory emptyQueueCopy = pq.assemblyCopy();
    //     assertEq(emptyQueueCopy.heap.length, 0, "Empty queue copy should have length 0");

    //     // Insert elements with various priorities
    //     pq.insert(address(0x1), 10);
    //     pq.insert(address(0x2), 20);
    //     pq.insert(address(0x3), 15);

    //     // Create a copy using assembly
    //     PriorityQueue.Queue memory copiedQueue = pq.assemblyCopy();

    //     // Verify the copy has the same length
    //     assertEq(copiedQueue.heap.length, 3, "Copied queue should have same length");

    //     // Verify all elements and priorities are copied correctly
    //     assertEq(copiedQueue.heap[0].value, address(0x2), "First element should be addr2");
    //     assertEq(copiedQueue.heap[0].priority, 20, "First element should have priority 20");

    //     // Verify the entire structure
    //     for (uint256 i = 0; i < pq.size(); i++) {
    //         assertEq(
    //             copiedQueue.heap[i].priority,
    //             pq.heap[i].priority,
    //             string.concat("Priority mismatch at index ", vm.toString(i))
    //         );
    //         assertEq(
    //             copiedQueue.heap[i].value,
    //             pq.heap[i].value,
    //             string.concat("Value mismatch at index ", vm.toString(i))
    //         );
    //     }
    // }

    function testRepeatedExtractMax() public {
        // Insert a significant number of elements
        uint256[] memory priorities = new uint256[](10);
        priorities[0] = 15;
        priorities[1] = 50;
        priorities[2] = 30;
        priorities[3] = 40;
        priorities[4] = 25;
        priorities[5] = 35;
        priorities[6] = 20;
        priorities[7] = 45;
        priorities[8] = 10;
        priorities[9] = 5;

        for (uint256 i = 0; i < priorities.length; i++) {
            pq.insert(address(uint160(i + 1)), priorities[i]);
        }

        // Extract all elements and verify they come out in descending priority order
        uint256 lastPriority = type(uint256).max;
        uint256 originalSize = pq.size();

        for (uint256 i = 0; i < originalSize; i++) {
            address maxAddr = pq.extractMax();
            uint256 currentPriority = priorities[uint160(maxAddr) - 1];
            assertTrue(currentPriority <= lastPriority, "Priorities should be in descending order");
            lastPriority = currentPriority;
        }

        assertEq(pq.size(), 0, "Queue should be empty after extracting all elements");
    }
}
