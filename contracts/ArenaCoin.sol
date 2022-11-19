// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface WETH {
  function transferFrom(address from, address to, uint amount) external returns (bool);
}

contract ArenaCoin is ERC20, Ownable {

  uint256 maxSupply = 10000000000; // 1.000.000.000.000
  address arena;
  address wethAdd = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // goerli

  WETH weth = WETH(wethAdd);

  modifier onlyAdmins() {
        require(owner() == _msgSender() || arena == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

  function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

  function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        if (msg.sender == arena) {
          return;
        }
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

  constructor(string memory _name, string memory _symbol)  ERC20(_name, _symbol) {
    mint(msg.sender, 1000000000); // 1.000.000.000 = 1/10
  }

  function mint(address _to, uint256 _amount) public onlyAdmins {
    require(totalSupply() + _amount <= maxSupply, "Minted amount is more then maxSupply");
    _mint(_to, _amount);
  }

  function buyCoinsETH() external payable returns(bool) {
    require(msg.value != 0, '0 value');
    _mint(msg.sender, msg.value / (4 * 100000000000)); //msg.value / 10**11
    return true;
  }

  function buyCoinsWETH(uint amountAC) external payable returns(bool) {
    bool res = weth.transferFrom(msg.sender, owner(), amountAC * (4 * 100000000000));
    require(res, 'Tx failed');
    return true;
  }

  function setArenaAddress(address _arena) public onlyOwner {
    arena = _arena;
  }

}