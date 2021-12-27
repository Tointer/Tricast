// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

interface IEventOutcomeProvider{

   function getEventOutcome() external returns(EventOutcome);

   enum EventOutcome{NOT_HAPPENED, RESOLVED_TRUE, RESOLVED_FALSE}
   
}

