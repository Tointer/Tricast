// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./OrderQueue.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OrderBook is Ownable{
    using QueueFuns for Queue;
    Queue[100] orders;

    uint8 BestSellPrice;
    uint8 BetBuyPrice = 100;

    mapping(address => uint) public synthBalances;

    function limitBuySynth(uint8 priceForEach) payable public {
        require(priceForEach > 0 && priceForEach < 100);

        Queue storage queue = getOrderQueue(priceForEach);
        queue.enqueue(Order(msg.sender, msg.value/priceForEach));
        BestSellPrice = max(priceForEach, BestSellPrice);
    }

    function limitSellSynth(uint amount, uint8 priceForEach) public {
        require(priceForEach > 0 && priceForEach < 100);

        Queue storage queue = getOrderQueue(priceForEach);
        synthBalances[msg.sender] -= amount;

        queue.enqueue(Order(msg.sender, amount));
        BetBuyPrice = min(priceForEach, BestSellPrice);
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