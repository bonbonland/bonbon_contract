pragma solidity ^0.4.24;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


interface DividendInterface {
    function deposit(uint256 _round) external payable returns(bool);
    function distribute(uint256 _round) external returns(bool);
}

interface PlayerAffiliateInterface {
    function getOrCreatePlayerId(address _plyAddr) external returns(uint256);
    function getPlayerId(address _gameAddr, address _plyAddr) external view returns(uint256);
    function getPlayerAddrById(address _gameAddr, uint256 _pid) external view returns(address);
    function registerAffiliate(address _plyAddr, address _affAddr) external;
    function hasAffiliate(address _plyAddr) external view returns(bool);
    function getPlayerAmount(address _gameAddr) external view returns(uint256);
    function playerAffiliate_(address _plyAddr) external view returns(address);
    function getOrRegisterAffiliate(address _plyAddr, address _affAddr) external returns(address);
    function depositShare(address _plyAddr) external payable returns(bool);
}

interface BBTxInterface {
    function mine(address _to, uint256 _amount) external returns(bool);
}

contract Sicbo is Pausable {
    using SafeMath for *;

    enum Choice { Big, Small }  //0 => big, 1 => small

    struct RoundInfo {
        uint256 roundId;
        uint256 startTime;
        bool ended;
        uint256 plyCountBig;
        uint256 plyCountSmall;
        uint8 result;
        uint256 potBig;
        uint256 potSmall;
        uint256 blockId;
    }

    struct RoundPot {           
        uint256 winnerPot;
        uint256 loserPot;
    }

    struct GameInfo {
        uint256 totalPotBig;
        uint256 totalPotSmall;
    }

    struct PlayerBetInfo {
        uint8 choice;
        uint256 wager;
        uint256 betTime;
    }

    struct PlayerInfo {
        uint256 returnWager;
        uint256 rebetWager;
        uint256 withdrew;
        uint256[] roundIds;
    }

    DividendInterface private Dividend;   // Dividend contract
    PlayerAffiliateInterface private PlayerAffiliate;   //PlayerAffiliate contract
    BBTxInterface private BBT;  //BBT contract

    RoundInfo public currentRound;
    GameInfo public gameInfo;
    mapping(uint256 => RoundInfo) public roundsHistory;  //roundId => RoundInfo
    mapping(uint256 => RoundPot) public roundsPot;      //roundId => RoundPot
    mapping(uint256 => PlayerInfo) public playersInfo;  //pid => PlayerInfo
    mapping(uint256 => mapping(uint256 => PlayerBetInfo[])) public playersBetInfo;    //roundId => pid => PlayerBetInfo
    mapping(uint256 => uint256[20]) public top20PlayerBig;  // roundId => index => pid
    mapping(uint256 => uint256[20]) public top20PlayerSmall;  // roundId => index => pid

    event Bet(uint256 indexed roundId, address indexed player, uint8 indexed choice, uint256 wager);
    event EndRound(uint256 indexed roundId, uint8 result, address player, uint256 time, uint256 blockId);
    event Withdraw(address indexed player, uint256 amount);

    uint256 public minimalWager = 0.005 ether;
    uint256 public roundDuration = 5 minutes;
    uint256 public BBTxDistributeRatio = 42;    //42 / 1000
    uint256 public affiliateDistributeRatio = 8;    //8 / 1000
    uint256 public mineBBTxRatio = 100;    // 1 eth => 100bbt
    address public constant devTeamWallet = 0x3235B0de284428Ceaf80244aaC77825507416370;   //development team wallet address

    modifier fitMinimalWager(uint256 _wager) {
        require(_wager >= minimalWager, 'minimal wager not fit.');
        _;
    }

    modifier validPlayer(address _plyAddr) {
        uint256 pid_ = getPlayerId(_plyAddr);
        require(pid_ != 0, 'not a valid player.');
        _;
    }

    modifier isHuman(address _addr) {
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    constructor(address _dividendContract, address _playerAffiliateContract, address _bbtContract) public {
        Dividend = DividendInterface(_dividendContract);
        PlayerAffiliate = PlayerAffiliateInterface(_playerAffiliateContract);
        BBT = BBTxInterface(_bbtContract);
    }

    function getPlayerId(address _plyAddr) public view returns(uint256) {
        return PlayerAffiliate.getPlayerId(address(this), _plyAddr);
    }

    function getPlayerAddrById(uint256 _plyId) public view returns(address) {
        return PlayerAffiliate.getPlayerAddrById(address(this), _plyId);
    }

    function getPlayerAmount() public view returns(uint256) {
        return PlayerAffiliate.getPlayerAmount(address(this));
    }

    //bet with balance
    function bet(uint8 _choice, uint256 _wager, address _affiliate)
        validPlayer(msg.sender)
        fitMinimalWager(_wager)
        isHuman(msg.sender)
        isHuman(_affiliate)
        whenNotPaused
        public
    {
        require(msg.sender != _affiliate);

        if (_affiliate == address(0)) {
            _affiliate = devTeamWallet;
        }

        uint256 pid_ = getPlayerId(msg.sender);
        require(getPlayerTotalBalance(pid_) >= _wager, 'not enough balance.');

        address plyAff_ = PlayerAffiliate.getOrRegisterAffiliate(msg.sender, _affiliate);

        if (currentRound.roundId == 0 || currentRound.ended == true) {
            initNewRound();
        }

        if (currentRound.startTime + roundDuration < now && currentRound.ended == false) {
            endCurrentRound(pid_, _wager);
        } else {
            //bbt dividend
            uint256 BBTxDistribution = _wager * BBTxDistributeRatio / 1000;
            Dividend.deposit.value(BBTxDistribution)(currentRound.roundId);

            //affiliate dividend
            uint256 affiliateDistribution = _wager * affiliateDistributeRatio / 1000;
            PlayerAffiliate.depositShare.value(affiliateDistribution)(plyAff_);

            //mine bbt
            mineBBT(msg.sender, _wager * mineBBTxRatio);

            playersInfo[pid_].rebetWager += _wager;
            _wager = _wager - BBTxDistribution - affiliateDistribution;
            betAction(pid_, uint8(Choice(_choice)), _wager);
        }
    }

    //bet with eth
    function bet(uint8 _choice, address _affiliate)
        fitMinimalWager(msg.value)
        isHuman(msg.sender)
        isHuman(_affiliate)
        whenNotPaused
        public
        payable
    {
        require(msg.sender != _affiliate);

        if (_affiliate == address(0)) {
            _affiliate = devTeamWallet;
        }

        uint256 pid_ = PlayerAffiliate.getOrCreatePlayerId(msg.sender);
        uint256 wager_ = msg.value;
        address plyAff_ = PlayerAffiliate.getOrRegisterAffiliate(msg.sender, _affiliate);

        if (currentRound.roundId == 0 || currentRound.ended == true) {
            initNewRound();
        }

        if (currentRound.startTime + roundDuration < now && currentRound.ended == false) {
            endCurrentRound(pid_, wager_);
        } else {
            //bbt dividend
            uint256 BBTxDistribution = wager_ * BBTxDistributeRatio / 1000;
            Dividend.deposit.value(BBTxDistribution)(currentRound.roundId);

            //affiliate dividend
            uint256 affiliateDistribution = wager_ * affiliateDistributeRatio / 1000;
            PlayerAffiliate.depositShare.value(affiliateDistribution)(plyAff_);

            //mine bbt
            mineBBT(msg.sender, wager_ * mineBBTxRatio);

            wager_ = wager_ - BBTxDistribution - affiliateDistribution;
            betAction(pid_, uint8(Choice(_choice)), wager_);
        }
    }

    function mineBBT(address _to, uint256 _amount) private returns(bool) {
        return BBT.mine(_to, _amount);
    }

    function initNewRound() private {
        RoundInfo memory roundInfo_;
        roundInfo_.roundId = (currentRound.roundId).add(1);
        roundInfo_.startTime = now;

        currentRound = roundInfo_;
    }

    function endCurrentRound(uint256 _pid, uint256 _wager) private {
        PlayerInfo storage playerInfo_ = playersInfo[_pid];
        if (_wager > 0)
            playerInfo_.returnWager += _wager;

        uint8 result_ = roll();

        distribute(result_);

        currentRound.ended = true;
        currentRound.result = result_;
        currentRound.blockId = block.number;

        roundsHistory[currentRound.roundId] = currentRound;

        emit EndRound(currentRound.roundId, currentRound.result, msg.sender, now, block.number);
    }

    function betAction(uint256 _pid, uint8 _choice, uint256 _wager) private {
        uint256 roundId_ = currentRound.roundId;
        PlayerBetInfo[] storage playBetInfo_ = playersBetInfo[roundId_][_pid];
        uint256[] storage playerRounds_ = playersInfo[_pid].roundIds;

        if (playBetInfo_.length == 0)
            playerRounds_.push(roundId_);

        playBetInfo_.push(PlayerBetInfo(_choice, _wager, now));

        if (_choice == 0) {
            currentRound.plyCountBig++;
            currentRound.potBig = (currentRound.potBig).add(_wager);
            gameInfo.totalPotBig = (gameInfo.totalPotBig).add(_wager);
        } else {
            currentRound.plyCountSmall++;
            currentRound.potSmall = (currentRound.potSmall).add(_wager);
            gameInfo.totalPotSmall = (gameInfo.totalPotSmall).add(_wager);
        }

        top20PlayerAction(_pid, _choice);
        emit Bet(roundId_, msg.sender, _choice, _wager);
    }

    function top20PlayerAction(uint256 _pid, uint8 _choice) private {
        uint256 roundId_ = currentRound.roundId;
        uint256[20] storage top20Player_ = _choice == 0 ? top20PlayerBig[roundId_] : top20PlayerSmall[roundId_];

        (bool pidExistsInTop20_, uint256 pidIndex_) = getPidIndexInTop20(_choice, roundId_, _pid);

        if (pidExistsInTop20_) {
            sortTop20Player(top20Player_, roundId_, pidIndex_, _choice);
        } else {
            if (getPlayerRoundWager(roundId_, top20Player_[19], _choice) < getPlayerRoundWager(roundId_, _pid, _choice)) {
                top20Player_[19] = _pid;
                sortTop20Player(top20Player_, roundId_, 19, _choice);
            }
        }
    }

    function getPidIndexInTop20(uint8 _choice, uint256 _roundId, uint256 _pid) private view returns(bool, uint256) {
        uint256[20] storage top20Player_ = _choice == 0 ? top20PlayerBig[_roundId] : top20PlayerSmall[_roundId];

        for (uint256 i; i < top20Player_.length; i++) {
            if (top20Player_[i] == _pid) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    function sortTop20Player(uint256[20] storage _top20Player, uint256 _roundId, uint256 _startIndex, uint8 _choice) private {
        for (uint256 i = _startIndex; i>= 1; i--) {   //compare two element
            if (getPlayerRoundWager(_roundId, _top20Player[i-1], _choice) >= getPlayerRoundWager(_roundId, _top20Player[i], _choice))
                break;

            uint256 biggerPid = _top20Player[i];
            uint256 smallerPid = _top20Player[i-1];
            _top20Player[i-1] = biggerPid;
            _top20Player[i] = smallerPid;
        }
    }

    function getTop20Player(uint256 _choice, uint256 _roundId) public view returns(uint256[20] memory) {
        uint8 choice_ = uint8(Choice(_choice));
        uint256[20] memory top20Player_ = choice_ == 0 ? top20PlayerBig[_roundId] : top20PlayerSmall[_roundId];
        return top20Player_;
    }

    function getTop20PlayerWin(uint256 _roundId) public view returns(address[20] memory, uint256[20] memory) {
        address[20] memory top20PlayerAddr_;
        uint256[20] memory top20PlayerWin_;
        RoundInfo storage roundInfo_ = roundsHistory[_roundId];

        if (roundInfo_.ended == true) {
            uint8 choice_ = roundInfo_.result;
            uint256[20] memory top20Player_ = getTop20Player(choice_, _roundId);

            for (uint256 i; i < top20Player_.length; i++) {
                uint256 pid_ = top20Player_[i];
                top20PlayerAddr_[i] = getPlayerAddrById(pid_);
                top20PlayerWin_[i] = getPlayerRoundWin(pid_, _roundId);
            }
        }

        return (top20PlayerAddr_, top20PlayerWin_);
    }

    function getPlayerRoundWager(uint256 _roundId, uint256 _pid, uint8 _choice) public view returns(uint256) {
        PlayerBetInfo[] storage playerBetInfo_ = playersBetInfo[_roundId][_pid];

        uint256 playerBetWager_ = 0;
        for (uint256 i = 0; i < playerBetInfo_.length; i++) {
            if (playerBetInfo_[i].choice == _choice) {
                playerBetWager_ += playerBetInfo_[i].wager;
            }
        }

        return playerBetWager_;
    }

    function getPlayerRoundBets(uint256 _roundId, uint256 _pid)
        public
        view
        returns(uint8[] memory, uint256[] memory, uint256[] memory)
    {
        PlayerBetInfo[] storage playerBetInfo_ = playersBetInfo[_roundId][_pid];

        uint8[] memory playerBetChoices_ = new uint8[](playerBetInfo_.length);
        uint256[] memory playerBetWagers_ = new uint256[](playerBetInfo_.length);
        uint256[] memory playerBetTime_ = new uint256[](playerBetInfo_.length);
        for (uint256 i = 0; i < playerBetInfo_.length; i++) {
            playerBetChoices_[i] = playerBetInfo_[i].choice;
            playerBetWagers_[i] = playerBetInfo_[i].wager;
            playerBetTime_[i] = playerBetInfo_[i].betTime;
        }

        return (playerBetChoices_, playerBetWagers_, playerBetTime_);
    }

    function roll() private view returns(uint8) {
        if (uint8(block.timestamp % 10) >= 5) {
            return uint8(0);
        } else {
            return uint8(1);
        }
    }

    function distribute(uint8 _result) private {
        uint256 roundId_ = currentRound.roundId;
        uint256 winnerPot_ = _result == 0 ? currentRound.potBig : currentRound.potSmall;
        uint256 loserPot_ = _result == 0 ? currentRound.potSmall : currentRound.potBig;

        Dividend.distribute(roundId_);

        roundsPot[roundId_] = RoundPot(winnerPot_, loserPot_);
    }

    //（returnWager + allRoundsBalance - withdrew）
    function getPlayerTotalBalance(uint256 _pid) public view returns(uint256) {
        PlayerInfo storage playerInfo_ = playersInfo[_pid];
        uint256[] memory playerRounds_ = getPlayerRounds(_pid);
        uint256 playerRoundsBalance_ = 0;
        for (uint256 i; i < playerRounds_.length; i++) {
            playerRoundsBalance_ += getPlayerRoundBalance(_pid, playerRounds_[i]);
        }
        return playerRoundsBalance_ + playerInfo_.returnWager - playerInfo_.withdrew - playerInfo_.rebetWager;
    }

    //（roundWager + roundWin）
    function getPlayerRoundBalance(uint256 _pid, uint256 _roundId) public view returns(uint256) {
        uint256 playerWagerBig_ = getPlayerRoundWager(_roundId, _pid, 0);
        uint256 playerWagerSmall_ = getPlayerRoundWager(_roundId, _pid, 1);

        if (playerWagerBig_ == 0 && playerWagerSmall_ == 0)
            return 0;

        RoundInfo storage roundInfo_ = roundsHistory[_roundId];
        if (roundInfo_.ended == false)
            return 0;

        RoundPot storage roundPot_ = roundsPot[_roundId];
        if (roundPot_.winnerPot == 0 || roundPot_.loserPot == 0)
            return playerWagerBig_ > 0 ? playerWagerBig_ : playerWagerSmall_;

        return getPlayerRoundWager(_roundId, _pid, roundInfo_.result) + getPlayerRoundWin(_pid, _roundId);
    }

    function getPlayerRoundWin(uint256 _pid, uint256 _roundId) public view returns(uint256) {
        PlayerBetInfo[] storage playerBetInfo_ = playersBetInfo[_roundId][_pid];
        if (playerBetInfo_.length == 0)
            return 0;

        RoundInfo storage roundInfo_ = roundsHistory[_roundId];
        if (roundInfo_.ended == false)
            return 0;

        RoundPot storage roundPot_ = roundsPot[_roundId];
        if (roundPot_.winnerPot == 0 || roundPot_.loserPot == 0)
            return 0;

        return getPlayerRoundWager(_roundId, _pid, roundInfo_.result) * roundPot_.loserPot / roundPot_.winnerPot;
    }

    function getPlayerRounds(uint256 _pid) public view returns(uint256[] memory) {
        return playersInfo[_pid].roundIds;
    }

    function withdraw()
        validPlayer(msg.sender)
        public
        isHuman(msg.sender)
        whenNotPaused
    {
        uint256 pid_ = getPlayerId(msg.sender);
        uint256 playerBalance_ = getPlayerTotalBalance(pid_);
        require(playerBalance_ > 0, 'not enough balance.');

        (msg.sender).transfer(playerBalance_);
        playersInfo[pid_].withdrew += playerBalance_;

        //check if need to end round
        if (currentRound.startTime + roundDuration < now && currentRound.ended == false) {
            endCurrentRound(pid_, 0);
        }

        emit Withdraw(msg.sender, playerBalance_);
    }

    function getTimeLeft() public view returns(uint256) {
        if (currentRound.startTime == 0 || now - currentRound.startTime > roundDuration) {
            return 0;
        } else if (currentRound.startTime == now) {
            return roundDuration;
        } else {
            return now - currentRound.startTime;
        }
    }
}
