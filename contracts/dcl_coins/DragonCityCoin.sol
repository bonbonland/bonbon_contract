pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol';

contract DragonCityCoin is PausableToken {
    using SafeMath for uint256;

    struct VaultInfo {
        uint256 amount;     //initial assigned coins amount
        uint256 acquiredTime;   //acquired to balance timestamp
    }

    string public constant symbol = "Coin1";    //todo change coin symbol
    string public constant name = "Coin one";   //todo change coin name
    uint8 public constant decimals = 0;
    uint256 private INI_SUPPLY_ = 600 * 1000; //todo change coin supply(land count * 1000)
    mapping (address => VaultInfo) public vaults;  //save user initial assigned coins
    uint256 public coinsInVaults;    //initial assigned total coins(can not great than totalSupply_)

    event Acquired(address indexed to, uint256 amount);

    constructor() public {
        totalSupply_ = INI_SUPPLY_;
    }

    /**
    * @dev user acquire initial coins to his balance.
    */
    function acquire() public {
        uint256 coinAmount = vaults[msg.sender].amount;
        require(coinAmount > 0, 'no coins to acquire.');

        balances[msg.sender] = balances[msg.sender].add(coinAmount);
        vaults[msg.sender].amount = 0;
        vaults[msg.sender].acquiredTime = block.timestamp;

        emit Acquired(msg.sender, coinAmount);
    }

    /**
    * @dev initialize coins to land holder.
    */
    function setVault(address _to, uint256 _amount) public onlyOwner {
        require(coinsInVaults.add(_amount) <= totalSupply_, 'initial assigned coins can not exceed total supply.');

        VaultInfo memory vaultInfo;
        vaultInfo.amount = _amount;
        vaultInfo.acquiredTime = 0;

        vaults[_to] = vaultInfo;
        coinsInVaults = coinsInVaults.add(_amount);
    }
}