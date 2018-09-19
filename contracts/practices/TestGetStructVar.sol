pragma solidity ^0.4.24;

contract TestGetStructVar {
    struct TestStruct {
        uint256 a;
        string b;
        bool c;
    }

    TestStruct public testStruct;

    constructor() public {
        testStruct.a = 123;
        testStruct.b = 'test';
        testStruct.c = true;
    }
}