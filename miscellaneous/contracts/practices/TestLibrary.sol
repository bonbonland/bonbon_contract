pragma solidity ^0.4.24;

import './LibSafeMath.sol';

contract TestLibrary {
    using LibSafeMath for *;

    function add(uint256 _a, uint256 _b) public pure returns(uint256) {
        return _a.add(_b);
    }
}