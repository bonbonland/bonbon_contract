pragma solidity ^0.4.24;

import './BonBonStorage.sol';

contract TestCallerNew {
    bytes32 public gameName;
    BonBonStorage private bonbonStorage;

    constructor(bytes32 _gameName, address _storageAddress) public {
        gameName = _gameName;
        bonbonStorage = BonBonStorage(_storageAddress);
    }

    function getShareAccount() private view returns(address) {
        address shareAccount = bonbonStorage.getShareAccount(gameName);
        require(shareAccount != address(0));
        return shareAccount;
    }

    function store() public payable {
        address shareAccount = getShareAccount();
//        if (! shareAccount.call.value(msg.value / 2)()) {
        if (! shareAccount.call.value(msg.value / 2)(bytes4(keccak256("unExists()")))) {
            revert();
        }
    }
}