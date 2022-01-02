// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

contract Balance{
    mapping(address => uint) denominatorBalances;

    function getBalance(address adr) external view returns(uint balance){
        balance = denominatorBalances[adr];
    }

    function addBalance(address adr, uint amount) external{
        denominatorBalances[adr] += amount;
    }

    function removeBalance(address adr, uint amount) external{
        denominatorBalances[adr] -= amount;
    }
}