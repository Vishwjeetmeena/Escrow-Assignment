// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Escrow Contract
 * @dev Handles ETH and ERC20 deposits with beneficiary release conditions.
 */
contract Escrow {
    using ECDSA for bytes32;

    ///@notice Stores deposits for each depositor
    mapping(address => Deposit) public deposits;

    ///@dev Represents a deposit with amount, hashed beneficiary, and optional ERC20 token address
    struct Deposit {
        uint256 amount;
        bytes32 hashedBeneficiary;
        address ERC20Address;
    }

    /**
     * @dev Emitted when a deposit is made.
     * @param depositer The address of the depositor.
     * @param beneficiary The hashed address of the beneficiary.
     */
    event Deposited(address indexed depositer, bytes32 indexed beneficiary);

    /**
     * @dev Emitted when funds are released.
     * @param depositer The address of the depositor.
     * @param beneficiary The address of the beneficiary.
     * @param to The address to which the funds are released.
     */
    event Released(
        address indexed depositer,
        address indexed beneficiary,
        address indexed to
    );

    ///@notice Custom error for invalid beneficiary address
    error InvalidBeneficiary();

    ///@notice Custom error for invalid signature during release
    error InvalidSignature();

    /**
     * @notice Deposits ETH to the contract with a hashed beneficiary address.
     * @param hashedBeneficiaryAddress The hashed address of the beneficiary.
     */
    function deposit(bytes32 hashedBeneficiaryAddress) external payable {
        deposits[msg.sender] = Deposit({
            amount: msg.value,
            hashedBeneficiary: hashedBeneficiaryAddress,
            ERC20Address: address(0)
        });

        emit Deposited(msg.sender, hashedBeneficiaryAddress);
    }

    /**
     * @notice Deposits ERC20 tokens to the contract with a hashed beneficiary address.
     * @param hashedBeneficiaryAddress The hashed address of the beneficiary.
     * @param erc20Address The address of the ERC20 token contract.
     * @param value The amount of tokens to deposit.
     */
    function depositERC20(
        bytes32 hashedBeneficiaryAddress,
        address erc20Address,
        uint256 value
    ) external {
        deposits[msg.sender] = Deposit({
            amount: value,
            hashedBeneficiary: hashedBeneficiaryAddress,
            ERC20Address: erc20Address
        });

        emit Deposited(msg.sender, hashedBeneficiaryAddress);
    }

    /**
     * @notice Releases funds to the designated address if the release conditions are met.
     * @param depositer The address of the depositor.
     * @param beneficiary The address of the beneficiary.
     * @param to The address where the funds will be released.
     * @param signature The signature authorizing the release.
     */
    function releaseFunds(
        address depositer,
        address beneficiary,
        address to,
        bytes memory signature
    ) external {
        bytes32 msgHash = keccak256(abi.encodePacked(to));
        Deposit memory depo = deposits[depositer];
        _validate(depo.hashedBeneficiary, beneficiary, msgHash, signature);

        if (depo.ERC20Address != address(0)) {
            IERC20 token = IERC20(depo.ERC20Address);
            token.transferFrom(depositer, to, depo.amount);
        } else {
            payable(to).transfer(depo.amount);
        }

        delete deposits[depositer];
        emit Released(depositer, beneficiary, to);
    }

    /**
     * @dev Validates the beneficiary and signature for the release.
     * @param hashedBeneficiary The hashed address of the beneficiary.
     * @param beneficiary The actual address of the beneficiary.
     * @param msgHash The message hash to validate.
     * @param signature The signed message.
     */
    function _validate(
        bytes32 hashedBeneficiary,
        address beneficiary,
        bytes32 msgHash,
        bytes memory signature
    ) internal pure {
        bytes32 beneficiaryHash = keccak256(abi.encodePacked(beneficiary));
        if (hashedBeneficiary != beneficiaryHash) {
            revert InvalidBeneficiary();
        }

        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
        );
        address signer = ethSignedMessageHash.recover(signature);
        if (signer != beneficiary) {
            revert InvalidSignature();
        }
    }
}
