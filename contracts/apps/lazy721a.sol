// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
// import "hardhat/console.sol";

contract Lazy721A is ERC721A, Ownable {
    uint16 private _tokenCap;
    string public baseURI;

    error Lazy721A__TokenIdDoesntExist();
    error Lazy721A__TokenCapExceeded();
    error Lazy721A__QuantityMustBeGreaterThanCero();

    constructor(
        string memory name,
        string memory symbol,
        uint16 tokenCap,
        string memory uri
    ) ERC721A(name, symbol) Ownable(msg.sender) {
        _tokenCap = tokenCap;
        // TODO: check URI
        baseURI = uri;
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `owner`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function safeMint(address to, uint256 quantity) external onlyOwner {
        uint256 totalSuply = totalSupply();
        // console.log("TS[%s] Q[%s] C[%s]", totalSuply, quantity, _tokenCap);
        if (quantity == 0) revert Lazy721A__QuantityMustBeGreaterThanCero();
        if (totalSuply + quantity > _tokenCap) revert Lazy721A__TokenCapExceeded();
        _mint(to, quantity);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert Lazy721A__TokenIdDoesntExist();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }
}
