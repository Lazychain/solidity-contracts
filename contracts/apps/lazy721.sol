// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Pausable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

import { Integers } from "../utils/Integers.sol";

contract Lazy721 is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Pausable, Ownable, ERC721Burnable {
    uint256 private _nextTokenId;
    uint256 private _tokenCap;
    string private _uri;

    error Lazy721__TokenIdDoesntExist();
    error Lazy721__TokenCapExceeded();
    error Lazy721__QuantityMustBeGreaterThanCero();

    constructor(
        string memory name,
        string memory symbol,
        uint256 tokenCap,
        string memory uri
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _tokenCap = tokenCap;
        _uri = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        if (_nextTokenId >= _tokenCap) revert Lazy721__TokenCapExceeded();
        uint256 tokenId = _nextTokenId++;
        string memory uri = tokenURI(tokenId);
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     _requireOwned(tokenId);
    //     return string(abi.encodePacked(_baseURI(), Integers.toString(tokenId), ".json"));
    // }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (tokenId > _nextTokenId) revert Lazy721__TokenIdDoesntExist();
        return string(abi.encodePacked(_baseURI(), Integers.toString(tokenId), ".json"));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
