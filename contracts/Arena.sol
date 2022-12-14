// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./VRFv2Consumer.sol";
import "./ArenaCoin.sol";
import "./Calculate.sol";


contract Arena is ERC721, Ownable, ReentrancyGuard{
  using SafeMath for uint;
  using Calculate for uint;
  VRFv2Consumer vrf;
  ArenaCoin arenaCoin;
  uint256 public baseReward = 10000;
  uint256 baseMintCost = 500000; // + 0.1% per minted
  uint256 legendaryMintCost = 2000000; // 2mln
  uint256 restorationCost = 20000;
  uint16 constant MAX_COUNT  = 30000;
  uint16 constant MAX_LEGENDARY = 1000;
  uint16 public totalSupply;
  uint16 public totalLegendSupply;
  bool public mintableFights;
  
  struct Fighter {
    address owner;
    string name;
    Race race;
    uint24 speed;
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
  mapping (uint16 => mapping(uint16 => bool)) challenges;
  enum Race { Orcs, Dragons, Elves, Humans}

  modifier onlyRNG() {
    require(msg.sender == address(vrf) || msg.sender == owner());
    _;
  }

  modifier onlyFighterOwner(uint16 _id) {
    _onlyFO(_id);
    _;
  }

  constructor(string memory _name, string memory _symbol, address _arenaCoin, address _consumer) ERC721(_name, _symbol){
    arenaCoin = ArenaCoin(_arenaCoin);
    vrf = VRFv2Consumer(_consumer);
  }

  function _onlyFO(uint16 _id) private view {
    require(fighters[_id].owner == msg.sender, 'Not owner');
  }

  function challenge(uint16 yourFighter, uint16 opponent) external onlyFighterOwner(yourFighter) {
    require(fighters[opponent].owner != msg.sender, 'Self fight');
    require(arenaCoin.transferFrom(msg.sender, address(this), 8000), 'TX failed');
    challenges[opponent][yourFighter] = true;
  }

  function applyChallenge(uint16 yourFighter, uint16 opponent) external onlyFighterOwner(yourFighter) {
    require(challenges[yourFighter][opponent] == true, 'No challenge');
    challenges[yourFighter][opponent] == false;
    arenaCoin.transferFrom(address(this), msg.sender, 7000);
    fight(yourFighter, opponent);
  }

  function fight(uint16 fighter1Id, uint16 fighter2Id) private {
    require(mintableFights, "Can not access mint-fights"); // Move to mintFights
    require(fighters[fighter1Id].stamina>0, 'Stamina1');
    require(fighters[fighter2Id].stamina>0, 'Stamina2');
    require(fighters[fighter1Id].stamina > 0 && fighters[fighter2Id].stamina > 0, "Fighters have no stamina");
    require(fighters[fighter1Id].owner != fighters[fighter2Id].owner, "Self fights aren't allowed");

    fighters[fighter1Id].stamina -= 1;
    fighters[fighter2Id].stamina -= 1;
    

    uint256 requestId = vrf.requestRandomWords(); // comment when debug
    requestsToFight[requestId] = FightParams(fighters[fighter1Id], fighters[fighter2Id]);

  
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
      uint8 agl1 = 1;
      if ((randomWord / 10 % 100) <= slower.agility) {
        agl1 = 0;
      }
      int orcdmg1 = int( Calculate.calculateHP(faster.damage, randomWord, 0, 0, 0) * agl1) - int24(slower.armor);
      if (orcdmg1< 0 ) {
        orcdmg1 = 0;
      }
      hp2 -= orcdmg1;
    }
    if (slower.race == Race.Orcs) {
      uint agl2 = 1;
      if ((randomWord / 10000 % 100) <= faster.agility) {
        agl2 = 0;
      }
      int orcdmg2 = int( Calculate.calculateHP(slower.damage, randomWord, 0, 0, 3) * agl2) - int24(faster.armor);
      if (orcdmg2< 0 ) {
        orcdmg2 = 0;
      }
      hp1 -= orcdmg2;
    }
    
    // Main Fight
    uint8 i = 1;
    while (i <= 10) { 
      if(hp1 <= 0 || hp2 <= 0) {
        break;
      }
      //Step 1
      int damage1 = int( Calculate.calculateHP(faster.damage, randomWord, i, 6, 0) * 
        Calculate.calculateAgility(randomWord, i, 1, slower.agility)) - int24(slower.armor);
      if (damage1< 0 ) {
        damage1 = 0;
      }
      hp2 -= damage1;
      
      // Check for winner
      if (hp2 <= 0) {
        WINNER = faster.id;
        LOSER = slower.id;
        break;
      }

      //Step 2
      int damage2 = int( Calculate.calculateHP(slower.damage, randomWord, i, 6, 3) * 
        Calculate.calculateAgility(randomWord, i, 4, faster.agility)) - int24(faster.armor);
      if (damage2< 0 ) {
        damage2 = 0;
      }
      hp1 -= damage2;

      // Check for winner
      if (hp1 <= 0) {
        WINNER = slower.id;
        LOSER = faster.id;
        break;
      }
      i++;
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
    if (fighters[WINNER].race == Race.Dragons) {
      if ( (randomWord / (10 ** 70) % 10) < 3 ) {
        fighters[WINNER].stamina += 1;
      }
    }
    _rewarding(WINNER, LOSER, i-1);


  }

  

  function _rewarding(
      uint16 _winner, // remake to uint16
      uint16 _loser,
      uint8 _hits) 
      private 
    {
    uint256 totalReward = baseReward;
    Fighter memory winner = fighters[_winner];
    Fighter memory loser = fighters[_loser];
    fighters[_winner].wins += 1;
    
    uint power1 = winner.power;
    uint power2 = loser.power;
    if(power1 < power2 ) {
      uint dif = power2 - power1;
      totalReward += dif.div(5);  // +20% of power difference
    }
    
    totalReward = totalReward + totalReward.mul(10 - _hits).div(10);

    if (winner.race == Race.Humans) {
      totalReward = totalReward.mul(12).div(10);
    }
    
    // For mintableFights
    arenaCoin.mint(winner.owner, totalReward);

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
      _to,
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
    fighters[id].speed = uint24( _randomWords % 100);
    fighters[id].race = Race((_randomWords / 1000000000000000) / 100 % 4);

    if (fighters[id].race == Race.Elves) {
      fighters[id].agility += 5;
    }
  // 1 HP + 1.5 ARMOR + 1000 AGILITY + 1 DAMAGE + 150 SPEED? NOT WORKING CZ OF TYPES

     fighters[id].power = uint(
      uint(fighters[id].hp) + 
      uint(fighters[id].armor * 15 / 10) +
      uint(fighters[id].agility * 1000) +
      uint(fighters[id].damage) +
      uint(fighters[id].speed * 150)
      );
    
    return true;
    

  }

  function buyFighter(uint16 _id) nonReentrant external returns(bool) {
    require(fighters[_id].isSelling, 'Not for sell');
    require(arenaCoin.balanceOf(msg.sender) >= fighters[_id].price, 'Not enough funds');
    require(fighters[_id].owner != msg.sender, 'Cant transfer to yourself');

    bool result = arenaCoin.transferFrom(msg.sender, fighters[_id].owner, fighters[_id].price);
    require(result, "Transfer failed");
    transferFrom(fighters[_id].owner, msg.sender, _id); 
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
  function returnWarrior( uint16 id) public view returns(Fighter memory) {
     return fighters[id];
 }
 function calculateReward(uint16 you, uint16 enemy) external view returns(uint) {
  uint totalReward = baseReward;
  
  if (fighters[you].power < fighters[enemy].power) {
      uint dif = fighters[enemy].power - fighters[you].power;
      totalReward += dif.div(5);  // +20% of power difference
    }

    if (fighters[you].race == Race.Humans) {
      totalReward = totalReward.mul(12).div(10);
    }

  return totalReward;
 }
}
