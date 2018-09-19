pragma solidity ^0.4.24;

contract TestMappingStruct {
    struct TestStruct {
        uint256 a;
        string b;
        bool c;
    }

    mapping (uint256 => TestStruct) public testMappingStruct;

    constructor() public {
        testMappingStruct[0].a = 1;
        testMappingStruct[0].b = '1';
        testMappingStruct[0].c = true;
        testMappingStruct[1].a = 2;
        testMappingStruct[1].b = '2';
        testMappingStruct[1].c = true;
        testMappingStruct[2].a = 3;
        testMappingStruct[2].b = '3';
        testMappingStruct[2].c = true;
    }
}