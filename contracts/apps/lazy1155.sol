// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { ERC1155Pausable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import { Strings } from "../utils/Strings.sol";
import { Integers } from "../utils/Integers.sol";

contract Lazy1155 is ERC1155, Ownable, ERC1155Pausable, ERC1155Burnable, ERC1155Supply {
    uint256 public constant INITIAL_ID = 0;
    uint16 private _tokenCap;

    error Lazy1155__TokenIdDoesntExist(); // TODO: Look for how to check Ids in batch
    error Lazy1155__TokenCapExceeded();
    error Lazy1155__QuantityMustBeGreaterThanCero();
    error Lazy1155__NoBalanceForTokenId();

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    constructor(uint16 tokenCap, string memory _uri, uint256 quantity) ERC1155(_uri) Ownable(msg.sender) {
        _tokenCap = tokenCap;
        // Creates amount tokens of token type id, and assigns them to account.
        if (quantity > 0) {
            mint(msg.sender, INITIAL_ID, quantity, ""); // Token ID 0, quantity 100
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function tokenURI(address from, uint256 tokenId) public view returns (string memory) {
        if (!tokenExists(tokenId)) revert Lazy1155__TokenIdDoesntExist();
        if (!isOwnerOfToken(from, tokenId)) revert Lazy1155__NoBalanceForTokenId();

        string memory uri = Strings.replace(super.uri(tokenId), "{id}", Integers.toString(tokenId), 1);
        //console.log("[%s]", uri);
        return uri;
    }

    function isOwnerOfToken(address _owner, uint256 _tokenId) public view returns (bool) {
        uint256 balance = super.balanceOf(_owner, _tokenId);
        return balance > 0;
    }

    function tokenExists(uint256 _tokenId) public view returns (bool) {
        // Check the total supply of the token ID
        uint256 totalSupply = totalSupply(_tokenId);
        return totalSupply > 0;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        uint256 totalSuply = totalSupply();
        // TODO: overflow?
        if (totalSuply + amount > _tokenCap) {
            revert Lazy1155__TokenCapExceeded();
        }
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        uint256 totalSuply = totalSupply();
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            // TODO: overflow?
            totalAmount += amounts[i];
        }
        if (totalSuply + totalAmount > _tokenCap) {
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
}
