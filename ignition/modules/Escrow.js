const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("Escrow", (m) => {
  const escrow = m.contract("Escrow");
  return { escrow };
});
