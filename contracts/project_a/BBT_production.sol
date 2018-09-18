pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol';
import 'openzeppelin-solidity/contracts/access/Whitelist.sol';

contract BBT is BurnableToken, PausableToken, Whitelist {
    string public constant symbol = "BBT";
    string public constant name = "BonBon Token";
    uint8 public constant decimals = 18;
    uint256 private overrideTotalSupply_ = 10 * 1e9 * 1e18; //10 billion

    uint256 public circulation;
    address public teamWallet;
    uint256 public constant teamReservedRatio_ = 10;

    event Mine(address indexed from, address indexed to, uint256 amount);
    event Release(address indexed from, address indexed to, uint256 amount);
    event SetTeamWallet(address indexed from, address indexed teamWallet);
    event UnlockTeamBBT(address indexed teamWallet, uint256 amount, string source);

    /**
     * @dev make sure unreleased BBT is enough.
     */
    modifier hasEnoughUnreleasedBBT(uint256 _amount) {
        require(circulation.add(_amount) <= totalSupply_, "Unreleased BBT not enough.");
        _;
    }

    /**
     * @dev make sure dev team wallet is set.
     */
    modifier hasTeamWallet() {
        require(teamWallet != address(0), "Team wallet not set.");
        _;
    }

    constructor() public {
        totalSupply_ = overrideTotalSupply_;
    }

    /**
     * @dev setup team wallet.
     * @param _address address of team wallet.
     */
    function setTeamWallet(address _address)
        onlyOwner
        whenNotPaused
        public
        returns (bool)
    {
        teamWallet = _address;
        emit SetTeamWallet(msg.sender, _address);
        return true;
    }

    /**
     * @dev for authorized dapp mining BBT.
     * @param _to to which address BBT send to.
     * @param _amount how many BBT send.
     */
    function mine(address _to, uint256 _amount)
        onlyIfWhitelisted(msg.sender)
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns (bool)
    {
        releaseBBT(_to, _amount);

        //unlock dev team bbt
        unlockTeamBBT(getTeamUnlockAmountHelper(_amount), 'mine');

        emit Mine(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev owner release BBT to specified address.
     * @param _to which address release to.
     * @param _amount how many BBT release to.
     */
    function release(address _to, uint256 _amount)
        onlyOwner
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns(bool)
    {
        releaseBBT(_to, _amount);
        emit Release(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev owner release BBT and unlock corresponding ratio to dev team wallet.
     * @param _to which address release to.
     * @param _amount how many BBT release to.
     */
    function releaseAndUnlock(address _to, uint256 _amount)
        onlyOwner
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns(bool)
    {
        release(_to, _amount);

        //unlock dev team bbt
        unlockTeamBBT(getTeamUnlockAmountHelper(_amount), 'release');

        return true;
    }

    function getTeamUnlockAmountHelper(uint256 _amount)
        private
        pure
        returns(uint256)
    {
        return _amount.mul(teamReservedRatio_).div(100 - teamReservedRatio_);
    }

    function unlockTeamBBT(uint256 _unlockAmount, string _source)
        hasTeamWallet
        hasEnoughUnreleasedBBT(_unlockAmount)
        private
        returns(bool)
    {
        releaseBBT(teamWallet, _unlockAmount);
        emit UnlockTeamBBT(teamWallet, _unlockAmount, _source);
        return true;
    }

    /**
     * @dev update balance and circulation.
     */
    function releaseBBT(address _to, uint256 _amount)
        hasEnoughUnreleasedBBT(_amount)
        private
        returns(bool)
    {
        balances[_to] = balances[_to].add(_amount);
        circulation = circulation.add(_amount);
    }
}