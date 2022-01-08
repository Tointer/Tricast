// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./OrderQueue.sol";
import "./Balance.sol";


import "hardhat/console.sol";

struct OrderBook{
    Queue[100] orders;

    uint8 bestSellPrice;
    uint8 bestBuyPrice;

    mapping(address => uint) synthBalances;
    Balance balance;

    
}

library OrderBookFuns{
    using QueueFuns for Queue;

    event BestSellPriceChanged(uint8 newValue);
    event BestBuyPriceChanged(uint8 newValue);

    function create(OrderBook storage self, Balance balance) internal {
        self.bestBuyPrice = 100;
        self.balance = balance;
    }

    function getOrderCountForPrice(OrderBook storage self, uint8 price) internal view returns(uint count){
        count = self.orders[price].getCount();
    }

    function getPriceVolume(OrderBook storage self, uint8 price) internal view returns(uint count){
        count = self.orders[price].volume;
    }

    function getLastOrderAmount(OrderBook storage self, uint8 price) internal view returns(uint amount){
        amount = self.orders[price].peek().amount;
    }

    function dequeueOrder(OrderBook storage self, uint8 price) internal returns(Order memory order){
        order = self.orders[price].dequeue();
    }

    function drain(OrderBook storage self, uint8 price, uint amount) internal returns(Order memory order){
        order = self.orders[price].drainOrderQueue(amount);
    }

    function removeLimitOrder(OrderBook storage self, uint8 price, uint index) internal{
        uint amount = self.orders[price].nullifyOrder(index, msg.sender);

        if(price <= self.bestSellPrice){
            self.balance.addBalance(msg.sender, amount*price);
        }
        else{
            self.synthBalances[msg.sender] += amount;
        }
    }

    function claimWinnings(OrderBook storage self, uint8 finalPrice) internal{
        if(finalPrice == 0){
            return;
        }
        uint amount = self.synthBalances[msg.sender];
        
        self.synthBalances[msg.sender] = 0;
        self.balance.addBalance(msg.sender, amount*finalPrice);
    }

    function mint(OrderBook storage self, address adr, uint amount) internal{
        self.synthBalances[adr] += amount;
    }

    function limitBuySynth(OrderBook storage self, uint8 priceForEach, uint amount) internal {
        require(priceForEach > 0 && priceForEach < 100, "invalid price");

        self.balance.removeBalance(msg.sender, amount*priceForEach);

        self.orders[priceForEach].enqueue(Order(msg.sender, amount));

        if(self.bestSellPrice < priceForEach){
            self.bestSellPrice = priceForEach;
            emit BestSellPriceChanged(priceForEach);
        }
    }

    function limitSellSynth(OrderBook storage self, uint8 priceForEach, uint amount) internal {
        require(priceForEach > 0 && priceForEach < 100, "invalid price");
        require(self.synthBalances[msg.sender] >= amount, "not enough funds");

        self.synthBalances[msg.sender] -= amount;

        self.orders[priceForEach].enqueue(Order(msg.sender, amount));

        if(self.bestBuyPrice > priceForEach){
            self.bestBuyPrice = priceForEach;
            emit BestBuyPriceChanged(priceForEach);
        }
    }

    function marketBuySynth(OrderBook storage self, uint amount) internal {
        //require(self.denominatorBalances[msg.sender] >= amount, "not enough funds");

        uint amountGathered = 0;

        for(uint8 i = self.bestBuyPrice; i < 100; i++){
            Queue storage queue = self.orders[i];

            while(queue.getCount() > 0){
                Order memory drainedOrder = queue.drainOrderQueue(amount/i - amountGathered/i);
                amountGathered += drainedOrder.amount*i;
                self.balance.removeBalance(msg.sender, drainedOrder.amount*i);
                self.balance.addBalance(drainedOrder.author, drainedOrder.amount*i);

                self.synthBalances[msg.sender] += drainedOrder.amount;

                if(amountGathered == amount){
                    return;
                }
            }

            self.bestBuyPrice++;
        }

        revert("not enough liqudity");
    }

    function marketSellSynth(OrderBook storage self, uint amount) internal {
        //require(self.denominatorBalances[msg.sender] >= amount, "not enough funds");

        uint amountGathered = 0;

        for(uint8 i = self.bestSellPrice; i > 0; i--){
            Queue storage queue = self.orders[i];

            while(queue.getCount() > 0){
                Order memory drainedOrder = queue.drainOrderQueue(amount - amountGathered);

                amountGathered += drainedOrder.amount;
                
                self.balance.addBalance(msg.sender, drainedOrder.amount*i);

                self.synthBalances[msg.sender] -= drainedOrder.amount;
                self.synthBalances[drainedOrder.author] += drainedOrder.amount;

                if(amountGathered == amount){
                    return;
                }
            }

            self.bestSellPrice--;
        }

        revert("not enough liqudity");
    }
}