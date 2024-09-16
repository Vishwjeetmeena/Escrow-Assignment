// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {

    using ECDSA for bytes32;

    mapping(address => Deposit) public deposits;

    struct Deposit{
        uint256 amount;
        bytes32 hashedBeneficiary;
        address ERC20Address;
    }

    function deposit(bytes32 hashedBeneficiaryAddress)  external payable {
        deposits[msg.sender] = Deposit({
            amount: msg.value,
            hashedBeneficiary: hashedBeneficiaryAddress,
            ERC20Address: address(0)
        });
    }

    function depositERC20(bytes32 hashedBeneficiaryAddress, address erc20Address, uint256 value) external {
        deposits[msg.sender] = Deposit({
            amount: value,
            hashedBeneficiary: hashedBeneficiaryAddress,
            ERC20Address: erc20Address
        });
    }

    function releaseFunds(address depositer, address beneficiary, address to, bytes memory signature) external  {
        bytes32 msgHash = keccak256(abi.encodePacked(to));
        Deposit memory depo = deposits[depositer];
        validation(depo.hashedBeneficiary, beneficiary, msgHash, signature);

        if (depo.ERC20Address != address(0)) {
            IERC20 token = IERC20(depo.ERC20Address);
            token.transferFrom(depositer, to, depo.amount);
        }
        else{
            payable(to).transfer(depo.amount);
        }
        delete deposits[depositer];
    }

    function validation(bytes32 hashedBeneficiary, address beneficiary, bytes32 msgHash, bytes memory signature)  internal pure{

        bytes32 beneficiaryHash = keccak256(abi.encodePacked(beneficiary));
        require(hashedBeneficiary == beneficiaryHash, "Invalid Beneficiar address");

        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        address signer = ethSignedMessageHash.recover(signature);
        require(signer == beneficiary, "Invalid signature");
    }

}


