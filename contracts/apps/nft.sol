// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Consecutive } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Consecutive.sol";
import { Integers } from "../utils/Integers.sol";

contract LazyNFT is ERC721, ERC721Enumerable, Ownable, ERC721Consecutive {
    uint16 private _tokenCap;
    uint256 private _nextTokenId = 0;

    error LazyNFTTokenCapExceeded();

    constructor(
        address initialOwner,
        string memory _name,
        string memory _symbol,
        uint16 tokenCap
    ) ERC721(_name, _symbol) Ownable(initialOwner) {
        _tokenCap = tokenCap;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://lazyhash/";
    }

    function _ownerOf(uint256 tokenId) internal view virtual override(ERC721, ERC721Consecutive) returns (address) {
        return super._ownerOf(tokenId); // ERC721
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Consecutive) returns (address) {
        return super._update(to, tokenId, auth); // ERC721
    }

    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount); // ERC721
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId); // ERC721
    }

    function safeMint(address to) public onlyOwner {
        if (_nextTokenId >= _tokenCap) revert LazyNFTTokenCapExceeded();
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(_baseURI(), Integers.toString(tokenId), ".json"));
    }
}
