// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./OrderQueue.sol";

contract OrderBook{
    using QueueFuns for Queue;
    Queue[100] public orders;

    uint8 public BestSellPrice;
    uint8 public BestBuyPrice = 100;

    mapping(address => uint) public synthBalances;
    mapping(address => uint) public denominatorBalances;

    function limitBuySynth(uint8 priceForEach, uint amount) public {
        require(priceForEach > 0 && priceForEach < 100, "invalid price");
        require(denominatorBalances[msg.sender] >= amount, "not enough funds");

        denominatorBalances[msg.sender] -= amount;
        Queue storage queue = getOrderQueue(priceForEach);

        queue.enqueue(Order(msg.sender, amount/priceForEach));
        BestSellPrice = max(priceForEach, BestSellPrice);
    }

    function limitSellSynth(uint8 priceForEach, uint amount) public {
        require(priceForEach > 0 && priceForEach < 100, "invalid price");
        require(synthBalances[msg.sender] >= amount, "not enough funds");

        synthBalances[msg.sender] -= amount;
        Queue storage queue = getOrderQueue(priceForEach);

        queue.enqueue(Order(msg.sender, amount));
        BestBuyPrice = min(priceForEach, BestBuyPrice);
    }

    function marketBuySynth(uint amount) public {
        require(denominatorBalances[msg.sender] >= amount, "not enough funds");

        uint amountGathered = 0;

        for(uint8 i = BestBuyPrice; i < 100; i++){
            Queue storage queue = getOrderQueue(i);

            while(queue.getCount() > 0){
                Order memory drainedOrder = queue.drainOrderQueue(amount*i - amountGathered);

                amountGathered += drainedOrder.amount*i;
                denominatorBalances[msg.sender] -= drainedOrder.amount*i;
                denominatorBalances[drainedOrder.author] += drainedOrder.amount*i;

                synthBalances[msg.sender] += drainedOrder.amount;
                synthBalances[drainedOrder.author] -= drainedOrder.amount;

                if(amountGathered == amount){
                    return;
                }
            }

            BestBuyPrice++;
        }

        revert("not enough liqudity");
    }

    function marketSellSynth(uint amount) public {
        require(denominatorBalances[msg.sender] >= amount, "not enough funds");

        uint amountGathered = 0;

        for(uint8 i = BestSellPrice; i > 0; i--){
            Queue storage queue = getOrderQueue(i);

            while(queue.getCount() > 0){
                Order memory drainedOrder = queue.drainOrderQueue(amount - amountGathered);

                amountGathered += drainedOrder.amount;
                denominatorBalances[msg.sender] += drainedOrder.amount*i;
                denominatorBalances[drainedOrder.author] -= drainedOrder.amount*i;

                synthBalances[msg.sender] -= drainedOrder.amount;
                synthBalances[drainedOrder.author] += drainedOrder.amount;

                if(amountGathered == amount){
                    return;
                }
            }

            BestSellPrice--;
        }

        revert("not enough liqudity");
    }


    function getOrderQueue(uint8 priceForEach) private returns (Queue storage data){
        if(orders[priceForEach].first == 0){
            orders[priceForEach].create();
        }
        data = orders[priceForEach];
    }

    function max(uint8 a, uint8 b) internal pure returns (uint8) {
        return a >= b ? a : b;
    }

    function min(uint8 a, uint8 b) internal pure returns (uint8) {
        return a < b ? a : b;
    }

    receive() external payable {
        //emit Received(msg.sender, msg.value);
    }
}