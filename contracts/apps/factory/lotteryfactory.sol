// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface INFTHandler {
    function transferNFT(address from, address to, uint256 tokenId) external;

    function getMaxSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

abstract contract LotteryFactory {
    constructor() {}
}
