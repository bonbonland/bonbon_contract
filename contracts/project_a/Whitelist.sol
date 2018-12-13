pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

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
    function addAddressesToWhitelist(address[] _operators)
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
    function removeAddressesFromWhitelist(address[] _operators)
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

    function getAllWhitelist() public view returns(address[]) {
        address[] memory allWhitelist = new address[](whitelistAddresses.length);
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            allWhitelist[i] = whitelistAddresses[i];
        }
        return allWhitelist;
    }
}