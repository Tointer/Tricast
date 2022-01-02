// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./OrderBook.sol";
import "./outcome_providers/IEventOutcomeProvider.sol";
import "./OrderQueue.sol";
import "./Balance.sol";
import "./ITrio.sol";

import "hardhat/console.sol";

contract TricastTrio is ITrio{
    using QueueFuns for Queue;
    using OrderBookFuns for OrderBook;

    OrderBook public againstBook;
    OrderBook public forBook;

    Balance public balance;

    IEventOutcomeProvider public outcomeProvider;

    constructor(IEventOutcomeProvider provider) {
      outcomeProvider = provider;   
      balance = new Balance();

      againstBook.create(balance);
      forBook.create(balance);
    }

    function getBalance(address adr) external view returns(uint amount){
        amount = balance.getBalance(adr);
    }
    function getAgainstBalance(address adr) external view returns(uint amount){
        amount = againstBook.synthBalances[adr];
    }
    function getForBalance(address adr) external view returns(uint amount){
        amount = forBook.synthBalances[adr];
    }

    function mintPivotingFor(uint8 forPrice, uint8 againstPrice) private {

        Order memory pivotOrder = forBook.dequeueOrder(forPrice);
        while(againstBook.getOrderCountForPrice(againstPrice) > 0){
            Order memory order = againstBook.drain(againstPrice, pivotOrder.amount);
            
            balance.removeBalance(order.author, order.amount*againstPrice);
            balance.removeBalance(msg.sender, order.amount*forPrice);

            againstBook.mint(order.author, order.amount);
            forBook.mint(msg.sender, order.amount);
        }

        revert("This shouldn't be possible");
    }

    function mintPivotingAgainst(uint8 forPrice, uint8 againstPrice) private {

        Order memory pivotOrder = againstBook.dequeueOrder(againstPrice);
        while(forBook.getOrderCountForPrice(forPrice) > 0){
            Order memory order = forBook.drain(forPrice, pivotOrder.amount);
            
            balance.removeBalance(order.author, order.amount*againstPrice);
            balance.removeBalance(msg.sender, order.amount*forPrice);

            forBook.mint(order.author, order.amount);
            againstBook.mint(msg.sender, order.amount);
        }

        revert("This shouldn't be possible");
    }

    function getMirrorPrice(uint8 price) private pure returns (uint8 mirrorPrice)
    {
        mirrorPrice = 100 - price;
    }
    
    function forBuyMarket(uint denominatorAmount) override external {
        forBook.marketBuySynth(denominatorAmount);
    }

    function forBuyLimit(uint synthAmount, uint8 priceForEach) override external {
        forBook.limitBuySynth(priceForEach, synthAmount);

        if(againstBook.getPriceVolume(priceForEach) != 0 && forBook.getPriceVolume(priceForEach) != 0){
            uint8 mirrorPrice = getMirrorPrice(priceForEach);
            if(synthAmount < againstBook.getLastOrderAmount(mirrorPrice)){
                mintPivotingAgainst(priceForEach, mirrorPrice);
            }
            else{
                mintPivotingFor(priceForEach, mirrorPrice);
            }
        }
    }

    function forSellMarket(uint synthAmount) override external {
        forBook.marketSellSynth(synthAmount);
    }

    function forSellLimit(uint synthAmount, uint8 priceForEach) override external {
        forBook.limitSellSynth(priceForEach, synthAmount);
    }

    function againstBuyMarket(uint denominatorAmount) override external {
        againstBook.marketBuySynth(denominatorAmount);
    }

    function againstBuyLimit(uint synthAmount, uint8 priceForEach) override external {
        againstBook.limitBuySynth(priceForEach, synthAmount);
        
        if(againstBook.getPriceVolume(priceForEach) != 0 && forBook.getPriceVolume(priceForEach) != 0){
            uint8 mirrorPrice = getMirrorPrice(priceForEach);
            if(synthAmount > forBook.getLastOrderAmount(mirrorPrice)){
                mintPivotingAgainst(mirrorPrice, priceForEach);
            }
            else{
                mintPivotingFor(mirrorPrice, priceForEach);
            }
        }
    }

    function againstSellMarket(uint synthAmount) override external {
        againstBook.marketSellSynth(synthAmount);
    }

    function againstSellLimit(uint synthAmount, uint8 priceForEach) override external {
        againstBook.limitSellSynth(priceForEach, synthAmount);
    }

    receive() external payable {
        balance.addBalance(msg.sender, msg.value);
    }
}