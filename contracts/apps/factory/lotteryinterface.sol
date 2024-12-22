// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { NFTLottery } from "../lottery.sol";

interface INFTHandler {
    function transferNFT(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) external;

    function getMaxSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address user, uint256 tokenId) external view returns (uint256);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface INFTLotteryFactory {
    function createLottery(
        address nftContract,
        uint256 fee,
        address fairyringContract,
        address decrypter
    ) external returns (NFTLottery);
}
