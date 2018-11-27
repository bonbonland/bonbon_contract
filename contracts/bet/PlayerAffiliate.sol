pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract PlayerAffiliate is Ownable {
    uint256 public gameCount_;
    mapping (uint256 => uint256) public playerCount_;  //gameId => playerCount
    mapping (address => address) public playerAffiliate_;   //player => player's affiliate
    mapping (uint256 => mapping(uint256 => address)) public players_;   //gameId => playerId => playerAddr
    mapping (uint256 => mapping(address => uint256)) public playerIds_;    //gameId => playerAddr => playerId;
    mapping (uint256 => address) public games_;    //gameId => gameAddress
    mapping (address => uint256) public gameIds_;  //gameAddress => gameId

    event RegisteredGame(address _addr, uint256 _gameId);
    event RegisteredAffiliate(uint256 indexed _gameId, address _plyAddr, address _affAddr);

    modifier isRegisteredGame(address _addr) {
        require(gameIds_[_addr] != 0, 'not a registered game.');
        _;
    }

    modifier isNotRegisteredGame(address _addr) {
        require(gameIds_[_addr] == 0, 'can not be a registered game.');
        _;
    }

    function determinePID(uint256 _gameId, address _addr)
        private
        returns(bool)
    {
        if (playerIds_[_gameId][_addr] == 0) {
            uint256 newPlayerId = playerCount_[_gameId] + 1;
            playerCount_[_gameId]++;
            players_[_gameId][newPlayerId] = _addr;
            playerIds_[_gameId][_addr] = newPlayerId;
            return true;
        } else {
            return false;
        }
    }

    function getOrCreatePlayerId(address _plyAddr)
        isRegisteredGame(msg.sender)
        public
        returns(uint256)
    {
        uint256 gameId = gameIds_[msg.sender];
        determinePID(gameId, _plyAddr);
        return playerIds_[gameId][_plyAddr];
    }

    function getPlayerId(address _gameAddr, address _plyAddr)
        isRegisteredGame(_gameAddr)
        public
        view
        returns(uint256)
    {
        uint256 gameId = gameIds_[_gameAddr];
        return playerIds_[gameId][_plyAddr];
    }

    function getPlayerAddrById(address _gameAddr, uint256 _pid)
        isRegisteredGame(_gameAddr)
        public
        view
        returns(address)
    {
        uint256 gameId = gameIds_[_gameAddr];
        return players_[gameId][_pid];
    }

    function registerGame(address _addr)
        onlyOwner
        isNotRegisteredGame(_addr)
        public
    {
        gameCount_++;
        games_[gameCount_] = _addr;
        gameIds_[_addr] = gameCount_;

        emit RegisteredGame(_addr, gameCount_);
    }

    function unRegisterGame(address _addr)
        onlyOwner
        isRegisteredGame(_addr)
        public
    {
        uint256 gameId = gameIds_[_addr];
        games_[gameId] = address(0);
        gameIds_[_addr] = 0;
    }

    function registerAffiliate(address _plyAddr, address _affAddr)
        isRegisteredGame(msg.sender)
        public
    {
        require(_plyAddr != _affAddr);
        require(playerAffiliate_[_plyAddr] == address(0), 'already registered affiliate.');

        uint256 gameId = gameIds_[msg.sender];
        determinePID(gameId, _plyAddr);
        determinePID(gameId, _affAddr);

        playerAffiliate_[_plyAddr] = _affAddr;

        emit RegisteredAffiliate(gameId, _plyAddr, _affAddr);
    }

    function hasAffiliate(address _plyAddr) public view returns(bool) {
        if (playerAffiliate_[_plyAddr] == address(0))
            return false;
        return true;
    }

    function clearAffiliate(address _plyAddr)
        onlyOwner
        public
    {
        require(playerAffiliate_[_plyAddr] != address(0));
        playerAffiliate_[_plyAddr] = address(0);
    }

    function getPlyAffiliateId(address _plyAddr)
        isRegisteredGame(msg.sender)
        public
        view
        returns(uint256)
    {
        uint256 gameId = gameIds_[msg.sender];
        address affAddr = playerAffiliate_[_plyAddr];
        return playerIds_[gameId][affAddr];
    }
}