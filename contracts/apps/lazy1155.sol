// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { ERC1155Pausable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

import { Strings } from "../utils/Strings.sol";
import { Integers } from "../utils/Integers.sol";
import { ILazy1155 } from "../interfaces/token/ILazy1155.sol";

contract Lazy1155 is ILazy1155, ERC1155, Ownable, ERC1155Pausable, ERC1155Burnable, ERC1155Supply {
    uint256 private _totalEmittion;

    error Lazy1155__TokenIdDoesntExist(); // TODO: Look for how to check Ids in batch
    error Lazy1155__TokenCapExceeded();
    error Lazy1155__QuantityMustBeGreaterThanCero();
    error Lazy1155__NoBalanceForTokenId();

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    constructor(uint256 totalEmmition, string memory _uri) ERC1155(_uri) Ownable(msg.sender) {
        _totalEmittion = totalEmmition;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function tokenURI(address from, uint256 tokenId) external view returns (string memory) {
        // console.log("tokenURI called.");
        if (!this.tokenExists(tokenId)) revert Lazy1155__TokenIdDoesntExist();
        if (!this.isOwnerOfToken(from, tokenId)) revert Lazy1155__NoBalanceForTokenId();

        string memory uri = Strings.replace(super.uri(tokenId), "{id}", Integers.toString(tokenId), 1);
        //console.log("[%s]", uri);
        return uri;
    }

    function isOwnerOfToken(address _owner, uint256 _tokenId) external view returns (bool) {
        uint256 balance = super.balanceOf(_owner, _tokenId);
        return balance > 0;
    }

    function tokenExists(uint256 _tokenId) external view returns (bool) {
        // Check the total supply of the token ID
        // console.log("tokenExists called.");
        uint256 totalSupply = totalSupply(_tokenId);
        return totalSupply > 0;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Creates a `value` amount of tokens of type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * @param to The destination address of the token to being transferred
     * @param id The ID of the token being transferred
     * @param amount The amount of tokens being transferred
     * @param data Additional data with no specified format
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        uint256 totalSuply = totalSupply();
        //console.log("[%s]", totalSuply);
        // TODO: overflow?
        if (totalSuply + amount > _totalEmittion) {
            revert Lazy1155__TokenCapExceeded();
        }
        _mint(to, id, amount, data);
    }


    /**
     * @dev bacthed version of mint.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     *
     * @param to The destination address of the token to being transferred
     * @param ids The list of IDs of the token being transferred
     * @param amounts The list of amount of tokens to being transferred
     * @param data Additional data with no specified format
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        uint256 totalSuply = totalSupply();
        //console.log("mintBatch [%s]", totalSuply);
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; ++i) {
            // TODO: overflow?
            totalAmount += amounts[i];
            //console.log("ammount [%s]", amounts[i]);
        }
        //console.log("[%s] > [%s]", totalSuply + totalAmount, _totalEmittion);
        if (totalSuply + totalAmount > _totalEmittion) {
            // TODO: overflow?
            revert Lazy1155__TokenCapExceeded();
        }
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public override(ILazy1155, ERC1155) {
        super.safeTransferFrom(from, to, id, value, data);
    }

    function balanceOf(address account, uint256 id) public view override(ILazy1155, ERC1155) returns (uint256) {
        return super.balanceOf(account, id);
    }

    function isApprovedForAll(address owner, address operator) public view override(ILazy1155, ERC1155) returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }
}
