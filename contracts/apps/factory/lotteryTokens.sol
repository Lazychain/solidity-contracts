// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { INFTLotteryFactory, INFTHandler } from "./lotteryinterface.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract ERC721Handler is INFTHandler {
    IERC721Enumerable private nftContract;

    constructor(address _nftContract) {
        nftContract = IERC721Enumerable(_nftContract);
    }

    function transferNFT(address from, address to, uint256 tokenId) external {
        nftContract.transferFrom(from, to, tokenId);
    }

    function getMaxSupply() external view returns (uint256) {
        return nftContract.totalSupply();
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return nftContract.ownerOf(tokenId);
    }

    function balanceOf(address user) external view returns (uint256) {
        return nftContract.balanceOf(user);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return nftContract.isApprovedForAll(owner, operator);
    }
}

contract ERC1155Handler is INFTLotteryFactory {
    IERC1155 private nftContract;
    uint256 private immutable tokenId;
    uint256 private immutable maxSupply;

    constructor(address _nftContract, uint256 _tokenId, uint256 _maxSupply) {
        nftContract = IERC1155(_nftContract);
        tokenId = _tokenId;
        maxSupply = _maxSupply;
    }

    function transferNFT(address from, address to, uint256 tokenId) external {
        nftContract.safeTransferFrom(from, to, tokenId, 1, "");
    }

    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }

    function ownerOf(uint256) external view override returns (address) {
        // ERC1155 doesn't have direct ownerOf, would need additional tracking
        revert("Not supported for ERC1155");
    }

    function balanceOf(address user) external view returns (uint256) {
        return nftContract.balanceOf(user);
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return nftContract.isApprovedForAll(owner, operator);
    }
}
