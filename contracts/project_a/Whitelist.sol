pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Whitelist is Ownable {
    mapping (address => bool) public whitelist;

    event AddWhitelist(address indexed operator);
    event RemoveWhitelist(address indexed operator);

    /**
    * @dev Throws if operator is not whitelisted.
    * @param _operator address
    */
    modifier onlyIfWhitelisted(address _operator) {
        require(whitelist[_operator] == true, "not whitelisted.");
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
        if (whitelist[_operator] == false) {
            whitelist[_operator] = true;
            emit AddWhitelist(_operator);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param _operators addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
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
        if (whitelist[_operator] == true) {
            whitelist[_operator] = false;
            emit RemoveWhitelist(_operator);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param _operators addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
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
        return whitelist[_operator];
    }
}