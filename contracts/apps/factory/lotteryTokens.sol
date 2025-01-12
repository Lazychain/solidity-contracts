// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ILazy1155 } from "../../interfaces/token/ILazy1155.sol";
import { INFTLotteryFactory, INFTHandler } from "./lotteryinterface.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// import "hardhat/console.sol";

contract ERC721Handler is INFTHandler {
    IERC721Enumerable private nftContract;
    error LazyERC721__TokenIdDoesntExist();

    constructor(address _nftContract) {
        // console.log("ERC721Handler ctor");
        nftContract = IERC721Enumerable(_nftContract);
    }

    function transferNFT(address from, address to, uint256[] memory tokenIds, uint256[] memory) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nftContract.transferFrom(from, to, tokenIds[i]);
        }
    }

    function getMaxSupply() external view returns (uint256) {
        return nftContract.totalSupply();
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return nftContract.ownerOf(tokenId);
    }

    function balanceOf(address user, uint256) external view returns (uint256) {
        return nftContract.balanceOf(user);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return nftContract.isApprovedForAll(owner, operator);
    }

    function tokenExists(uint256) public pure returns (bool) {
        // console.log("ERC721 tokenExists.");
        // revert LazyERC721__TokenIdDoesntExist();
        return true; // TODO: here we need to check for token id
    }
}

contract ERC1155Handler is INFTHandler {
    ILazy1155 private nftContract;

    mapping(uint256 => uint256) private supply; // tokenId => maxSupply
    mapping(uint256 => uint256) private allocatedAmounts; // tokenId => amount
    uint256[] private supportedTokenIds; // track of all tokenIds

    error ERC1155Handler__NotSupported();

    constructor(address _nftContract, uint256[] memory _tokenIds, uint256[] memory _maxSupplies) {
        // console.log("ERC1155Handler ctor");
        require(_tokenIds.length == _maxSupplies.length, "Arrays length mismatch");
        nftContract = ILazy1155(_nftContract);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            supply[_tokenIds[i]] = _maxSupplies[i];
            supportedTokenIds.push(_tokenIds[i]);
        }
        // console.log("ERC1155Handler ctor finish");
    }

    function transferNFT(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) external {
        require(tokenIds.length == amounts.length, "Arrays length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(allocatedAmounts[tokenIds[i]] + amounts[i] <= supply[tokenIds[i]], "Exceeds max supply");

            nftContract.safeTransferFrom(from, to, tokenIds[i], amounts[i], "");
            allocatedAmounts[tokenIds[i]] += amounts[i];
        }
    }

    function getMaxSupply() external view override returns (uint256) {
        uint256 totalSupply = 0;
        for (uint256 i = 0; i < supportedTokenIds.length; i++) {
            totalSupply += supply[supportedTokenIds[i]];
        }
        return totalSupply;
    }

    function getTokenMaxSupply(uint256 tokenId) external view returns (uint256) {
        return supply[tokenId];
    }

    function getAllocatedAmount(uint256 tokenId) external view returns (uint256) {
        return allocatedAmounts[tokenId];
    }

    function ownerOf(uint256) external pure returns (address) {
        // ERC1155 doesn't have direct ownerOf, would need additional tracking
        revert ERC1155Handler__NotSupported();
    }

    function balanceOf(address user, uint256 tokenId) external view returns (uint256) {
        return nftContract.balanceOf(user, tokenId);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return nftContract.isApprovedForAll(owner, operator);
    }

    function tokenExists(uint256 _tokenId) public view returns (bool) {
        return nftContract.tokenExists(_tokenId);
    }
}
