// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./VRFv2Consumer.sol";
import "./ArenaCoin.sol";

contract Arena is ERC721, Ownable{
  using SafeMath for uint;
  VRFv2Consumer vrf;
  ArenaCoin arenaCoin;
  uint256 baseAward = 10000;
  uint256 baseMintCost = 500000; // + 0.1% per minted
  uint16 constant MAX_COUNT  = 30000;
  uint16 constant MAX_LEGENDARY = 1000;
  uint16 totalSupply;
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

  mapping (uint16 => Fighter) fighters;
  enum Race { Orcs, Dragons, Elves, Humans}

  modifier onlyRNG() {
    require(msg.sender == vrf.address || msg.sender == owner());
  }

  constructor(string memory _name, string memory _symbol, address _arenaCoin, address _consumer) ERC721(_name, _symbol){
    arenaCoin = ArenaCoin(_arenaCoin);
    vrf = VRFv2Consumer(_consumer);
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

  function mintFighter(address _to) public returns (bool) {
    require(totalSupply != MAX_COUNT, 'Max supply reached');
    uint mintCost = baseMintCost + baseMintCost.mul(totalSupply).div(1000);
    require(arenaCoin.balanceOf(msg.sender) >= mintCost, 'Not enough funds');
    require(arenaCoin.transferFrom(msg.sender, owner(), mintCost), 'Transfer has failed');
    uint16 num = uint16(totalSupply) + 1;
    _mint( _to, num );
    fighters[num] = Fighter(
      msg.sender,
      string.concat('Fighter ', Strings.toString(num)),
      Race.Humans,
      10, //speed
      num,
      10000, //hp
      10,
      3000,
      1600,
      2000,
      false,
      0
      );

    totalSupply ++;
    return true;

  }

  function setStats(
    uint256 _randomWords
    // uint16 id,
    // Race race,
    // uint24 hp,
    // uint24 stamina,
    // uint24 damage,
    // uint24 armor,
    // uint24 agility, 
    // uint8 speed
    )
    public
    onlyOwner 
    returns (bool) 
  {
    fighters[id];
  }

  function toggleMintableFights() public onlyRNG {
    mintableFights = !mintableFights;
  }
}

