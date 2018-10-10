pragma solidity ^0.4.24;

contract TestSelfDestruct {
    address public owner;
    uint256 private num;

    constructor() public {
        owner = msg.sender;
        num = 100;
    }

    function transfer() public payable {}

    function kill(address _to) public {
        selfdestruct(_to);
    }

    function getNum() public view returns(uint256){
        return num;
    }
}