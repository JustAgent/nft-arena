// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArenaCoin is ERC20, Ownable {

  uint256 maxSupply = 10000000000; // 1.000.000.000.000
  address arena;

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

  function setArenaAddress(address _arena) public onlyOwner {
    arena = _arena;
  }

}