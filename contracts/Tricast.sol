// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./ITrio.sol";
import "./TricastTrio.sol";
import "./outcome_providers/IEventOutcomeProvider.sol";
import "./Balance.sol";

contract Tricast{
    event TrioCreated(address trio);

    address[] public allTrios;
    Balance public balance;

    IEventOutcomeProvider public outcomeProvider;

    constructor() {  
      balance = new Balance();
    }

    function createTrio(address oracleAddress) external returns (address trioAddress){
        require(oracleAddress != address(0), "TRICAST: ZERO_ADDRESS");

        TricastTrio trio = new TricastTrio(IEventOutcomeProvider(oracleAddress), balance);

        trioAddress = address(trio);
        allTrios.push(trioAddress);
        emit TrioCreated(trioAddress);
    }
}
