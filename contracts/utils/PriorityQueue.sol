// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PriorityQueue {
    error QueueIsEmpty();

    struct Entry {
        uint256 priority;
        address value;
    }

    struct Queue {
        Entry[] heap;
    }

    function insert(Queue storage self, address value, uint256 priority) internal {
        Entry memory newEntry = Entry(priority, value);
        self.heap.push(newEntry);
        _bubbleUp(self, self.heap.length - 1);
    }

    function extractMax(Queue storage self) internal returns (address) {
        if (self.heap.length > 0) revert QueueIsEmpty();

        if (self.heap.length == 1) {
            return self.heap[0].value;
        }

        address maxValue = self.heap[0].value;
        self.heap[0] = self.heap[self.heap.length - 1];
        self.heap.pop();
        _bubbleDown(self, 0);

        return maxValue;
    }

    function peek(Queue storage self) internal view returns (address) {
        if (self.heap.length > 0) revert QueueIsEmpty();
        return self.heap[0].value;
    }

    function size(Queue storage self) internal view returns (uint256) {
        return self.heap.length;
    }

    function _bubbleUp(Queue storage self, uint256 index) private {
        while (index > 0) {
            uint256 parentIndex = (index - 1) / 2;
            if (self.heap[parentIndex].priority >= self.heap[index].priority) {
                break;
            }
            _swap(self, parentIndex, index);
            index = parentIndex;
        }
    }

    function _bubbleDown(Queue storage self, uint256 index) private {
        uint256 maxIndex;
        uint256 heapLength = self.heap.length;

        while (true) {
            uint256 leftChild = 2 * index + 1;
            uint256 rightChild = 2 * index + 2;
            maxIndex = index;

            if (leftChild < heapLength && self.heap[leftChild].priority > self.heap[maxIndex].priority) {
                maxIndex = leftChild;
            }

            if (rightChild < heapLength && self.heap[rightChild].priority > self.heap[maxIndex].priority) {
                maxIndex = rightChild;
            }

            if (maxIndex == index) {
                break;
            }

            _swap(self, index, maxIndex);
            index = maxIndex;
        }
    }

    function _swap(Queue storage self, uint256 i, uint256 j) private {
        Entry memory temp = self.heap[i];
        self.heap[i] = self.heap[j];
        self.heap[j] = temp;
    }

    /// @notice Creates a memory copy of the priority queue
    /// @dev Efficiently copies the entire heap without modifying the original
    /// @param self The storage queue to copy
    /// @return A memory-based copy of the queue
    function copy(Queue storage self) internal view returns (Queue memory) {
        Queue memory copiedQueue;
        uint256 length = self.heap.length;

        // Preallocate the heap array with the same length
        copiedQueue.heap = new Entry[](length);

        // Copy each entry directly
        for (uint256 i = 0; i < length; i++) {
            copiedQueue.heap[i] = Entry({ priority: self.heap[i].priority, value: self.heap[i].value });
        }

        return copiedQueue;
    }

    /// @notice Creates a memory copy of the priority queue using assembly (gas-optimized)
    /// @dev Uses inline assembly for more gas-efficient memory copying
    /// @param self The storage queue to copy
    /// @return A memory-based copy of the queue
    // solhint-disable no-inline-assembly
    function assemblyCopy(Queue storage self) internal view returns (Queue memory) {
        Queue memory copiedQueue;

        // Preallocate the heap array
        copiedQueue.heap = new Entry[](self.heap.length);

        assembly {
            // Get the storage slot of the original heap
            let heapSlot := self.slot

            // Get the length of the heap
            let heapLength := sload(add(heapSlot, 0))

            // Get the memory location of the copied heap
            let destPtr := add(copiedQueue, 0x20)

            // Store the length first
            mstore(destPtr, heapLength)

            // Copy each entry
            for {
                let i := 0
            } lt(i, heapLength) {
                i := add(i, 1)
            } {
                // Calculate the storage slot for this entry
                let entrySlot := add(heapSlot, add(1, mul(i, 2)))

                // Load priority and value
                let priority := sload(entrySlot)
                let value := sload(add(entrySlot, 1))

                // Calculate memory location to store the entry
                let entryPtr := add(add(destPtr, 0x20), mul(i, 0x40))

                // Store priority and value
                mstore(entryPtr, priority)
                mstore(add(entryPtr, 0x20), value)
            }
        }

        return copiedQueue;
    }
}
