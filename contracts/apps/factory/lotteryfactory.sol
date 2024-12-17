// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { INFTLotteryFactory, INFTHandler } from "./lotteryinterface.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract ERC721Handler is INFTHandler {
    IERC721Enumerable private nftContract;

    constructor(address _nftContract) {
        nftContract = IERC721Enumerable(_nftContract)
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

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return nftContract.isApprovedForAll(owner, operator);
    }
}