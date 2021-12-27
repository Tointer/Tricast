// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./OrderBook.sol";
import "./IEventOutcomeProvider.sol";

contract TokenPriceOracle is IEventOutcomeProvider{

    address _oracleAddress;

    constructor(address oracleAddress) {
        _oracleAddress = oracleAddress;
    }

    function getEventOutcome() public override returns(IEventOutcomeProvider.EventOutcome eventOutcome){

    }
}

