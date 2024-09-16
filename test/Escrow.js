const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Escrow", function () {
  const zeroAddress = "0x0000000000000000000000000000000000000000";

  async function deployTokenFixture() {
    const [owner, depositor, beneficiary, other] = await ethers.getSigners();

    const EscrowFactory = await ethers.getContractFactory("Escrow");
    const Escrow = await EscrowFactory.deploy();
    await Escrow.waitForDeployment();

    return { owner, depositor, beneficiary, other, Escrow };
  }

  it("Should allow depositor to deposit ETH and hash the beneficiary address", async function () {
    const { depositor, beneficiary, Escrow } = await deployTokenFixture();

    const depositAmount = ethers.parseEther("100");
    const hashedBeneficiaryAddress = ethers.solidityPackedKeccak256(
      ["address"],
      [beneficiary.address]
    );

    const depositTx = await Escrow.connect(depositor).deposit(
      hashedBeneficiaryAddress,
      { value: depositAmount }
    );
    await depositTx.wait();

    const deposit = await Escrow.deposits(depositor.address);
    expect(deposit.amount).to.equal(depositAmount);
    expect(deposit.hashedBeneficiary).to.equal(hashedBeneficiaryAddress);
    expect(deposit.ERC20Address).to.equal(zeroAddress);
  });

  it("Should release the funds to the address provided by the beneficiary with a valid signature", async function () {
    const { depositor, beneficiary, Escrow, other } =
      await deployTokenFixture();

    // Simulate a deposit
    const depositAmount = ethers.parseEther("100");

    const hashedBeneficiaryAddress = ethers.solidityPackedKeccak256(
      ["address"],
      [beneficiary.address]
    );
    await Escrow.connect(depositor).deposit(hashedBeneficiaryAddress, {
      value: depositAmount,
    });

    // get the msg hash
    const msgHash = ethers.solidityPackedKeccak256(
      ["address"],
      [other.address]
    );
    const ethSignedMessageHash = ethers.solidityPackedKeccak256(
      ["string", "bytes32"],
      ["\x19Ethereum Signed Message:\n32", msgHash]
    );

    // Sign the message hash
    const signature = await beneficiary.signMessage(ethers.toBeArray(msgHash));

    // Release the funds
    await expect(() =>
      Escrow.connect(depositor).releaseFunds(
        depositor.address,
        beneficiary.address,
        other.address,
        signature
      )
    ).to.changeEtherBalance(other, depositAmount);
  });
});
