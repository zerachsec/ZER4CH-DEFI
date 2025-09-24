// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Zer4ch Stable Coin
 * @author Zer4ch
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
 * This is the contract meant to be owned by DSCEngine. It is a ERC20 token that can be minted and burned by theDSCEngine smart contract.
 */
contract Zer4chStableCoin is ERC20Burnable, Ownable {
    error Zer4chStableCoin__mustbemorethanzero();
    error Zer4chStableCoin__burnAmountExceedsBalance();
    error Zer4chStableCoin__NotZeroAddress();

    constructor() ERC20("Zer4chStableCoin", "Z4C") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert Zer4chStableCoin_mustbemorethanzero();
        }
        if (_amount > balance) {
            revert Zer4chStableCoin__burnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert Zer4chStableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert Zer4chStableCoin__mustbemorethanzero();
        }
        _mint(_to, _amount);
        return true;
    }
}
