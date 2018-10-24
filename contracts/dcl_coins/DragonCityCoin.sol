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

    modifier lessThanTotalSupply(uint256[] _amount) {
        uint256 totalAmount = 0;
        for (uint256 i; i < _amount.length; i++) {
            totalAmount = totalAmount.add(_amount[i]);
        }
        require(totalAmount.add(coinsInVaults) <= totalSupply_, 'can not exceed total supply.');
        _;
    }

    constructor() public {
        totalSupply_ = INI_SUPPLY_;
    }

    /**
    * @dev user acquire initial coins to his balance.
    */
    function acquire() whenNotPaused public {
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
    function setVault(address[] _to, uint256[] _amount)
        onlyOwner
        lessThanTotalSupply(_amount)
        whenNotPaused
        public
    {
        require(_to.length == _amount.length, 'address count and amount count do not match.');

        for (uint256 i; i < _to.length; i++) {
            address to = _to[i];
            uint256 amount = _amount[i];
            require(amount > 0, 'amount should great than 0.');

            VaultInfo storage vaultInfo = vaults[to];
            vaultInfo.amount = (vaultInfo.amount).add(amount);
            vaultInfo.acquiredTime = 0;
            coinsInVaults = coinsInVaults.add(amount);
        }
    }
}