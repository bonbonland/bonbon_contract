pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

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

    struct RoundPot {           //每一轮的奖池（扣除团队和bbt分红之后的玩家奖池）
        uint256 winnerPot;
        uint256 loserPot;
    }

    struct GameInfo {
        uint256 totalPotBig;
        uint256 totalPotSmall;
    }

    struct PlayerBetInfo {
        uint8 choice;
        uint256 wager;          //已下注筹码
        uint256 betTime;        //下注时间
    }

    struct PlayerInfo {
        uint256 returnWager;    //返还的筹码（触发开奖时返还）
        uint256 rebetWager;     //复投已消耗
        uint256 withdrew;       //已提现
        uint256[] roundIds;     //参与游戏的局数id
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

    uint256 public minimalWager = 0.005 ether;   //todo 待调整
    uint256 public roundDuration = 1 minutes;   //todo 待调整
    uint256 public BBTxDistributeRatio = 42;    //42 / 1000
    uint256 public affiliateDistributeRatio = 8;    //8 / 1000
    uint256 public mineBBTxRatio = 100;    // 1 eth => 10bbt   //todo 待调整
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

//        address payable plyAff_ = address(uint160(bytes20(PlayerAffiliate.getOrRegisterAffiliate(msg.sender, _affiliate))));
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
        //最后一个玩家的投注需要返还给他
        PlayerInfo storage playerInfo_ = playersInfo[_pid];
        if (_wager > 0)
            playerInfo_.returnWager += _wager;

        //获得大小结果，分配收益
        uint8 result_ = roll();

        //计算利润
        distribute(result_);

        //结束currentRound
        currentRound.ended = true;
        currentRound.result = result_;
        currentRound.blockId = block.number;

        //记录roundsHistory
        roundsHistory[currentRound.roundId] = currentRound;

        emit EndRound(currentRound.roundId, currentRound.result, msg.sender, now, block.number);
    }

    function betAction(uint256 _pid, uint8 _choice, uint256 _wager) private {
        uint256 roundId_ = currentRound.roundId;
        PlayerBetInfo[] storage playBetInfo_ = playersBetInfo[roundId_][_pid];
        uint256[] storage playerRounds_ = playersInfo[_pid].roundIds;

        if (playBetInfo_.length == 0)   //初次投注
            playerRounds_.push(roundId_);

        playBetInfo_.push(PlayerBetInfo(_choice, _wager, now)); //投注

        if (_choice == 0) { //投大
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

        //如果是加注的情况，查看用户id是否已经存在
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

    //开大小
    function roll() private view returns(uint8) {
//        bytes32 lastBlockHash = blockhash(block.number - 1);
//        bytes1 lastByte = lastBlockHash[lastBlockHash.length -1];
//        uint8 lastNum = uint8(lastByte & bytes1(0x0f));
//        if (lastNum <= 7) {
//            return 1;   //small
//        } else {
//            return 0;   //big
//        }
        if (uint8(block.timestamp % 10) >= 5) {
            return uint8(0);
        } else {
            return uint8(1);
        }
    }

    //根据结果分配利润(记录奖池资金)
    function distribute(uint8 _result) private {
        //todo 触发开奖的玩家是否获得额外的收益
        uint256 roundId_ = currentRound.roundId;
        uint256 winnerPot_ = _result == 0 ? currentRound.potBig : currentRound.potSmall;
        uint256 loserPot_ = _result == 0 ? currentRound.potSmall : currentRound.potBig;

        Dividend.distribute(roundId_);

        roundsPot[roundId_] = RoundPot(winnerPot_, loserPot_);
    }

    //玩家总balance（returnWager + allRoundsBalance - withdrew）
    function getPlayerTotalBalance(uint256 _pid) public view returns(uint256) {
        PlayerInfo storage playerInfo_ = playersInfo[_pid];
        uint256[] memory playerRounds_ = getPlayerRounds(_pid);
        uint256 playerRoundsBalance_ = 0;
        for (uint256 i; i < playerRounds_.length; i++) {
            playerRoundsBalance_ += getPlayerRoundBalance(_pid, playerRounds_[i]);
        }
        return playerRoundsBalance_ + playerInfo_.returnWager - playerInfo_.withdrew - playerInfo_.rebetWager;
    }

    //返回玩家某局游戏的balance（roundWager + roundWin）
    function getPlayerRoundBalance(uint256 _pid, uint256 _roundId) public view returns(uint256) {
        uint256 playerWagerBig_ = getPlayerRoundWager(_roundId, _pid, 0);
        uint256 playerWagerSmall_ = getPlayerRoundWager(_roundId, _pid, 1);

        if (playerWagerBig_ == 0 && playerWagerSmall_ == 0)  //此轮未投注
            return 0;

        RoundInfo storage roundInfo_ = roundsHistory[_roundId];
        if (roundInfo_.ended == false)  //未开奖
            return 0;

        RoundPot storage roundPot_ = roundsPot[_roundId];
        if (roundPot_.winnerPot == 0 || roundPot_.loserPot == 0)    //只有单边投注时筹码返还
            return playerWagerBig_ > 0 ? playerWagerBig_ : playerWagerSmall_;

        return getPlayerRoundWager(_roundId, _pid, roundInfo_.result) + getPlayerRoundWin(_pid, _roundId);
    }

    //返回玩家某一轮的盈利
    function getPlayerRoundWin(uint256 _pid, uint256 _roundId) public view returns(uint256) {
        PlayerBetInfo[] storage playerBetInfo_ = playersBetInfo[_roundId][_pid];
        if (playerBetInfo_.length == 0)     //此玩家未投注
            return 0;

        RoundInfo storage roundInfo_ = roundsHistory[_roundId];
        if (roundInfo_.ended == false)  //未开奖 or wrong choice
            return 0;

        RoundPot storage roundPot_ = roundsPot[_roundId];
        if (roundPot_.winnerPot == 0 || roundPot_.loserPot == 0)    //只有单边投注时筹码返还
            return 0;

        //这里必须要先乘后除不然,顺序反了精度会出问题
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