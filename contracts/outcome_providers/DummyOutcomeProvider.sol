// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./IEventOutcomeProvider.sol";

contract DummyOutcomeProvider is IEventOutcomeProvider{

    IEventOutcomeProvider.EventOutcome public eventOutcome;

    function getEventOutcome() public view override returns (IEventOutcomeProvider.EventOutcome){
        return eventOutcome;
    }

    function setEventOutcome(EventOutcome outcome) public{
        eventOutcome = outcome;
    }
}
