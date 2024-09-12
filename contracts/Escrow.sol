// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {

    using ECDSA for bytes32;

    mapping(address => Deposite) deposits;

    struct Deposite{
        uint256 amount;
        bytes32 hashedBeneficiary;
        address ERC20Address;
    }

    function deposite(bytes32 hashedBeneficiaryAddress)  external payable {
        deposits[msg.sender] = Deposite({
            amount: msg.value,
            hashedBeneficiary: hashedBeneficiaryAddress,
            ERC20Address: address(0)
        });
    }

    function depositeERC20(bytes32 hashedBeneficiaryAddress, address erc20Address, uint256 value) external {
        deposits[msg.sender] = Deposite({
            amount: value,
            hashedBeneficiary: hashedBeneficiaryAddress,
            ERC20Address: erc20Address
        });
    }

    function releaseFunds(address depositer, address beneficiary, bytes32 msghash, bytes memory signature) external  {
        Deposite memory depo = deposits[depositer];

        validation(depo.hashedBeneficiary, beneficiary, msghash, signature);

        if (depo.ERC20Address != address(0)) {
            IERC20 token = IERC20(depo.ERC20Address);
            token.transfer(beneficiary, depo.amount);
        }
        else{
            payable(beneficiary).transfer(depo.amount);
        }
        delete deposits[depositer];
    }

    function validation(bytes32 hashedBeneficiary, address beneficiary, bytes32 msghash, bytes memory signature)  internal pure{

        bytes32 beneficiaryHash = keccak256(abi.encodePacked(beneficiary));
        require(hashedBeneficiary == beneficiaryHash, "Invalid Beneficiar address");

        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msghash));
        address signer = ethSignedMessageHash.recover(signature);
        require(signer == beneficiary, "Invalid signature");
    }

}

/*
Your task is to implement an escrow contract in Solidity.

1. Two roles are interacting with the smart contract: depositor and beneficiary. The depositor sends an arbitrary ERC20 or ETH to the smart contract and provides information about the beneficiary address which can release the funds. The beneficiary address should remain hidden until the funds are released. Hashing the address is enough.

2. The beneficiary signs the release funds order off-chain and any address can submit it to the chain. The funds should be released to the address provided by the beneficiary.

3. The escrow contract should handle multiple depositors and beneficiaries. There is always only one beneficiary for the given deposit.
*/

