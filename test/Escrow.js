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

    //message hash
    const msgHash = ethers.solidityPackedKeccak256(
      ["address"],
      [other.address]
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

  it("Should Deposit ERC20 Token funds and release the funds to the address provided by the beneficiary with a valid signature ", async function () {
    const { owner, depositor, beneficiary, Escrow, other } = await deployTokenFixture();

    //Deploying ERC20Token
    const ERC20Factory = await ethers.getContractFactory("ERC20Token");
    const ERC20 = await ERC20Factory.deploy(owner.address);
    await ERC20.waitForDeployment();

    //minting 1000 token in depositor address
    await ERC20.mint(depositor.address, 1000);

    //Depositing ERC20 Funds
    const hashedBeneficiaryAddress = ethers.solidityPackedKeccak256(
      ["address"],
      [beneficiary.address]
    );
    await Escrow.connect(depositor).depositERC20( hashedBeneficiaryAddress, ERC20.target, 100);

    //Approving Escrow contract to spend token on behalf of depositor
    await ERC20.connect(depositor).approve(Escrow.target, 100);

    const deposit = await Escrow.deposits(depositor.address);
    expect(deposit.amount).to.equal(100);
    expect(deposit.hashedBeneficiary).to.equal(hashedBeneficiaryAddress);
    expect(deposit.ERC20Address).to.equal(ERC20.target);

    //Releasing Funds
    const msgHash = ethers.solidityPackedKeccak256(
      ["address"],
      [other.address]
    );
    const signature = await beneficiary.signMessage(ethers.toBeArray(msgHash));
    await Escrow.releaseFunds(depositor.address, beneficiary.address, other.address, signature);

    expect(await ERC20.balanceOf(other.address)).to.be.equal(100n);

  })

});
