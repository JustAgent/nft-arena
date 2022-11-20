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
  uint256 legendaryMintCost = 2000000; // 2mln
  uint256 restorationCost;
  uint16 constant MAX_COUNT  = 30000;
  uint16 constant MAX_LEGENDARY = 1000;
  uint16 totalSupply;
  uint16 totalLegendSupply;
  bool mintableFights;
  
  struct Fighter {
    address owner;
    string name;
    Race race;
    uint8 speed;
    uint16 id;
    int hp;
    uint24 stamina;
    uint24 maxStamina;
    uint24 damage;
    uint24 armor;
    uint24 agility;
    bool legendary;
    bool isSelling;
    uint256 price;
    uint256 wins;
    uint256 lastFight;
    uint256 power; // Может логичнее каждый раз ее считать?
  }

  struct FightParams {
    Fighter fighter1;
    Fighter fighter2;
  }

  mapping (uint256 => uint16) requestsToId;
  mapping (uint256 => FightParams) requestsToFight;
  mapping (uint16 => Fighter) fighters;

  enum Race { Orcs, Dragons, Elves, Humans}

  modifier onlyRNG() {
    require(msg.sender == address(vrf) || msg.sender == owner());
    _;
  }

  modifier onlyFighterOwner(uint16 _id) {
    require(fighters[_id].owner == msg.sender, 'Not owner');
    _;
  }

  constructor(string memory _name, string memory _symbol, address _arenaCoin, address _consumer) ERC721(_name, _symbol){
    arenaCoin = ArenaCoin(_arenaCoin);
    vrf = VRFv2Consumer(_consumer);
  }

  function fight(Fighter memory fighter1, Fighter memory fighter2) external returns(uint16) {
    require(mintableFights, "Can not access mint-fights"); // Move to mintFights
    fighter1.stamina --;
    fighter1.stamina --;
    

    uint256 requestId = vrf.requestRandomWords(); // comment when debug
    requestsToFight[requestId] = FightParams(fighter1, fighter2);

  
  }

  function _fight(uint requestId, uint randomWord) public {
    require(msg.sender == address(this) || msg.sender == address(vrf), "Not allowed");
    FightParams memory params = requestsToFight[requestId];

    Fighter memory faster = params.fighter1;
    Fighter memory slower = params.fighter2;
    if (params.fighter1.speed < params.fighter2.speed) {
      faster = params.fighter2;
      slower = params.fighter1;
    }

    int hp1 = faster.hp;
    int hp2 = slower.hp;
    uint16 WINNER;
    uint16 LOSER;
    // Starting battle
    // ORCs
    if (faster.race == Race.Orcs) {
      uint k = (randomWord % 10) + 4;
      uint n = (randomWord / 10 % 100);
      uint agl1 = 1;
      if (n <= slower.agility) {
        agl1 = 0;
      }
      hp2 -= int(faster.damage * k / 10 * agl1) - int24(slower.armor);
    }
    if (slower.race == Race.Orcs) {
      uint k = (randomWord / 1000 % 10) + 4;
      uint n = (randomWord / 10000 % 100);
      uint agl2 = 1;
      if (n <= faster.agility) {
        agl2 = 0;
      }
      hp1 -= int(slower.damage * k / 10 * agl2) - int24(faster.armor);
    }
    
    // Main Fight
    uint8 i = 1;
    while (i <= 10 || hp1 > 0 || hp2 > 0) {
      //Step 1
      uint k = (randomWord / 10**(i * 6)) % 10 + 4;
      uint n = (randomWord / 10**(i * 6 + 1) % 100);
      uint agl1 = 1;
      if (n <= slower.agility) {
        agl1 = 0;
      }
      hp2 -= int(faster.damage * k / 10 * agl1) - int24(slower.armor);
      
      // Check for winner
      if (hp2 <= 0) {
        WINNER = faster.id;
        LOSER = slower.id;
        break;
      }

      //Step 2
      uint k2 = (randomWord / 1000 / (10 ** (i * 6)) ) % 10 + 4;
      uint n2 = (randomWord / 100000 % 100);
      uint agl2 = 1;
      if (n2 <= faster.agility) {
        agl2 = 0;
      }
      hp1 -= int(slower.damage * k2 / 10 * agl2) - int24(faster.armor);
      // Check for winner
      if (hp1 <= 0) {
        WINNER = slower.id;
        LOSER = faster.id;
        break;
      }
    }
    // If its draw
    if (WINNER == 0) {
      if (hp1 > hp2) {
        WINNER = faster.id;
        LOSER = slower.id;
      }
      else {
        WINNER = slower.id;
        LOSER = faster.id;
      }
    }
    // dragon

    _rewarding(WINNER, LOSER, i);


  }

  function _rewarding(
      uint16 _winner, // remake to uint16
      uint16 _loser,
      uint8 _hits) 
      private 
    {
    uint256 totalAward = baseAward;
    Fighter memory winner = fighters[_winner];
    Fighter memory loser = fighters[_loser];
    winner.wins += 1;
    
    uint power1 = winner.power;
    uint power2 = loser.power;
    if(power1 < power2 ) {
      uint dif = power2 - power1;
      totalAward += dif.div(5);  // +20% of power difference
    }
    
    totalAward = totalAward + totalAward.mul(10 - _hits);

    if (winner.race == Race.Humans) {
      totalAward = totalAward.mul(12).div(10);
    }
    
    // For mintableFights
    arenaCoin.mint(winner.owner, totalAward);

  }

  function mintFighter(address _to) public returns (bool) {
    require(totalSupply != MAX_COUNT, 'Max supply reached');
    uint mintCost = baseMintCost + baseMintCost.mul(totalSupply).div(1000);
    require(arenaCoin.balanceOf(msg.sender) >= mintCost, 'Not enough funds');
    require(arenaCoin.transferFrom(msg.sender, owner(), mintCost), 'Transfer has failed');
    uint16 num = uint16(totalSupply) + 1;
    _mint( _to, num );

    uint256 requestId = vrf.requestRandomWords(); // comment when debug
    requestsToId[requestId] = num;

    fighters[num] = Fighter(
      msg.sender,
      string.concat('Fighter ', Strings.toString(num)),
      Race.Humans,
      0, //speed
      num,
      0, //hp
      0, //stamina
      0, //MaxStamina
      0, //damage
      0, //armor
      0, //agility
      false, //legendary
      false, //isSelling
      0, //price
      0,   //wins
      0, //last fight
      0 //power
      );

    totalSupply ++;
    return true;

  }

  function setStats(
    uint256 _randomWords,
    uint16 id
    )
    public
    onlyRNG 
    returns (bool) 
  {
    
    fighters[id].hp = int((_randomWords / 100) % 10000);
    fighters[id].damage = uint24((_randomWords / 10000000) % 10000);
    fighters[id].armor = uint24((_randomWords / 100000000000) % 10000);
    fighters[id].agility = uint24((_randomWords / 1000000000000000) % 100);
    fighters[id].maxStamina = uint24((_randomWords / 1000000) % 10);
    fighters[id].stamina = uint24((_randomWords / 1000000) % 10);
    fighters[id].speed = uint8( _randomWords % 100);
    fighters[id].race = Race((_randomWords / 1000000000000000) / 100 % 4);

  // 1 HP + 1.5 ARMOR + 1000 AGILITY + 1 DAMAGE + 150 SPEED? NOT WORKING CZ OF TYPES
    // fighters[id].power = 
    //   (fighters[id].hp) + 
    //   (fighters[id].armor * 15 / 10) +
    //   (fighters[id].agility * 1000) +
    //   (fighters[id].damage) +
    //   (fighters[id].speed * 150);
    
    //emit
    return true;
    

  }

  function buyFighter(uint16 _id) external returns(bool) {
    require(fighters[_id].isSelling, 'Not for sell');
    require(arenaCoin.balanceOf(msg.sender) >= fighters[_id].price, 'Not enough funds');
    require(fighters[_id].owner != msg.sender, 'Cant transfer to yourself');

    bool result = arenaCoin.transferFrom(msg.sender, fighters[_id].owner, fighters[_id].price);
    require(result, "Transfer failed");

    fighters[_id].owner = msg.sender;
    fighters[_id].isSelling = false;

    return true;

  }

  function sellFighter(uint16 _id, uint256 _price) external onlyFighterOwner(_id) {
    fighters[_id].price = _price;
    fighters[_id].isSelling = true;
    
  }

  function stopSelling(uint16 _id) external onlyFighterOwner(_id) {
    fighters[_id].isSelling = false;
  }

  function transferFighter(uint16 _id, address _to) external returns(bool) {
    require(fighters[_id].owner == msg.sender, 'Not owner');
    fighters[_id].owner = _to;

    return true;
  }

  function restoreStamina(uint16 _id, uint amount) public returns(bool) {
    require(arenaCoin.balanceOf(msg.sender) >= amount, 'Not enough funds');
    if (amount == restorationCost) {
      fighters[_id].stamina = fighters[_id].maxStamina;
      return true;
    }
    if (block.timestamp - fighters[_id].lastFight >= 1 days ) {
      fighters[_id].stamina = fighters[_id].maxStamina;
      return true;
    }
    return false;
  }

  function evolve(uint16 _id) external onlyFighterOwner(_id) {
    require(totalLegendSupply < MAX_LEGENDARY, 'Reached max legendary count');
    require(fighters[_id].wins >= 50, 'Not enough wins');
    require(arenaCoin.balanceOf(msg.sender) >= legendaryMintCost, 'Not enough funds');

    bool result = arenaCoin.transferFrom(msg.sender, address(this), legendaryMintCost);
    require(result, 'Transfer failed');

    totalLegendSupply++;
  }
  function getRequestId(uint256 _requestId) public view returns(uint16) {
    return requestsToId[_requestId];
  }

  function toggleMintableFights() public onlyOwner {
    mintableFights = !mintableFights;
  }
}

