const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { BigNumber } = require("ethers");

describe("Arena", function () {
  async function deployFixture() {
    const [owner, acc1, acc2] = await ethers.getSigners();

    const VRF = await ethers.getContractFactory("VRFv2Consumer");
    let vrf = await VRF.deploy();
    const Coin = await ethers.getContractFactory("ArenaCoin");
    let coin = await Coin.deploy("11", "123");

    const Arena = await ethers.getContractFactory("Arena");
    const arena = await Arena.deploy("1", "1", coin.address, vrf.address);

    await coin.setArenaAddress(arena.address);
    await vrf.setArena(arena.address);
    return { vrf, coin, arena, owner, acc1, acc2 };
  }

  describe("Deployment", function () {
    it("Should set the name & symb", async function () {
      const { vrf, coin, owner } = await loadFixture(deployFixture);
      expect(await coin.name()).to.equal("11");
      expect(await coin.symbol()).to.equal("123");
    });
  });

  describe("Fight", function () {
    it("Should fight", async function () {
      const { vrf, coin, arena, owner, acc1 } = await loadFixture(
        deployFixture
      );

      await arena.toggleMintableFights();
      await arena.mintFighter(owner.address);
      await arena.mintFighter(acc1.address);
      expect(await arena.totalSupply()).to.eq(2);
      expect(await arena.ownerOf(2)).to.eq(acc1.address);

      // expect(await arena.fight(1, 2)).to.eq(false);
      await arena.fight(1, 2);
      await arena._fight(
        3,
        BigNumber.from(
          "12345671234567123456712345671234567123456712345671234567123456712345671234567"
        )
      );
    });
  });

  // describe("Withdrawals", function () {

  // });
});
