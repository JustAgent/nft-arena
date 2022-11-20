// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library Calculate {
  function calculateAgility(uint randomWord, uint8 i, uint e, uint agility) internal pure returns(uint8) {
    uint8 agl = 1;
    if ((randomWord / 10**(i * 6 + e) % 100) <= agility) {
        agl = 0;
      }
    return agl;
  }

  function calculateHP(uint damage, uint randomWord, uint8 i, uint e, uint add) internal pure returns(uint) {
    return damage * ((randomWord / 10 ** (i * e + add)) % 10 + 4) / 10;
  }
}