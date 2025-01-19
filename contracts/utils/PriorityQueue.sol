// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PriorityQueue - A max heap implementation of a priority queue for addresses
/// @notice This library implements a max-priority queue where elements (addresses) are
///         ordered by their associated priority values
/// @dev Uses a binary heap stored in an array to maintain the queue efficiently
library PriorityQueue {
    error PriorityQueue__QueueIsEmpty();

    struct Entry {
        uint256 priority;
        address value;
    }

    struct Queue {
        Entry[] heap;
    }

    /// @notice Inserts a new address into the queue with the specified priority
    /// @dev Time complexity: O(log n) where n is the size of the queue
    /// @param self The queue to insert into
    /// @param value The address to insert
    /// @param priority The priority value associated with the address
    function insert(Queue storage self, address value, uint256 priority) internal {
        Entry memory newEntry = Entry(priority, value);
        self.heap.push(newEntry);
        _bubbleUp(self, self.heap.length - 1);
    }

    /// @notice Removes and returns the address with the highest priority
    /// @dev Time complexity: O(log n) where n is the size of the queue
    /// @param self The queue to extract from
    /// @return The address with the highest priority
    /// @custom:throws QueueIsEmpty if the queue is empty
    function extractMax(Queue storage self) internal returns (address) {
        if (self.heap.length == 0) revert PriorityQueue__QueueIsEmpty();

        address maxValue = self.heap[0].value;

        if (self.heap.length > 1) {
            self.heap[0] = self.heap[self.heap.length - 1];
            self.heap.pop();
            _bubbleDown(self, 0);
        } else {
            self.heap.pop();
        }

        return maxValue;
    }

    /// @notice Returns the address with the highest priority without removing it
    /// @dev Time complexity: O(1)
    /// @param self The queue to peek into
    /// @return The address with the highest priority
    /// @custom:throws QueueIsEmpty if the queue is empty
    function peek(Queue storage self) internal view returns (address) {
        if (self.heap.length == 0) revert PriorityQueue__QueueIsEmpty();
        return self.heap[0].value;
    }

    /// @notice Returns the current size of the queue
    /// @dev Time complexity: O(1)
    /// @param self The queue to get the size of
    /// @return The number of elements in the queue
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

    /// @notice Moves an entry down the heap to maintain the heap property
    /// @dev Internal function used by extractMax
    /// @param self The queue being modified
    /// @param index The index of the entry to move down
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

    /// @notice Swaps two entries in the heap
    /// @dev Internal function used by _bubbleUp and _bubbleDown
    /// @param self The queue being modified
    /// @param i The index of the first entry to swap
    /// @param j The index of the second entry to swap
    function _swap(Queue storage self, uint256 i, uint256 j) private {
        Entry memory temp = self.heap[i];
        self.heap[i] = self.heap[j];
        self.heap[j] = temp;
    }

    /// @notice Creates a memory copy of the priority queue
    /// @dev Time complexity: O(n) where n is the size of the queue
    /// @param self The storage queue to copy
    /// @return A memory-based copy of the queue
    function copy(Queue storage self) internal view returns (Queue memory) {
        Queue memory copiedQueue;
        uint256 length = self.heap.length;

        copiedQueue.heap = new Entry[](length);

        for (uint256 i = 0; i < length; i++) {
            copiedQueue.heap[i] = Entry({ priority: self.heap[i].priority, value: self.heap[i].value });
        }

        return copiedQueue;
    }

    /// @notice Creates a memory copy of the priority queue using assembly for gas optimization
    /// @dev Uses inline assembly for more efficient memory operations
    /// @dev Time complexity: O(n) where n is the size of the queue
    /// @param self The storage queue to copy
    /// @return A memory-based copy of the queue
    // solhint-disable-next-line no-inline-assembly
    function assemblyCopy(Queue storage self) internal view returns (Queue memory) {
        Queue memory copiedQueue;
        copiedQueue.heap = new Entry[](self.heap.length);

        assembly {
            let heapSlot := self.slot
            let heapLength := sload(heapSlot)
            let destPtr := add(copiedQueue, 0x20)

            mstore(destPtr, heapLength)

            for {
                let i := 0
            } lt(i, heapLength) {
                i := add(i, 1)
            } {
                let entrySlot := add(heapSlot, add(1, mul(i, 2)))
                let priority := sload(entrySlot)
                let value := sload(add(entrySlot, 1))
                let entryPtr := add(add(destPtr, 0x20), mul(i, 0x40))
                mstore(entryPtr, priority)
                mstore(add(entryPtr, 0x20), value)
            }
        }

        return copiedQueue;
    }
}
