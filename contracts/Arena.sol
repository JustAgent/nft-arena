// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Arena is ERC721, Ownable{

ArenaCoin arenaCoin;
uint16 constant MAX_COUNT  = 30000;
uint16 constant MAX_LEGENDARY = 1000;

// MAX STATS:
// - [ ] HP 40.000 / 100.000
// - [ ] DAMAGE 15.000 / 40 000
// - [ ] ARMOR 8000 / 15000
// - [ ] AGILITY 20 / 30
// - [ ] Speed 100 / 100
// - [ ] ENERGY 10 / 1

  struct Fighter {
    address owner;
    string name;
    Race race;
    uint8 speed;
    uint16 id;
    uint24 hp;
    uint24 stamina;
    uint24 damage;
    uint24 armor;
    uint24 agility;
    bool legendary;
    uint256 power; // Может логичнее каждый раз ее считать?
  }


  enum Race { Orcs, Dragons, Elves, Humans}

  constructor(string memory _name, string memory _symbol, address _arenaCoin) ERC721(_name, _symbol){
    arenaCoin = ArenaCoin(_arenaCoin);
  }

  function _fight(Fighter memory fighter1, Fighter memory fighter2)  private returns(uint16) {
    // uint24 hp1 = fighter1.hp;
    // uint24 hp2 = fighter2.hp;
    // 1hit
    // 2hit
    // 3hit
    address winner;
    _rewarding(winner);
  }


  function _rewarding(address _winner) private {

  }
}


contract ArenaCoin is ERC20, Ownable {

  constructor(string memory _name, string memory _symbol)  ERC20(_name, _symbol) {
    mint(msg.sender, 1000000000000); // 1.000.000.000.000
  }

  function mint(address _to, uint256 _amount) public onlyOwner {
    _mint(_to, _amount);
  }

}