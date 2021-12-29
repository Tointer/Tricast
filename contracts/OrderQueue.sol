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
        data = peek(self);

        delete self.queue[self.first];
        self.first += 1;
    }

    function peek(Queue storage self) public view returns (Order memory data){
        require(self.last >= self.first, "queue is empty");  
        data = self.queue[self.first];
    }

    function drainOrderQueue(Queue storage self, uint amount) 
    public returns(Order memory drainedOrder){

        Order memory nextOrder = peek(self);

        if(nextOrder.amount <= amount){
            drainedOrder = dequeue(self);
        }
        else{
            drainedOrder = Order(nextOrder.author, amount);
            nextOrder.amount -= amount;
        }
    }

    function getCount(Queue storage self) public view returns(uint count){
        return self.last - self.first;
    }
}

struct Order {
    address author;
    uint amount;
}
