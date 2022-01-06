// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  
import "hardhat/console.sol";

struct Queue {
    mapping(uint256 => Order) queue;
    uint256 first;
    uint256 last;
    uint256 volume;
}

library QueueFuns {
    function enqueue(Queue storage self, Order memory order) internal {
        self.queue[self.last] = order;

        self.last += 1;
        self.volume += order.amount;
    }

    function dequeue(Queue storage self) internal returns (Order memory data) {
        data = peek(self);

        delete self.queue[self.first];
        self.first += 1;

        self.volume -= data.amount;
    }

    function nullifyOrder(Queue storage self, uint index, address wallet) internal returns (uint amountDeleted){
        require(index >= self.first && index <= self.last, "Index out of bounds");
        require(self.queue[index].author == wallet, "You are not author of this order");

        amountDeleted = self.queue[index].amount;
        self.queue[index].amount = 0;
        self.volume -= amountDeleted;
    }

    function peek(Queue storage self) internal view returns (Order memory data){
        require(self.last > self.first, "queue is empty");  
        data = self.queue[self.first];
    }

    function drainOrderQueue(Queue storage self, uint amount) 
    internal returns(Order memory drainedOrder){

        Order memory nextOrder = peek(self);

        if(nextOrder.amount <= amount){
            drainedOrder = dequeue(self);
        }
        else{
            drainedOrder = Order(nextOrder.author, amount);
            nextOrder.amount -= amount;
            self.volume -= amount;
        }
    }

    function getCount(Queue storage self) internal view returns(uint count){
        return self.last - self.first;
    }
}

struct Order {
    address author;
    uint amount;
}
