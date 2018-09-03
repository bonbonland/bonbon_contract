pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract DdzShareAccount is Ownable {
    mapping (address => uint256) public amountOf; //通过transfer方法存进来的总数量
    address public lastMsgSender = address(0);

    function deposit() public payable {
        amountOf[msg.sender] += msg.value;
        lastMsgSender = msg.sender;
    }

    function transferTo(address _toAddress, uint256 _toAmount) onlyOwner public {
        require(_toAmount <= address(this).balance);
        _toAddress.transfer(_toAmount);
    }

    function () public payable {
        deposit();
    }
}