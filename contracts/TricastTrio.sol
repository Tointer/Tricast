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

    IEventOutcomeProvider.EventOutcome public currentState;

    IEventOutcomeProvider public outcomeProvider;

    constructor(IEventOutcomeProvider provider, Balance denominatorBalance) {
        require(address(denominatorBalance) != address(0));
        outcomeProvider = provider;   
        balance = denominatorBalance;
        againstBook.create(balance);
        forBook.create(balance);
    }

    function getDenominatorBalance(address adr) external view returns(uint amount){
        amount = balance.getBalance(adr);
    }
    function getAgainstBalance(address adr) external view returns(uint amount){
        amount = againstBook.synthBalances[adr];
    }
    function getForBalance(address adr) external view returns(uint amount){
        amount = forBook.synthBalances[adr];
    }
    function getForOrderCount(uint8 price) external view returns(uint count){
        count = forBook.getOrderCountForPrice(price);
    }
    function getAgainstOrderCount(uint8 price) external view returns(uint count){
        count = againstBook.getOrderCountForPrice(price);
    }
    function getForPriceVolume(uint8 price) external view returns(uint volume){
        volume = forBook.getPriceVolume(price);
    }
    function getAgainstPriceVolume(uint8 price) external view returns(uint volume){
        volume = againstBook.getPriceVolume(price);
    }


    function mintPivotingFor(uint8 forPrice, uint8 againstPrice) private {

        Order memory pivotOrder = forBook.dequeueOrder(forPrice);
        uint gatheredAmount;


        while(againstBook.getOrderCountForPrice(againstPrice) > 0){
            Order memory order = againstBook.drain(againstPrice, pivotOrder.amount);
            
            againstBook.mint(order.author, order.amount);
            forBook.mint(pivotOrder.author, order.amount);

            gatheredAmount += order.amount;

            if(gatheredAmount == pivotOrder.amount){
                return;
            }
        }

        revert("This shouldn't be possible");
    }

    function mintPivotingAgainst(uint8 forPrice, uint8 againstPrice) private {

        Order memory pivotOrder = againstBook.dequeueOrder(againstPrice);
        uint gatheredAmount;

        while(forBook.getOrderCountForPrice(forPrice) > 0){
            Order memory order = forBook.drain(forPrice, pivotOrder.amount);

            forBook.mint(order.author, order.amount);
            againstBook.mint(pivotOrder.author, order.amount);

            gatheredAmount += order.amount;

            if(gatheredAmount == pivotOrder.amount){
                return;
            }
        }

        revert("This shouldn't be possible");
    }

    function getMirrorPrice(uint8 price) private pure returns (uint8 mirrorPrice)
    {
        mirrorPrice = 100 - price;
    }
    
    function forBuyMarket(uint denominatorAmount) override external onlyBeforeResolve{
        forBook.marketBuySynth(denominatorAmount);
    }

    function forBuyLimit(uint synthAmount, uint8 priceForEach) override external onlyBeforeResolve{
        forBook.limitBuySynth(priceForEach, synthAmount);
        uint8 mirrorPrice = getMirrorPrice(priceForEach);

        if(againstBook.getPriceVolume(mirrorPrice) != 0 && forBook.getPriceVolume(priceForEach) != 0){
            if(synthAmount < againstBook.getLastOrderAmount(mirrorPrice)){
                mintPivotingAgainst(priceForEach, mirrorPrice);
            }
            else{
                mintPivotingFor(priceForEach, mirrorPrice);
            }
        }
    }

    function forSellMarket(uint synthAmount) override external onlyBeforeResolve{
        forBook.marketSellSynth(synthAmount);
    }

    function forSellLimit(uint synthAmount, uint8 priceForEach) override external onlyBeforeResolve{
        forBook.limitSellSynth(priceForEach, synthAmount);
    }

    function againstBuyMarket(uint denominatorAmount) override external onlyBeforeResolve{
        againstBook.marketBuySynth(denominatorAmount);
    }

    function againstBuyLimit(uint synthAmount, uint8 priceForEach) override external onlyBeforeResolve{
        againstBook.limitBuySynth(priceForEach, synthAmount);
        uint8 mirrorPrice = getMirrorPrice(priceForEach);
        
        if(againstBook.getPriceVolume(priceForEach) != 0 && forBook.getPriceVolume(mirrorPrice) != 0){
            if(synthAmount > forBook.getLastOrderAmount(mirrorPrice)){
                mintPivotingAgainst(mirrorPrice, priceForEach);
            }
            else{
                mintPivotingFor(mirrorPrice, priceForEach);
            }
        }
    }

    function againstSellMarket(uint synthAmount) override external onlyBeforeResolve{
        againstBook.marketSellSynth(synthAmount);
    }

    function againstSellLimit(uint synthAmount, uint8 priceForEach) override external onlyBeforeResolve{
        againstBook.limitSellSynth(priceForEach, synthAmount);
    }

    function removeForLimit(uint8 price, uint index) override external{
        forBook.removeLimitOrder(price, index);
    }
    
    function removeAgainstLimit(uint8 price, uint index) override external{
        againstBook.removeLimitOrder(price, index);
    }

    function claimWinnings() override external onlyAfterResolve{
        if(currentState == IEventOutcomeProvider.EventOutcome.RESOLVED_TRUE){
            forBook.claimWinnings(100);
        }
        else{
            againstBook.claimWinnings(100);
        }
    }

    function tryResolve() override external onlyBeforeResolve{
        IEventOutcomeProvider.EventOutcome outcome = outcomeProvider.getEventOutcome();
        require(outcome != IEventOutcomeProvider.EventOutcome.NOT_HAPPENED, "Can't resolve now");

        console.log("Resolved: %s", uint(outcome));
        currentState = outcome;
    }

    modifier onlyBeforeResolve(){
        require(currentState == IEventOutcomeProvider.EventOutcome.NOT_HAPPENED, "TRICAST_TRIO: CAN'T DO IT AFTER RESOLVE");
        _;
    }

    modifier onlyAfterResolve(){
        require(currentState != IEventOutcomeProvider.EventOutcome.NOT_HAPPENED, "TRICAST_TRIO: CAN'T DO IT BEFORE RESOLVE");
        _;
    }
}