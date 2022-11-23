const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Arena", function () {
  async function deployFixture() {
    const [owner, acc1, acc2] = await ethers.getSigners();

    const VRF = await ethers.getContractFactory("VRFv2Consumer");
    let vrf = await VRF.deploy();
    const Coin = await ethers.getContractFactory("ArenaCoin");
    let coin = await Coin.deploy("11", "123");
    console.log("AAAAAA", coin.address);
    console.log("AAAAAA", vrf.address);
    const Arena = await ethers.getContractFactory("Arena");
    const arena = await Arena.deploy("1", "1", coin.address, vrf.address);

    return { vrf, coin, arena, owner, acc1, acc2 };
  }

  describe("Deployment", function () {
    it("Should set the name & symb", async function () {
      const { vrf, coin, owner } = await loadFixture(deployFixture);
      expect(await coin.name()).to.equal("11");
      expect(await coin.symbol()).to.equal("123");
    });
  });

  it("Should fight", async function () {
    const { vrf, coin, arena, owner } = await loadFixture(deployFixture);
  });

  // describe("Withdrawals", function () {

  // });
});
