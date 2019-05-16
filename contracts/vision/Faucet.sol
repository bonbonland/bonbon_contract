pragma solidity ^0.5.4;

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

contract Whitelist is Ownable {
    struct WhitelistInfo {
        bool inWhitelist;
        uint256 index;  //index in whitelistAddress
        uint256 time;   //timestamp when added to whitelist
    }

    mapping (address => WhitelistInfo) public whitelist;
    address[] public whitelistAddresses;

    event AddWhitelist(address indexed operator, uint256 indexInWhitelist);
    event RemoveWhitelist(address indexed operator, uint256 indexInWhitelist);

    /**
    * @dev Throws if operator is not whitelisted.
    * @param _operator address
    */
    modifier onlyIfWhitelisted(address _operator) {
        require(inWhitelist(_operator) == true, "not whitelisted.");
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param _operator address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address _operator)
        public
        onlyOwner
        returns(bool)
    {
        WhitelistInfo storage whitelistInfo_ = whitelist[_operator];

        if (inWhitelist(_operator) == false) {
            whitelistAddresses.push(_operator);

            whitelistInfo_.inWhitelist = true;
            whitelistInfo_.time = block.timestamp;
            whitelistInfo_.index = whitelistAddresses.length-1;

            emit AddWhitelist(_operator, whitelistAddresses.length-1);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param _operators addresses
     */
    function addAddressesToWhitelist(address[] memory _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    /**
    * @dev remove an address from the whitelist
    * @param _operator address
    * @return true if the address was removed from the whitelist,
    * false if the address wasn't in the whitelist in the first place
    */
    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner
        returns(bool)
    {
        if (inWhitelist(_operator) == true) {
            uint256 whitelistIndex_ = whitelist[_operator].index;
            removeItemFromWhitelistAddresses(whitelistIndex_);
            whitelist[_operator] = WhitelistInfo(false, 0, 0);

            emit RemoveWhitelist(_operator, whitelistIndex_);
            return true;
        } else {
            return false;
        }
    }

    function removeItemFromWhitelistAddresses(uint256 _index) private {
        address lastWhitelistAddr = whitelistAddresses[whitelistAddresses.length-1];
        WhitelistInfo storage lastWhitelistInfo = whitelist[lastWhitelistAddr];

        //move last whitelist to the deleted slot
        whitelistAddresses[_index] = whitelistAddresses[whitelistAddresses.length-1];
        lastWhitelistInfo.index = _index;
        delete whitelistAddresses[whitelistAddresses.length-1];
        whitelistAddresses.length--;
    }

    /**
     * @dev remove addresses from the whitelist
     * @param _operators addresses
     */
    function removeAddressesFromWhitelist(address[] memory _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

    /**
    * @dev check if the given address already in whitelist.
    * @return return true if in whitelist.
    */
    function inWhitelist(address _operator)
        public
        view
        returns(bool)
    {
        return whitelist[_operator].inWhitelist;
    }

    function getWhitelistCount() public view returns(uint256) {
        return whitelistAddresses.length;
    }

    function getAllWhitelist() public view returns(address[] memory) {
        address[] memory allWhitelist = new address[](whitelistAddresses.length);
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            allWhitelist[i] = whitelistAddresses[i];
        }
        return allWhitelist;
    }
}

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

contract Faucet is Whitelist, Pausable {
    using SafeMath for uint256;

    struct FaucetConf {
        uint256 interval;   //interval between faucet
        uint256 amount;     //token amount each faucet
    }

    struct FaucetRecord {
        uint256 amount;
        uint256 lastTime;
    }

    address[] private faucetToken_;
    uint256 public faucetTokenAmount;
    FaucetConf public ethFaucetConf = FaucetConf(24 hours, 1 ether);
    mapping(address => FaucetConf) public erc20FaucetConf;  //tokenContract => conf
    mapping(address => FaucetRecord) public userLatestEthFaucetRecord;  //wallet address => FaucetRecord
    mapping(address => mapping(address => FaucetRecord)) public userLatestErc20FaucetRecord;    //tokenContract => (wallet_address => FaucetRecord)

    event FaucetErc20Event(address indexed _to, uint256 _value, uint256 _time);
    event FaucetEthEvent(address indexed _to, uint256 _value, uint256 _time);

    modifier isNotFaucetToken(address _contract) {
        for (uint256 i = 0; i < faucetToken_.length; i++) {
            require(_contract != faucetToken_[i]);
        }
        _;
    }

    modifier isFaucetToken(address _contract) {
        bool inList = false;
        for (uint256 i = 0; i < faucetToken_.length; i++) {
            if (_contract == faucetToken_[i]) {
                inList = true;
                break;
            }
        }
        require(inList == true, "this token in not in faucet list.");
        _;
    }

    constructor() public {
        addAddressToWhitelist(msg.sender);
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getFaucetTokenList()
        public
        view
        //token contract address, token symbol, token name, token decimal, interval, amount
        returns(address[] memory, bytes32[]memory, bytes32[] memory, uint8[] memory, uint256[] memory, uint256[] memory)
    {
        address[] memory tokenAddresses_ = new address[](faucetTokenAmount);
        bytes32[] memory tokenSymbols_ = new bytes32[](faucetTokenAmount);
        bytes32[] memory tokenNames_ = new bytes32[](faucetTokenAmount);
        uint8[] memory tokenDecimals_ = new uint8[](faucetTokenAmount);
        uint256[] memory tokenFaucetIntervals_ = new uint256[](faucetTokenAmount);
        uint256[] memory tokenFaucetAmounts_ = new uint256[](faucetTokenAmount);
        uint256 index_ = 0;
        for (uint256 i = 0; i < faucetToken_.length; i++) {
            if (faucetToken_[i] != address(0)) {
                Erc20Interface tokenContractInterface_ = Erc20Interface(faucetToken_[i]);
                tokenAddresses_[index_] = faucetToken_[i];
                tokenSymbols_[index_] = stringToBytes32(tokenContractInterface_.symbol());
                tokenNames_[index_] = stringToBytes32(tokenContractInterface_.name());
                tokenDecimals_[index_] = tokenContractInterface_.decimals();
                tokenFaucetIntervals_[index_] = erc20FaucetConf[faucetToken_[i]].interval;
                tokenFaucetAmounts_[index_] = erc20FaucetConf[faucetToken_[i]].amount;
                index_++;
            }
        }
        return (tokenAddresses_, tokenSymbols_, tokenNames_, tokenDecimals_, tokenFaucetIntervals_, tokenFaucetAmounts_);
    }

    function getFaucetTokenIndex(address _tokenContract)
        private
        view
        returns(uint256)
    {
        for (uint256 i = 0; i < faucetToken_.length; i++) {
            if (_tokenContract == faucetToken_[i]) {
                return i;
            }
        }
        revert("not a valid faucet token contract.");
    }

    /**
     * @dev add token for faucet.
     */
    function addFaucetToken(address _tokenContract, uint256 _interval, uint256 _amount)
        onlyOwner
        isNotFaucetToken(_tokenContract)
        public
    {
        for (uint256 i = 0; i < faucetToken_.length; i++) {
            if (faucetToken_[i] == address(0)) {
                faucetToken_[i] = _tokenContract;
                erc20FaucetConf[_tokenContract] = FaucetConf(_interval, _amount);
                faucetTokenAmount++;
                return;
            }
        }
        faucetToken_.push(_tokenContract);
        erc20FaucetConf[_tokenContract] = FaucetConf(_interval, _amount);
        faucetTokenAmount++;
    }

    /**
    * @dev remove token for faucet.
    */
    function removeFaucetToken(address _tokenContract)
        onlyOwner
        public
    {
        uint256 tokenIndex = getFaucetTokenIndex(_tokenContract);
        faucetToken_[tokenIndex] = address(0);
        erc20FaucetConf[_tokenContract] = FaucetConf(0, 0);
        faucetTokenAmount--;
    }

    function editFaucetTokenConf(address _tokenContract, uint256 _interval, uint256 _amount)
        onlyOwner
        isFaucetToken(_tokenContract)
        public
    {
        erc20FaucetConf[_tokenContract] = FaucetConf(_interval, _amount);
    }

    function editEthFaucetConf(uint256 _interval, uint256 _amount)
        onlyOwner
        public
    {
        ethFaucetConf = FaucetConf(_interval, _amount);
    }

    function faucetErc20(address _tokenContract)
        isFaucetToken(_tokenContract)
        whenNotPaused
        public
    {
        FaucetRecord storage userLatestErc20FaucetRecord_ = userLatestErc20FaucetRecord[_tokenContract][msg.sender];
        FaucetConf storage faucetTokenConf_ = erc20FaucetConf[_tokenContract];
        Erc20Interface ecr20Token_ = Erc20Interface(_tokenContract);

        if (userLatestErc20FaucetRecord_.lastTime == 0) {
            ecr20Token_.transfer(msg.sender, faucetTokenConf_.amount);
            userLatestErc20FaucetRecord[_tokenContract][msg.sender] = FaucetRecord(faucetTokenConf_.amount, block.timestamp);
            emit FaucetErc20Event(msg.sender, faucetTokenConf_.amount, block.timestamp);
        } else if ((block.timestamp).sub(userLatestErc20FaucetRecord_.lastTime) > faucetTokenConf_.interval) {
            ecr20Token_.transfer(msg.sender, faucetTokenConf_.amount);
            userLatestErc20FaucetRecord[_tokenContract][msg.sender] = FaucetRecord(faucetTokenConf_.amount, block.timestamp);
            emit FaucetErc20Event(msg.sender, faucetTokenConf_.amount, block.timestamp);
        } else {
            revert("please wait more time for the next faucet.");
        }
    }

    function faucetEth(address _to)
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
    {
        FaucetRecord storage userLastEthFaucetRecord_ = userLatestEthFaucetRecord[_to];
        address payable _to= address(uint160(bytes20(_to)));

        if (userLastEthFaucetRecord_.lastTime == 0) {
            _to.transfer(ethFaucetConf.amount);
            userLatestEthFaucetRecord[_to] = FaucetRecord(ethFaucetConf.amount, block.timestamp);
            emit FaucetEthEvent(_to, ethFaucetConf.amount, block.timestamp);
        } else if ((block.timestamp).sub(userLastEthFaucetRecord_.lastTime) > ethFaucetConf.interval) {
            _to.transfer(ethFaucetConf.amount);
            userLatestEthFaucetRecord[_to] = FaucetRecord(ethFaucetConf.amount, block.timestamp);
            emit FaucetEthEvent(_to, ethFaucetConf.amount, block.timestamp);
        } else {
            revert("please wait more time for the next faucet.");
        }
    }

    function() external payable {}
}

interface Erc20Interface {
    function transfer(address _to, uint256 _value) external returns(bool);
    function symbol() external view returns(string memory);
    function name() external view returns(string memory);
    function decimals() external view returns(uint8);
}
