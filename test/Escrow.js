const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Escrow", function () {
  const zeroAddress = "0x0000000000000000000000000000000000000000";
  
  async function deployTokenFixture() {
    const [owner, depositor, beneficiary, otherAddress] = await ethers.getSigners();

    const Escrow = await ethers.deployContract("Escrow");

    return { owner, depositor, beneficiary, otherAddress, Escrow };
  }

  it("Should allow depositor to deposit ETH and hash the beneficiary address", async function () {
    const { depositor, beneficiary, Escrow } = await loadFixture(deployTokenFixture);

    const depositAmount = ethers.parseEther("100");
    const hashedBeneficiaryAddress = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(["address"], [beneficiary.address]));
    
    const depositTx = await Escrow.connect(depositor).deposit(hashedBeneficiaryAddress, { value: depositAmount });
    await depositTx.wait();

    const deposit = await Escrow.deposits(depositor.address);
    expect(deposit.amount).to.equal(depositAmount);
    expect(deposit.hashedBeneficiary).to.equal(hashedBeneficiaryAddress);
    expect(deposit.ERC20Address).to.equal(zeroAddress);
  });
});

