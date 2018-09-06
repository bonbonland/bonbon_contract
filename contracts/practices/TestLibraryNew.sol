pragma solidity ^0.4.24;

import './LibSafeMath.sol';

contract TestLibraryNew {
    LibSafeMath.result safeMathResult;

    function add(uint256 _a, uint256 _b) public returns(uint256) {
        LibSafeMath.add2Result(safeMathResult, _a, _b);
        return safeMathResult.result;
    }
}