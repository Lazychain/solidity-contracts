// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";

contract Lazy721A is ERC721A, Ownable {
    uint16 private _tokenCap;
    string public baseURI;

    error LazyNFTTokenCapExceeded();
    error LazyNFTQuantityMustBeGreaterThanCero();

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
    function mint(uint256 quantity) external onlyOwner {
        if (quantity == 0) revert LazyNFTQuantityMustBeGreaterThanCero();
        if (quantity > _tokenCap) revert LazyNFTTokenCapExceeded();
        _mint(msg.sender, quantity);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }
}
