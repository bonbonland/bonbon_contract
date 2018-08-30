pragma solidity ^0.4.24;

contract TestDeployed {
    bytes32 public foo = 'deployed_foo';
    mapping (address => uint256) public share;

    function setFoo(bytes32 _foo) public returns(bytes32) {
        foo = _foo;
        return foo;
    }

    function () public payable {
        share[msg.sender] += msg.value;

    }

    function send() public payable {
        share[msg.sender] += msg.value;
    }
}