// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

struct Queue {
    mapping(uint256 => Order) queue;
    uint256 first;
    uint256 last;
}

library QueueFuns {
    function create(Queue storage self) internal {
        self.first = 1;
    }
    
    function enqueue(Queue storage self, Order memory order) public {
        self.last += 1;
        self.queue[self.last] = order;
    }

    function dequeue(Queue storage self) public returns (Order memory data) {
        require(self.last >= self.first);  // non-empty queue

        data = self.queue[self.first];

        delete self.queue[self.first];
        self.first += 1;
    }
}

struct Order {
    address author;
    uint amount;
}