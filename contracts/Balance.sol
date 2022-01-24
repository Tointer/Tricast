// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Balance is Ownable, AccessControl{
    mapping(address => uint) denominatorBalances;
    bytes32 public constant TRIO_ROLE = keccak256("TRIO_ROLE");

    function getBalance(address adr) external view returns(uint balance){
        balance = denominatorBalances[adr];
    }

    function addTrioRole(address adr) public onlyOwner{
        _setupRole(TRIO_ROLE, adr);
    }

    function addBalance(address adr, uint amount) external{
        require(hasRole(TRIO_ROLE, msg.sender), "Caller is not a trio");
        denominatorBalances[adr] += amount;
    }

    function removeBalance(address adr, uint amount) external{
        require(hasRole(TRIO_ROLE, msg.sender), "Caller is not a trio");
        denominatorBalances[adr] -= amount;
    }

    receive() external payable {
        denominatorBalances[msg.sender] += msg.value;
    }
}