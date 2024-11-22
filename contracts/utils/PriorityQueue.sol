// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PriorityQueue {
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
        require(self.heap.length > 0, "Queue is empty");
        
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
        require(self.heap.length > 0, "Queue is empty");
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

            if (leftChild < heapLength && 
                self.heap[leftChild].priority > self.heap[maxIndex].priority) {
                maxIndex = leftChild;
            }

            if (rightChild < heapLength && 
                self.heap[rightChild].priority > self.heap[maxIndex].priority) {
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
}