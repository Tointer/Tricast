// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

import "./ITrio.sol";
import "./TricastTrio.sol";
import "./outcome_providers/IEventOutcomeProvider.sol";
import "./Balance.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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

        balance.addTrioRole(trioAddress);
        allTrios.push(trioAddress);
        emit TrioCreated(trioAddress);
    }

    function withdraw(uint amount) external{
      balance.removeBalance(msg.sender, amount);
      Address.sendValue(payable(msg.sender), amount);
    }

    receive() external payable {
        balance.addBalance(msg.sender, msg.value);
    }
}
