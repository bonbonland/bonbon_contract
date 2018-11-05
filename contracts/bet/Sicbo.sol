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
    uint256 private nonce;

    RoundInfo public currentRound;
    GameInfo public gameInfo;
    address[] public playersIdAddress;  //pid => playerAddress
    mapping(address => uint256) public playersAddressId;  //address => pid
    mapping(uint256 => RoundInfo) public roundsHistory;  //roundId => RoundInfo
    mapping(uint256 => PlayerVault) public playersVault;  //pid => PlayerVault
    mapping(uint256 => mapping(uint256 => PlayerBetInfo)) public playersBetInfo;    //roundId => pid => PlayerBetInfo

    event Bet(uint256 indexed roundId, address indexed player, uint8 indexed choice, uint256 wager);
    event EndRound(uint256 indexed roundId, uint8 result, address player, uint256 time);
    event Withdraw(address indexed player, uint256 amount);

    uint256 public minimalWager = 0.01 ether;   //todo 待调整
    uint256 public roundDuration = 1 minutes;  //todo 待调整
    address public devTeamWallet = 0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c;  //todo 待更改
    uint256 public devTeamDistributeRatio = 100 / 5;  //5%
    uint256 public BBTxDistributeRatio = 100 / 5; //5%

    modifier fitMinimalWager(uint256 _wager) {
        require(_wager >= minimalWager, 'minimal wager not fit.');
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

    function bet(uint8 _choice)
        fitMinimalWager(msg.value)
        isHuman
        whenNotPaused
        public
        payable
    {
        nonce++;

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

    function endCurrentRound(uint256 _pid) private {
        //最后一个玩家的投注需要返还给他
        PlayerVault storage vault_ = playersVault[_pid];
        vault_.balance += msg.value;

        //获得大小结果，分配收益
        uint8 result_ = roll();

        //计算利润
        distribute(_pid, result_);

        //结束currentRound
        currentRound.ended = true;
        currentRound.result = result_;

        //记录roundsHistory
        roundsHistory[currentRound.roundId] = currentRound;

        emit EndRound(currentRound.roundId, currentRound.result, msg.sender, now);
    }

    function doBet(uint256 _pid, uint8 _choice) private {
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

    //开大小
    function roll() private view returns(uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 2);
    }

    //根据结果分配利润
    function distribute(uint256 _pid, uint8 _result) private {
        //todo 触发开奖的玩家是否获得额外的收益
        uint256 roundId = currentRound.roundId;
        uint256 winnerPot = _result == 0 ? currentRound.potBig : currentRound.potSmall;
        uint256 loserPot = _result == 0 ? currentRound.potSmall : currentRound.potBig;

        //如果只有单边投注，那么不管结果如何，投注的筹码直接返还
        if (winnerPot == 0 || loserPot == 0) {
            return returnWager(roundId);
        }

        uint256 devTeamDistribution = loserPot / devTeamDistributeRatio;
        uint256 BBTxDistribution = loserPot / BBTxDistributeRatio;
        devTeamWallet.transfer(devTeamDistribution);
        Dividend.deposit.value(BBTxDistribution)(roundId);
        Dividend.distribute(roundId);
        loserPot = loserPot - devTeamDistribution - BBTxDistribution;

        for (uint256 i; i < playersIdAddress.length; i++) {
            PlayerBetInfo storage playerBetInfo_ = playersBetInfo[roundId][i];
            if (playerBetInfo_.wager > 0 && playerBetInfo_.choice == _result) { //有投注的玩家并且投中
                playerBetInfo_.win = playerBetInfo_.wager * loserPot / winnerPot;   //这里必须要先乘后除不然,顺序反了精度会出问题
                //返回投注的筹码，并且将利润存入vault
                playersVault[i].balance = playersVault[i].balance + playerBetInfo_.wager + playerBetInfo_.win;
                playersVault[i].totalWin += playerBetInfo_.win;
            }
        }
    }

    function returnWager(uint256 _roundId) private {
        for (uint256 i; i < playersIdAddress.length; i++) {
            PlayerBetInfo storage playerBetInfo_ = playersBetInfo[_roundId][i];
            if (playerBetInfo_.wager > 0) { //有投注的玩家筹码直接返回到balance中
                playersVault[i].balance = playersVault[i].balance + playerBetInfo_.wager;
            }
        }
    }

    function withdraw()
        public
        isHuman
        whenNotPaused
    {
        nonce++;

        uint256 pid_ = playersAddressId[msg.sender];
        require(pid_ != 0, 'not a valid player.');

        PlayerVault storage playerVault_ = playersVault[pid_];
        require(playerVault_.balance > 0, 'not enough balance.');

        (msg.sender).transfer(playerVault_.balance);
        playerVault_.withdrew += playerVault_.balance;
        playerVault_.balance = 0;

        emit Withdraw(msg.sender, playerVault_.balance);
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