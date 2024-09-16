# Escrow Contract

This repository contains an Ethereum-based escrow contract implemented in Solidity. The contract allows a **depositor** to send an arbitrary amount of **ETH** or **ERC20 tokens** to the contract and define a **beneficiary** who will eventually receive the funds. The beneficiary address is hidden until the funds are released, and off-chain signatures are used to authorize the release of funds.

## Features

- **Supports both ETH and ERC20 deposits**
- **Role-based interactions**: Depositors send funds and define a hashed beneficiary, who can later release the funds.
- **Off-chain signature validation**: Beneficiaries sign a release order off-chain, and any party can submit the order to release funds.
- **Multi-depositor support**: The contract handles deposits from multiple depositors and ensures each deposit has a unique beneficiary.
- **Security**: The beneficiary address remains hashed until the funds are released, ensuring privacy.

## Table of Contents
- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)

## Overview

This escrow system is designed with the following roles and interactions:
- **Depositor**: The depositor can send ETH or ERC20 tokens to the contract and specify a hashed beneficiary address.
- **Beneficiary**: The beneficiary's address is hashed and stored with the deposit. The actual address remains hidden until funds are released. The beneficiary can sign a release order off-chain, and anyone can submit this signed order to release the funds to the beneficiary.

The contract supports multiple depositors and beneficiaries. Each deposit is associated with exactly one beneficiary.

## Requirements

Ensure you have the following installed:

- [Node.js](https://nodejs.org/) (v16+)
- [npm](https://www.npmjs.com/)
- [Hardhat](https://hardhat.org/)
- [Ethers.js](https://docs.ethers.io/v5/) (v6)
- [OpenZeppelin Contracts](https://openzeppelin.com/contracts/)

## Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/your-username/escrow-contract.git
    cd Escrow-Assignment
    ```

2. Install the necessary dependencies:
    ```bash
    npm install
    ```

3. Compile the contract:
    ```bash
    npx hardhat compile
    ```

## Usage

- for Testing visit (https://hardhat.org/hardhat-runner/docs/guides/test-contracts) 
- for Deplyoment and Verification visit (https://hardhat.org/hardhat-runner/docs/guides/verifying)

