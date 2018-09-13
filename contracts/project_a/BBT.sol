pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol';
import 'openzeppelin-solidity/contracts/access/Whitelist.sol';

contract BBT is BurnableToken, PausableToken, Whitelist {
    string public constant symbol = "BBT";
    string public constant name = "BonBon Token";
    uint8 public constant decimals = 18;
    uint256 private overrideTotalSupply_ = 100 * 1e8 * 1e18;   //100亿

    uint256 public circulation;   //流通量
    address public teamWallet;    //团队持有bbt钱包
    uint256 public constant teamReservedRatio_ = 10;    //团队比例(百分之x)

    event Mine(address indexed from, address indexed to, uint256 amount);
    event Release(address indexed from, address indexed to, uint256 amount);
    event SetTeamWallet(address indexed from, address indexed teamWallet);
    event UnlockTeamBBT(address indexed teamWallet, uint256 amount, string source);

    modifier hasEnoughUnreleasedBBT(uint256 _amount) {
        require(circulation.add(_amount) <= totalSupply_);
        _;
    }

    modifier hasTeamWallet() {
        require(teamWallet != address(0));  //团队账号必须是已设置
        _;
    }

    //必须要在constructor里面改totalSupply_的值，直接通过覆盖base合约的totalSupply_的形式来赋值无效
    //因为totalSupply_是继承下来的，除非将totalSupply方法在此合约里面重写一次，
    //不然base合约的totalSupply方法获取的是父合约的totalSupply_变量，在此合约覆盖totalSupply_的值在base合约的方法是获取不到的
    constructor() public {
        totalSupply_ = overrideTotalSupply_;
    }

    //设置团队bbt钱包地址
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

    //游戏挖矿赚取bbt
    function mine(address _to, uint256 _amount)
        onlyIfWhitelisted(msg.sender)
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns (bool)
    {
        releaseBBT(_to, _amount);

        //解锁团队bbt
        unlockTeamBBT(getTeamUnlockAmountHelper(_amount), 'mine');

        emit Mine(msg.sender, _to, _amount);
        return true;
    }

    //释放token
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

    //释放token并且等比例解锁团队token
    function releaseAndUnlock(address _to, uint256 _amount)
        onlyOwner
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns(bool)
    {
        release(_to, _amount);

        //解锁团队bbt
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

    //给mine或release的账户添加余额，同时更改流通量的值
    function releaseBBT(address _to, uint256 _amount)
        hasEnoughUnreleasedBBT(_amount)
        private
        returns(bool)
    {
        balances[_to] = balances[_to].add(_amount);
        circulation = circulation.add(_amount);
    }
}