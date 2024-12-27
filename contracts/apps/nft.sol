// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Integers } from "../utils/Integers.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract LazyNFT is ERC721, ERC721Enumerable, Ownable {
    uint16 private constant _TOKEN_CAP = 4;
    uint256 private _nextTokenId = 0;

    error LazyNFT__TokenCapExceeded();

    constructor(
        address initialOwner,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(initialOwner) {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://lazyhash/";
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function safeMint(address to) public onlyOwner {
        if (_nextTokenId >= _TOKEN_CAP) revert LazyNFT__TokenCapExceeded();
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(_baseURI(), Integers.toString(tokenId), ".json"));
    }
}
