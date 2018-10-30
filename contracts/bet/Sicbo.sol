pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

interface DividendInterface {
    function deposit(uint256 _round) external payable returns(bool);
    function distribute(uint256 _round) external returns(bool);
}

contract Sicbo is Ownable {
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

    struct GameInfo {
        uint256 playerAmount;   //玩家总人数
        uint256 totalPotBig;
        uint256 totalPotSmall;
    }

    struct PlayerBetInfo {
        uint8 choice;
        uint256 wager;          //已下注筹码
        uint256 win;            //盈利
    }

    struct PlayerVault {
        uint256 balance;    //余额
        uint256 totalWin;   //总盈利
        uint256 withdrew;   //已提现
    }

    DividendInterface private Dividend;   // Dividend contract

    RoundInfo public currentRound;
    GameInfo public gameInfo;
    address[] public playersIdAddress;  //pid => playerAddress
    mapping(address => uint256) public playersAddressId;  //address => pid
    mapping(uint256 => RoundInfo) public roundsHistory;  //roundId => RoundInfo
    mapping(uint256 => PlayerVault) public playersVault;  //pid => PlayerVault
    mapping(uint256 => mapping(uint256 => PlayerBetInfo)) public playersBetInfo;    //roundId => pid => PlayerBetInfo

    event Bet(uint256 indexed _roundId, address indexed _player, uint8 indexed _choice, uint256 wager);
    event Withdraw(address indexed _player, uint256 _amount);

    uint256 public minimalWager = 0.01 ether;   //todo 待调整
    uint256 public roundDuration = 1 minutes;  //todo 待调整
    address public devTeamWallet = 0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c;  //todo
    uint256 public devTeamDistributeRatio = 5;  //5%
    uint256 public BBTxDistributeRatio = 5; //5%

    modifier fitMinimalWager(uint256 _wager) {
        require(_wager >= minimalWager, 'minimal wager not fit.');
        _;
    }

    constructor(address _dividendContract) public {
        Dividend = DividendInterface(_dividendContract);

        //填充pid0，不然第一个玩家需要第二次determine才生效
        determinePid(address(0));
    }

    function initNewRound() internal {
        RoundInfo memory roundInfo_;
        roundInfo_.roundId = (currentRound.roundId).add(1);
        roundInfo_.startTime = now;

        currentRound = roundInfo_;
    }

    function endCurrentRound(uint256 _pid) internal {
        //todo 最后一个玩家的投注需要返还给他
        PlayerVault storage vault_ = playersVault[_pid];
        vault_.balance = msg.value;

        //todo 获得大小结果，分配收益
        uint8 result_ = roll();

        //todo 分发利润
        distribute(_pid, result_);

        //更改currentRound的状态
        currentRound.ended = true;
        currentRound.result = result_;

        //roundsHistory
        roundsHistory[currentRound.roundId] = currentRound;
    }

    function determinePid(address _addr) internal returns(uint256) {
        uint256 pid_ = playersAddressId[_addr];
        if (pid_ == 0) {
            uint256 plyId = (playersIdAddress.push(_addr)).sub(1);
            playersAddressId[_addr] = plyId;
            gameInfo.playerAmount++;
            return plyId;
        }
        return pid_;
    }

    //todo 玩家下注
    function bet(uint8 _choice)
    fitMinimalWager(msg.value)
    public
    payable
    {
        uint8 plyChoice_ = uint8(Choice(_choice));
        uint256 pid_ = determinePid(msg.sender);

        if (currentRound.roundId == 0 || currentRound.ended == true) {
            initNewRound();
        }

        if (currentRound.startTime + roundDuration < now) {
            endCurrentRound(pid_);
        } else {
            doBet(pid_, plyChoice_);
        }
    }

    function doBet(uint256 _pid, uint8 _choice) internal {
        uint256 roundId = currentRound.roundId;
        PlayerBetInfo storage playBetInfo_ = playersBetInfo[roundId][_pid];

        if (playBetInfo_.wager > 0) {   //加注
            require(_choice == playBetInfo_.choice, 'can not change choice.');  //只能往已选择的方向加注

            playBetInfo_.wager = (playBetInfo_.wager).add(msg.value);
            if (_choice == 0) { //投大
                currentRound.potBig = (currentRound.potBig).add(msg.value);
                gameInfo.totalPotBig = (gameInfo.totalPotBig).add(msg.value);
            } else {
                currentRound.potSmall = (currentRound.potSmall).add(msg.value);
                gameInfo.totalPotSmall = (gameInfo.totalPotSmall).add(msg.value);
            }
        } else {    //当前轮，初次投注
            playBetInfo_.choice = _choice;
            playBetInfo_.wager = (playBetInfo_.wager).add(msg.value);
            if (_choice == 0) { //投大
                currentRound.plyCountBig++;
                currentRound.potBig = (currentRound.potBig).add(msg.value);
                gameInfo.totalPotBig = (gameInfo.totalPotBig).add(msg.value);
            } else {
                currentRound.plyCountSmall++;
                currentRound.potSmall = (currentRound.potSmall).add(msg.value);
                gameInfo.totalPotSmall = (gameInfo.totalPotSmall).add(msg.value);
            }
        }

        emit Bet(roundId, msg.sender, _choice, msg.value);
    }

    //todo 开大小
    function roll() internal pure returns(uint8) {
        return uint8(1);
    }

    //todo 根据结果分配利润
    function distribute(uint256 _pid, uint8 _result) internal {
        //todo 触发开奖的玩家是否获得额外的收益
        uint256 roundId = currentRound.roundId;
        uint256 winnerPot;
        uint256 loserPot;
        if (_result == 0) {
            winnerPot = currentRound.potBig;
            loserPot = currentRound.potSmall;
        } else {
            winnerPot = currentRound.potSmall;
            loserPot = currentRound.potBig;
        }

        //todo if winnerpot or loserpot == 0 返回返回抽not distribute
        uint256 devTeamDistribution = loserPot * devTeamDistributeRatio / 100;
        uint256 BBTxDistribution = loserPot * BBTxDistributeRatio / 100;
        devTeamWallet.transfer(devTeamDistribution);
        Dividend.deposit.value(BBTxDistribution)(roundId);
        Dividend.distribute(roundId);
        loserPot = loserPot - devTeamDistribution - BBTxDistribution;

        for (uint256 i; i < playersIdAddress.length; i++) {
            PlayerBetInfo memory playerBetInfo_ = playersBetInfo[roundId][i];
            if (playerBetInfo_.wager > 0) { //有投注的玩家
                if (playerBetInfo_.choice == _result) { //投中了
                    playerBetInfo_.win = playerBetInfo_.wager / winnerPot * loserPot;
                    //返回投注的筹码，并且将利润存入vault
                    playersVault[i].balance = playersVault[i].balance + playerBetInfo_.wager + playerBetInfo_.win;
                    playersVault[i].totalWin = playersVault[i].totalWin + playerBetInfo_.win;
                }
            }
        }
    }

    function withdraw() public {
        uint256 pid_ = playersAddressId[msg.sender];
        require(pid_ != 0, 'not a valid player.');

        PlayerVault storage playerVault_ = playersVault[pid_];
        require(playerVault_.balance > 0, 'not enough balance.');

        playerVault_.balance = 0;
        playerVault_.withdrew += playerVault_.balance;
        (msg.sender).transfer(playerVault_.balance);

        emit Withdraw(msg.sender, playerVault_.balance);
    }
}