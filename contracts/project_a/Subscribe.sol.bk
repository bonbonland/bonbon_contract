pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {

        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    /**
       * @dev gives square root of given x.
       */
    function sqrt(uint256 x)
    internal
    pure
    returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
    internal
    pure
    returns (uint256)
    {
        return (mul(x,x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
    internal
    pure
    returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                // require character is a space
                    _temp[i] == 0x20 ||
                // OR lowercase a-z
                (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                // or 0-9
                (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

library DataSet{
    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 donation;
        uint256 refNum;
        uint256 currentRef;
        uint256 currentDonateTime;
        uint256 level;
        uint256 force;
        uint256 earn;
        uint256 withdrawed;
    }

    struct Round {
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 start;   // time round started
        uint256 totalForce;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        // uint256 mask;   // global mask
    }

    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 ref;
        uint256 force;   // keys
    }
}

contract BBT {
    function checkRole(address _operator, string _role) public view;
    function mine(address _to, uint256 _amount) public returns (bool);
}

contract Subscribe is Pausable{
    using SafeMath for *;
    using NameFilter for string;

    // user id related info
    mapping (address => uint256) public pIDxAddr_;
    mapping (bytes32 => uint256) public pIDxName_;
    mapping (uint256 => DataSet.Player) public plyr_;
    // user name related
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;
    mapping (uint256 => mapping (uint256 => bool)) public refShip_;
    mapping (bytes32 => bool) private nameMap_;
    // configs
    BBT private BBTInterface = BBT(0xf628099229Fae56F0fFBe7140A41d3820a1248F1);
    uint256[] public donations = [11,21,40,100,200,500,1000,0];
    uint256[] public refTimes = [2,4,8,16,32,32,32,1000];
    uint256[] public donateTimes = [1,2,4,8,16,16,16,0];
    // global info
    uint256 public maxPID = 0;
    uint256 public totalForce_;
    bool public activated_;
    uint256 public roundID = 0;
    mapping (uint256 => DataSet.Round) public roundInfo_;
    mapping (uint256 => mapping (uint256 => DataSet.PlayerRounds)) public playerRoundInfo_;

    //events
    event Activated(address indexed who);
    event Donated(address indexed who, uint256 indexed pID, uint256 indexed value);
    event Withdraw(address indexed who, uint256 indexed pID, uint256 indexed amount);
    event Distribute(address indexed who,uint256 indexed roundid);

    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    constructor() public {
        roundInfo_[roundID].start = now;
        roundInfo_[roundID].ended = false;
    }

    function donateAmount(uint256 _pID,uint256 _ndonate)public view returns(uint256){
        require(_ndonate>0);
        uint256 _ndonateLimit;
        if(_ndonate>donateTimes(_pID)){
            _ndonateLimit = donateTimes(_pID);
        }else{
            _ndonateLimit = _ndonate;
        }
        // require(_ndonate<=donateTimes(_pID));
        if(_pID == 0){
            return donations[0].mul(_ndonateLimit);
        }
        uint256 donateLimit = donations[plyr_[_pID].level].mul(_ndonateLimit);
        return donateLimit;
    }

    function donateTimes(uint256 _pID)public view returns(uint256){
        if(_pID == 0){
            return donateTimes[0];
        }
        uint256 timesLimit = donateTimes[plyr_[_pID].level].sub(plyr_[_pID].currentDonateTime);
        return timesLimit;
    }

    function refTimes(uint256 _pID)public view returns(uint256){
        if(_pID == 0){
            return refTimes[0];
        }
        uint256 timesLimit = refTimes[plyr_[_pID].level].sub(plyr_[_pID].currentRef);
        return timesLimit;
    }

    function determinePIdAName(address useraddr, string nameStr) private{
        uint256 _pID = pIDxAddr_[useraddr];
        bytes32 _name = nameStr.nameFilter();

        require(_pID !=0 || (_name != "" && !nameMap_[_name]));
        // require(nameMap_[_name] == false );
        // if player is new here
        if(_pID == 0 && (_name != "" && !nameMap_[_name])){
            // grab their player ID, name and last aff ID, from player names contract
            _pID = maxPID.add(1);
            // set up player account and global info
            pIDxAddr_[msg.sender] = _pID;
            pIDxName_[_name] = _pID;
            plyrNames_[_pID][_name] = true;
            nameMap_[_name] = true;
            // update _pID information
            plyr_[_pID].addr = msg.sender;
            plyr_[_pID].name = _name;
            // update max id
            maxPID = _pID;
        }
    }

    function activate() public onlyOwner(){
        // can only be ran once
        require(activated_ == false, "Already activated");
        // activate the contract
        activated_ = true;
        emit Activated(msg.sender);
    }

    function forceofLevel(uint256 level) public view returns(uint256) {
        uint256 donateMax = 0;
        for(uint256 lev=0; lev<=level; lev++){
            donateMax = donateMax + donations[lev].mul(donateTimes[lev]);
        }
        uint256 ref = 0;
        for(uint256 lev2=0; lev2<=level;lev2++){
            ref = ref + donateTimes[lev2];
        }
        return calculateForce(donateMax, ref);
    }

    function calculateForce(uint256 donate, uint256 ref) public pure returns(uint256) {
        return (donate.mul(donate)).add((donate.mul(20)).mul(ref)).sub(120);
    }

    function updateForce(uint256 userId) private{
        // previous force of user
        uint256 preForce = plyr_[userId].force;
        // updated force
        plyr_[userId].force = calculateForce(plyr_[userId].donation,plyr_[userId].refNum);
        // update total force
        uint256 incForce = plyr_[userId].force.sub(preForce);
        // update total force
        totalForce_ = totalForce_.add(incForce);
        // update round force info
        roundInfo_[roundID].totalForce = roundInfo_[roundID].totalForce.add(incForce);
        // update user round force info
        playerRoundInfo_[userId][roundID].force = playerRoundInfo_[userId][roundID].force.add(incForce);
        // check whether user can upgrade
        upgrade(userId);
        // mine some bbt to userId
        BBTInterface.mine(plyr_[userId].addr,incForce);
    }

    function upgrade(uint256 userId) private{
        uint256 force = plyr_[userId].force;
        uint256 level = plyr_[userId].level;
        if(force>=forceofLevel(level)){
            plyr_[userId].currentRef = 0;
            plyr_[userId].currentDonateTime = 0;
            plyr_[userId].level = plyr_[userId].level.add(1);
        }
    }

    function donateXid(uint256 _refID, string _nameStr,uint256 _ndonate) public payable isActivated() isHuman(){
        uint256 _pIDold = pIDxAddr_[msg.sender];
        determinePIdAName(msg.sender,_nameStr);
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID != 0);
        // check amount of eth
        require(msg.value == donateAmount(_pID,_ndonate) && _ndonate<=donateTimes(_pID));
        // require the referral id should not be yourself, not 0 and is a vaild user
        if(!(_refID == _pID || plyr_[_refID].addr == 0 || _refID == 0)){
            if(refShip_[_refID][_pID] == false && _pIDold == 0){
                // update _refID
                refShip_[_refID][_pID] = true;
                // update ref info only if you can referral
                if(refTimes(_refID)>0){
                    plyr_[_refID].refNum = plyr_[_refID].refNum.add(1);
                    plyr_[_refID].currentRef = plyr_[_refID].currentRef.add(1);
                    playerRoundInfo_[_refID][roundID].ref = playerRoundInfo_[_refID][roundID].ref.add(1);
                    updateForce(_refID);
                    updateEarning(_refID);
                }
            }
        }
        // require(_refID != _pID && plyr_[_refID].addr!= 0 && _refID != 0);
        // when msg.sender is new to this game and didnot ref msg.sender before
        // update _pID
        plyr_[_pID].donation = plyr_[_pID].donation.add(msg.value);
        plyr_[_pID].currentDonateTime = plyr_[_pID].currentDonateTime.add(_ndonate);
        updateForce(_pID);
        // update round info
        roundInfo_[roundID].eth = roundInfo_[roundID].eth.add(msg.value);
        roundInfo_[roundID].pot = roundInfo_[roundID].pot.add(msg.value);
        // update user round info
        playerRoundInfo_[_pID][roundID].eth = playerRoundInfo_[_pID][roundID].eth.add(msg.value);
        // update earning info
        updateEarning(_pID);

        emit Donated(msg.sender,_pID,msg.value);

    }

    function donateXname(string _refName, string _nameStr,uint256 _ndonate) public payable isActivated() isHuman(){
        bytes32 _name = _refName.nameFilter();
        uint256 _refID = pIDxName_[_name];
        donateXid(_refID,_nameStr,_ndonate);
    }

    function donateXAddress(address _addr, string _nameStr,uint256 _ndonate) public payable isActivated() isHuman(){
        uint256 _refID = pIDxAddr_[_addr];
        donateXid(_refID,_nameStr,_ndonate);
    }

    function reload(uint256 _ndonate) public isActivated() isHuman(){
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID != 0 && _ndonate>0);
        updateEarning(_pID);
        // check amount of unwithdrawed eth
        uint256 dAmount = donateAmount(_pID,_ndonate);
        require(plyr_[_pID].earn.sub(plyr_[_pID].withdrawed) >= dAmount);
        // update _pID
        plyr_[_pID].withdrawed = plyr_[_pID].withdrawed.add(dAmount);
        plyr_[_pID].donation = plyr_[_pID].donation.add(dAmount);
        plyr_[_pID].currentDonateTime = plyr_[_pID].currentDonateTime.add(_ndonate);
        updateForce(_pID);
        // update round info
        roundInfo_[roundID].eth = roundInfo_[roundID].eth.add(dAmount);
        roundInfo_[roundID].pot = roundInfo_[roundID].pot.add(dAmount);
        // update user round info
        playerRoundInfo_[_pID][roundID].eth = playerRoundInfo_[_pID][roundID].eth.add(dAmount);
        // update earning info
        updateEarning(_pID);

        emit Donated(msg.sender,_pID,dAmount);
    }

    function withdraw() public isActivated() isHuman(){
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID != 0);
        updateEarning(_pID);
        uint256 rest = plyr_[_pID].earn.sub(plyr_[_pID].withdrawed);
        require(rest >= 1 finney);
        plyr_[_pID].withdrawed = plyr_[_pID].withdrawed.add(rest);
        msg.sender.transfer(rest);
        emit Withdraw(msg.sender,_pID,rest);
    }

    function distribute() public isActivated() onlyOwner(){
        roundInfo_[roundID].end = now;
        roundInfo_[roundID].ended = true;
        roundID = roundID.add(1);
        roundInfo_[roundID].start = now;
        roundInfo_[roundID].ended = false;
        emit Distribute(msg.sender,roundID.sub(1));
    }

    function updateEarning(uint256 userId) public isActivated(){
        require(plyr_[userId].addr != 0);
        uint256 totalEarn = 0;
        for(uint256 rid=0; rid<roundID; rid++){
            totalEarn = totalEarn + (playerRoundInfo_[userId][rid].force.div(roundInfo_[rid].totalForce)).mul(roundInfo_[rid].pot);
        }
        plyr_[userId].earn = totalEarn;
    }

    function estimateEarning(uint256 userId) public view isActivated() returns(uint256){
        require(plyr_[userId].addr != 0);
        uint256 totalEarn = 0;
        for(uint256 rid=0; rid<=roundID; rid++){
            totalEarn = totalEarn + (playerRoundInfo_[userId][rid].force.div(roundInfo_[rid].totalForce)).mul(roundInfo_[rid].pot);
        }
        return totalEarn;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

}
