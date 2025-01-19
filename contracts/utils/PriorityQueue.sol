// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library PriorityQueue {
    error PriorityQueue__QueueIsEmpty();

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

    function peek(Queue storage self) internal view returns (address) {
        if (self.heap.length == 0) revert PriorityQueue__QueueIsEmpty();
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

    function copy(Queue storage self) internal view returns (Queue memory) {
        Queue memory copiedQueue;
        uint256 length = self.heap.length;

        copiedQueue.heap = new Entry[](length);

        for (uint256 i = 0; i < length; i++) {
            copiedQueue.heap[i] = Entry({ priority: self.heap[i].priority, value: self.heap[i].value });
        }

        return copiedQueue;
    }

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
