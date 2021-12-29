// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./IEventOutcomeProvider.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 

contract TokenPriceOracle is IEventOutcomeProvider{

    AggregatorV3Interface internal priceFeed; 
    uint public resolveDate; 
    uint public targetPrice; 

    constructor(address oracleAddress, uint eventResolveDate, uint coinTargetPrice) {
        priceFeed = AggregatorV3Interface(oracleAddress); 
        resolveDate = eventResolveDate;
        targetPrice = coinTargetPrice;
    }

    function getEventOutcome() public view override returns (IEventOutcomeProvider.EventOutcome eventOutcome){
        (int price, uint timestamp) = getLatestPrice();

        require(price >= 0, "Price can't be negative"); 
        eventOutcome = EventOutcome.NOT_HAPPENED;

        if(resolveDate <= timestamp) {
            if(uint(price) >= targetPrice) {
                eventOutcome = EventOutcome.RESOLVED_TRUE;
            }
            else {
                eventOutcome = EventOutcome.RESOLVED_FALSE;
            }
        }
    }

    function getLatestPrice() public view returns (int, uint) {
        (
            uint80 roundID, 
            int price, 
            uint startedAt, 
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData(); 
        return (price, timeStamp);
    }
}

