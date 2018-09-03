pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract BonBonStorage is Ownable {
    mapping (bytes32 => address) public shareAccountAddress; //分红账号合约(或普通账号)地址

    modifier shareAccountExists(bytes32 _gameName) {
        require(shareAccountAddress[_gameName] != address(0));
        _;
    }

    function setShareAccount(bytes32 _gameName, address _accountAddress)
        onlyOwner
        public
    {
        shareAccountAddress[_gameName] = _accountAddress;
    }

    function getShareAccount(bytes32 _gameName)
        shareAccountExists(_gameName)
        public
        view
        returns(address)
    {
        return shareAccountAddress[_gameName];
    }

    function transferTo(address _toAddress, uint256 _toAmount) onlyOwner public {
        require(_toAmount <= address(this).balance);
        _toAddress.transfer(_toAmount);
    }

    function () public payable {
        //
    }
}