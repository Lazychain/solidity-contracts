// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

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
        if (self.heap.length == 0) revert QueueIsEmpty();

        address maxValue = self.heap[0].value;
        
        if (self.heap.length == 1) {
            self.heap.pop();
            return maxValue;
        }

        self.heap[0] = self.heap[self.heap.length - 1];
        self.heap.pop();
        _bubbleDown(self, 0);

        return maxValue;
    }

    function peek(Queue storage self) internal view returns (address) {
        if (self.heap.length == 0) revert QueueIsEmpty();
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
            copiedQueue.heap[i] = Entry({ 
                priority: self.heap[i].priority, 
                value: self.heap[i].value 
            });
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
    
    uint256 length = self.heap.length;
    if (length == 0) {
        return copiedQueue;
    }
    
    Entry[] memory newHeap = new Entry[](length);
    
    assembly {
        // Get array slot (self.heap array location)
        mstore(0x00, self.slot) // slot of Queue struct
        let heapArraySlot := keccak256(0x00, 0x20) // slot of heap array
        
        // Get pointer to destination memory array data
        let destPtr := add(newHeap, 0x20)
        
        for { let i := 0 } lt(i, length) { i := add(i, 1) } {
            // Each Entry struct takes 2 slots in storage
            let entrySlot := add(heapArraySlot, mul(i, 2))
            
            // Each Entry takes 64 bytes in memory
            let destEntryPtr := add(destPtr, mul(i, 0x40))
            
            // Copy priority (first slot of Entry)
            mstore(destEntryPtr, sload(entrySlot))
            
            // Copy address (second slot of Entry)
            mstore(add(destEntryPtr, 0x20), sload(add(entrySlot, 1)))
        }
    }
    
    copiedQueue.heap = newHeap;
    return copiedQueue;
}
}