pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

interface DividendInterface {
    function deposit(uint256 _round) external payable returns(bool);
    function distribute(uint256 _round) external returns(bool);
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
    }

    struct RoundPot {           //每一轮的奖池（扣除团队和bbt分红之后的玩家奖池）
        uint256 winnerPot;
        uint256 loserPot;
    }

    struct GameInfo {
        uint256 playerAmount;   //玩家总人数
        uint256 totalPotBig;
        uint256 totalPotSmall;
    }

    struct PlayerBetInfo {
        uint8 choice;
        uint256 wager;          //已下注筹码
    }

    struct PlayerInfo {
        uint256 returnWager;    //返还的筹码（触发开奖时返还）
        uint256 rebetWager;     //复投已消耗
        uint256 withdrew;       //已提现
        uint256[] roundIds;     //参与游戏的局数id
    }

    DividendInterface private Dividend;   // Dividend contract

    RoundInfo public currentRound;
    GameInfo public gameInfo;
    address[] public playersIdAddress;  //pid => playerAddress
    mapping(address => uint256) public playersAddressId;  //address => pid
    mapping(uint256 => RoundInfo) public roundsHistory;  //roundId => RoundInfo
    mapping(uint256 => RoundPot) public roundsPot;      //roundId => RoundPot
    mapping(uint256 => PlayerInfo) public playersInfo;  //pid => PlayerInfo
    mapping(uint256 => mapping(uint256 => PlayerBetInfo)) public playersBetInfo;    //roundId => pid => PlayerBetInfo
    mapping(uint256 => uint256[20]) public top20PlayerBig;  // roundId => index => pid
    mapping(uint256 => uint256[20]) public top20PlayerSmall;  // roundId => index => pid

    event Bet(uint256 indexed roundId, address indexed player, uint8 indexed choice, uint256 wager);
    event EndRound(uint256 indexed roundId, uint8 result, address player, uint256 time);
    event Withdraw(address indexed player, uint256 amount);

    uint256 public minimalWager = 0.01 ether;   //todo 待调整
    uint256 public roundDuration = 1 minutes;   //todo 待调整
    uint256 public BBTxDistributeRatio = 32;    //32 / 1000
    uint256 public agentDistributeRatio = 8;    //8 / 1000

    modifier fitMinimalWager(uint256 _wager) {
        require(_wager >= minimalWager, 'minimal wager not fit.');
        _;
    }

    modifier validPlayer(address _plyAddr) {
        uint256 pid_ = playersAddressId[_plyAddr];
        require(pid_ != 0, 'not a valid player.');
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    constructor(address _dividendContract) public {
        Dividend = DividendInterface(_dividendContract);

        //填充pid0，不然第一个玩家需要第二次determine才生效
        determinePid(address(0));
    }

    //bet with balance
    function bet(uint8 _choice, uint256 _wager)
        validPlayer(msg.sender)
        fitMinimalWager(_wager)
        isHuman
        whenNotPaused
        public
    {
        uint8 plyChoice_ = uint8(Choice(_choice));
        uint256 pid_ = playersAddressId[msg.sender];
        uint256 playerBalance_ = getPlayerTotalBalance(pid_);
        require(playerBalance_ >= _wager, 'not enough balance.');

        if (currentRound.roundId == 0 || currentRound.ended == true) {
            initNewRound();
        }

        if (currentRound.startTime + roundDuration < now) {
            endCurrentRound(pid_, _wager);
        } else {
            //bbt dividend
            uint256 BBTxDistribution = _wager * BBTxDistributeRatio / 1000;
            Dividend.deposit.value(BBTxDistribution)(currentRound.roundId);

            playersInfo[pid_].rebetWager += _wager;
            _wager -= BBTxDistribution;
            betAction(pid_, plyChoice_, _wager);
        }
    }

    //bet with eth
    function bet(uint8 _choice)
        fitMinimalWager(msg.value)
        isHuman
        whenNotPaused
        public
        payable
    {
        uint8 plyChoice_ = uint8(Choice(_choice));
        uint256 pid_ = determinePid(msg.sender);
        uint256 wager_ = msg.value;

        if (currentRound.roundId == 0 || currentRound.ended == true) {
            initNewRound();
        }

        if (currentRound.startTime + roundDuration < now) {
            endCurrentRound(pid_, wager_);
        } else {
            //bbt dividend
            uint256 BBTxDistribution = wager_ * BBTxDistributeRatio / 1000;
            Dividend.deposit.value(BBTxDistribution)(currentRound.roundId);

            wager_ -= BBTxDistribution;
            betAction(pid_, plyChoice_, wager_);
        }
    }

    function determinePid(address _addr) private returns(uint256) {
        uint256 pid_ = playersAddressId[_addr];
        if (pid_ == 0) {
            uint256 plyId = (playersIdAddress.push(_addr)).sub(1);
            playersAddressId[_addr] = plyId;
            gameInfo.playerAmount++;
            return plyId;
        }
        return pid_;
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
        playerInfo_.returnWager += _wager;

        //获得大小结果，分配收益
        uint8 result_ = roll();

        //计算利润
        distribute(result_);

        //结束currentRound
        currentRound.ended = true;
        currentRound.result = result_;

        //记录roundsHistory
        roundsHistory[currentRound.roundId] = currentRound;

        emit EndRound(currentRound.roundId, currentRound.result, msg.sender, now);
    }

    function betAction(uint256 _pid, uint8 _choice, uint256 _wager) private {
        uint256 roundId_ = currentRound.roundId;
        PlayerBetInfo storage playBetInfo_ = playersBetInfo[roundId_][_pid];

        if (playBetInfo_.wager > 0) {   //加注
            require(_choice == playBetInfo_.choice, 'can not change choice.');  //只能往已选择的方向加注

            playBetInfo_.wager = (playBetInfo_.wager).add(_wager);
            if (_choice == 0) { //投大
                currentRound.potBig = (currentRound.potBig).add(_wager);
                gameInfo.totalPotBig = (gameInfo.totalPotBig).add(_wager);
            } else {
                currentRound.potSmall = (currentRound.potSmall).add(_wager);
                gameInfo.totalPotSmall = (gameInfo.totalPotSmall).add(_wager);
            }
        } else {    //当前轮，初次投注
            playBetInfo_.choice = _choice;
            playBetInfo_.wager = (playBetInfo_.wager).add(_wager);
            playersInfo[_pid].roundIds.push(roundId_);
            if (_choice == 0) { //投大
                currentRound.plyCountBig++;
                currentRound.potBig = (currentRound.potBig).add(_wager);
                gameInfo.totalPotBig = (gameInfo.totalPotBig).add(_wager);
            } else {
                currentRound.plyCountSmall++;
                currentRound.potSmall = (currentRound.potSmall).add(_wager);
                gameInfo.totalPotSmall = (gameInfo.totalPotSmall).add(_wager);
            }
        }

        top20PlayerAction(_pid, _choice);
        emit Bet(roundId_, msg.sender, _choice, _wager);
    }

    function top20PlayerAction(uint256 _pid, uint8 _choice) private {
        uint256 roundId_ = currentRound.roundId;
        PlayerBetInfo storage playBetInfo_ = playersBetInfo[roundId_][_pid];
        uint256[20] storage top20Player_ = _choice == 0 ? top20PlayerBig[roundId_] : top20PlayerSmall[roundId_];

        (bool pidExistsInTop20_, uint256 pidIndex_) = getPidIndexInTop20(_choice, roundId_, _pid);

        if (pidExistsInTop20_) {
            sortTop20Player(top20Player_, roundId_, pidIndex_);
        } else {
            if (playersBetInfo[roundId_][top20Player_[19]].wager < playBetInfo_.wager) {
                top20Player_[19] = _pid;
                sortTop20Player(top20Player_, roundId_, 19);
            }
        }
    }

    function getPidIndexInTop20(uint256 _choice, uint256 _roundId, uint256 _pid) private view returns(bool, uint256) {
        uint256[20] storage top20Player_ = _choice == 0 ? top20PlayerBig[_roundId] : top20PlayerSmall[_roundId];

        //如果是加注的情况，查看用户id是否已经存在
        for (uint256 i; i < top20Player_.length; i++) {
            if (top20Player_[i] == _pid) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    function sortTop20Player(uint256[20] storage _top20Player, uint256 _roundId, uint256 _startIndex) private {
        for (uint256 i = _startIndex; i>= 1; i--) {   //compare two element
            if (playersBetInfo[_roundId][_top20Player[i-1]].wager >= playersBetInfo[_roundId][_top20Player[i]].wager)
                break;

            uint256 biggerPid = _top20Player[i];
            uint256 smallerPid = _top20Player[i-1];
            _top20Player[i-1] = biggerPid;
            _top20Player[i] = smallerPid;
        }
    }

    function getTop20Player(uint256 _choice, uint256 _roundId) public view returns(uint256[20]) {
        uint8 choice_ = uint8(Choice(_choice));
        uint256[20] memory top20Player_ = choice_ == 0 ? top20PlayerBig[_roundId] : top20PlayerSmall[_roundId];
        return top20Player_;
    }

    function getTop20PlayerWin(uint256 _roundId) public view returns(address[20], uint256[20]) {
        address[20] memory top20PlayerAddr_;
        uint256[20] memory top20PlayerWin_;
        RoundInfo storage roundInfo_ = roundsHistory[_roundId];

        if (roundInfo_.ended == true) {
            uint8 choice_ = roundInfo_.result;
            uint256[20] memory top20Player_ = getTop20Player(choice_, _roundId);

            for (uint256 i; i < top20Player_.length; i++) {
                uint256 pid_ = top20Player_[i];
                top20PlayerAddr_[i] = playersIdAddress[pid_];
                top20PlayerWin_[i] = getPlayerRoundWin(pid_, _roundId);
            }
        }

        return (top20PlayerAddr_, top20PlayerWin_);
    }

    //开大小
    function roll() private view returns(uint8) {
        bytes32 lastBlockHash = blockhash(block.number - 1);
        byte lastByte = lastBlockHash[lastBlockHash.length -1];
        uint8 lastNum = uint8(lastByte & byte(15));
        if (lastNum <= 7) {
            return 1;   //small
        } else {
            return 0;   //big
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
        PlayerBetInfo storage playerBetInfo_ = playersBetInfo[_roundId][_pid];
        if (playerBetInfo_.wager == 0)  //此轮未投注
            return 0;

        RoundInfo storage roundInfo_ = roundsHistory[_roundId];
        if (roundInfo_.ended == false)  //未开奖
            return 0;

        RoundPot storage roundPot_ = roundsPot[_roundId];
        if (roundPot_.winnerPot == 0 || roundPot_.loserPot == 0)    //只有单边投注时筹码返还
            return playerBetInfo_.wager;

        if (playerBetInfo_.choice != roundInfo_.result) //wrong choice
            return 0;

        return playerBetInfo_.wager + getPlayerRoundWin(_pid, _roundId);
    }

    //返回玩家某一轮的盈利
    function getPlayerRoundWin(uint256 _pid, uint256 _roundId) public view returns(uint256) {
        PlayerBetInfo storage playerBetInfo_ = playersBetInfo[_roundId][_pid];
        if (playerBetInfo_.wager == 0)
            return 0;

        RoundInfo storage roundInfo_ = roundsHistory[_roundId];
        if (roundInfo_.ended == false || playerBetInfo_.choice != roundInfo_.result)  //未开奖 or wrong choice
            return 0;

        RoundPot storage roundPot_ = roundsPot[_roundId];
        if (roundPot_.winnerPot == 0 || roundPot_.loserPot == 0)    //只有单边投注时筹码返还
            return 0;

        return playerBetInfo_.wager * roundPot_.loserPot / roundPot_.winnerPot;   //这里必须要先乘后除不然,顺序反了精度会出问题
    }

    function getPlayerRounds(uint256 _pid) public view returns(uint256[]) {
        return playersInfo[_pid].roundIds;
    }

    function withdraw()
        validPlayer(msg.sender)
        public
        isHuman
        whenNotPaused
    {
        uint256 pid_ = playersAddressId[msg.sender];
        uint256 playerBalance_ = getPlayerTotalBalance(pid_);
        require(playerBalance_ > 0, 'not enough balance.');

        (msg.sender).transfer(playerBalance_);
        playersInfo[pid_].withdrew += playerBalance_;

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

    function calculateProfit(address _plyAddr) public view returns(uint256) {
        if (currentRound.ended) //current round is end
            return 0;

        uint256 roundId = currentRound.roundId;
        uint256 pid_ = playersAddressId[_plyAddr];
        if (pid_ == 0)      //user not exists
            return 0;

        PlayerBetInfo storage playerBetInfo_ = playersBetInfo[roundId][pid_];
        if (playerBetInfo_.wager == 0)  //not betting on current round
            return 0;

        uint256 winnerPot = playerBetInfo_.choice == 0 ? currentRound.potBig : currentRound.potSmall;
        uint256 loserPot = playerBetInfo_.choice == 0 ? currentRound.potSmall : currentRound.potBig;

        if (winnerPot == 0 || loserPot == 0) {  //when all betting on one side, the wager will return, no winner.
            return 0;
        }

        uint256 BBTxDistribution = loserPot * BBTxDistributeRatio / 1000;
        loserPot -= BBTxDistribution;

        return playerBetInfo_.wager * loserPot / winnerPot;
    }
}