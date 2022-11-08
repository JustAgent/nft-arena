// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Arena is ERC721, Ownable{
  using SafeMath for uint;

  ArenaCoin arenaCoin;
  uint256 baseAward = 10000;
  uint16 constant MAX_COUNT  = 30000;
  uint16 constant MAX_LEGENDARY = 1000;
  bool mintableFights;
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
    require(mintableFights, "Can not access mint-fights"); // Move to mintFights
    // uint24 hp1 = fighter1.hp;
    // uint24 hp2 = fighter2.hp;
    // 1hit
    // 2hit
    // 3hit
    Fighter memory winner;
    uint8 hits;
    uint power1; // winner
    uint power2;
    _rewarding(winner, power1, power2, hits);


    return winner.id;
  }


  function _rewarding(
      Fighter memory _winner,
      uint _power1,
      uint _power2,
      uint8 _hits) 
      private 
    {
    uint256 totalAward = baseAward;

    if(_power1 < _power2 ) {
      uint dif = _power2 - _power1;
      totalAward += dif.div(5);  // +20% of power difference
    }
    
    totalAward = totalAward + totalAward.mul(10 - _hits);

    if (_winner.race == Race.Humans) {
      totalAward = totalAward.mul(12).div(10);
    }
    
    // For mintableFights
    arenaCoin.mint(_winner.owner, totalAward);

  }

  function changeMintableFights() public onlyOwner {
    mintableFights = !mintableFights;
  }
}


contract ArenaCoin is ERC20, Ownable {

  uint256 maxSupply = 10000000000; // 1.000.000.000.000
  address arena;

   modifier onlyAdmins() {
        require(owner() == _msgSender() || arena == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

  constructor(string memory _name, string memory _symbol)  ERC20(_name, _symbol) {
    mint(msg.sender, 1000000000); // 1.000.000.000 = 1/10
  }

  function mint(address _to, uint256 _amount) public onlyAdmins {
    require(totalSupply() + _amount <= maxSupply, "Minted amount is more then maxSupply");
    _mint(_to, _amount);
  }

  function setArenaAddress(address _arena) public onlyOwner {
    arena = _arena;
  }

}