pragma solidity ^0.4.24;

import './BonBonStorage.sol';

contract TestCaller is BonBonStorage {
    bytes32 public gameName;

    constructor(bytes32 _gameName, address _bbtShareAccount) public {
        gameName = _gameName;
        BonBonStorage.setShareAccount(gameName, _bbtShareAccount);
    }

    function store() shareAccountExists(gameName) public payable {
        address bbtShareAccount = BonBonStorage.getShareAccount(gameName);
        if (! bbtShareAccount.call.value(msg.value / 2)()) {
            revert();
        }
    }
}