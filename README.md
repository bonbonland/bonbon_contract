## ethereum contracts

### 部署BBT和Dividend合约
```
truffle migrate --network development -f 12
```

### BBT添加白名单
```
truffle exec ./truffle_scripts/project_a/bbt_add_whitelist.js --network development 0xDD0680dB212610909DAbEcf4231a30c2fF7437B4
```

### Dividend注册游戏
```
truffle exec ./truffle_scripts/project_a/dividend_register_game.js --network development 0xDD0680dB212610909DAbEcf4231a30c2fF7437B4
```