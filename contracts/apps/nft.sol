// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Integers } from "../utils/Integers.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract LazyNFT is ERC721A, Ownable {
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
        if (quantity >= _tokenCap) revert LazyNFTTokenCapExceeded();
        _mint(msg.sender, quantity);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    // function _ownerOf(uint256 tokenId) internal view virtual override(ERC721, ERC721Consecutive) returns (address) {
    //     return super._ownerOf(tokenId); // ERC721
    // }

    // function _update(
    //     address to,
    //     uint256 tokenId,
    //     address auth
    // ) internal virtual override(ERC721, ERC721Enumerable, ERC721Consecutive) returns (address) {
    //     return super._update(to, tokenId, auth); // ERC721
    // }

    // function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
    //     super._increaseBalance(account, amount); // ERC721
    // }

    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    //     return super.supportsInterface(interfaceId); // ERC721
    // }
}
