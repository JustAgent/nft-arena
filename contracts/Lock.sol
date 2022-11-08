// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

uint16 constant MAX_COUNT  = 30000;
uint16 constant MAX_LEGENDARY = 1000;

contract Arena is ERC721{
  struct Fighter {
    string name;
    Race race;
    uint24 hp;
    uint24 stamina;
    uint24 damage;
    uint24 armor;
    uint24 agility;
    uint24 speed;
    bool legendary;
    uint256 power;
  }

  enum Race { Orcs, Dragons, Elves, Humans}

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol){}
}
