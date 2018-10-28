pragma solidity ^0.4.24;

contract TestArray {
    //address[3] public addresses;
    address[] public addresses;

    constructor() public {
        //可变长的array，不能通过index赋值（因为length为0）
        //addresses[0] = 0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c;
        addresses.push(0xF83c5c0be4c0803ECA56a4CBf02b07F6E6BbDa9c);
        addresses.push(0xA08d4485E50d28E60A41cb015203fDB3D1dE6C8C);
        //addresses[2] = 0x018649744e6e2a52fA8551749e5db938EfF11567;
    }

    //array的length不能通过web3获取，需要通过getter获取
    function getAddressesCount() view public returns(uint256) {
        return addresses.length;
    }
}