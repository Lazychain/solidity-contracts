// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "../../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "../../../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "../../../node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ReentrancyGuard } from "../../../node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ERC721Holder } from "../../../node_modules/@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "../../../node_modules/@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract NFTStaking is ERC721Holder, ERC1155Holder, Ownable, ReentrancyGuard {
    ////////////
    // ERRORS //
    ////////////
    error NFTStaking__UnAuthorized();
    error NFTStaking__WrongDataFilled();
    error NFTStaking__InsufficientBalance();

    struct StakeInfo {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 timeStamp;
        bool isERC1155;
    }

    mapping(address => StakeInfo[]) public stakes; // Staker Address => Stake Info

    ////////////
    // EVENTS //
    ////////////
    event Staked(address indexed staker, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);
    event UnStaked(address indexed staker, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function stakeERC721(address tokenAddress, uint256 tokenId) external nonReentrant {
        if (tokenAddress == address(0)) {
            revert NFTStaking__WrongDataFilled();
        }

        IERC721 nft = IERC721(tokenAddress);

        if (nft.ownerOf(tokenId) != msg.sender) {
            revert NFTStaking__UnAuthorized();
        }

        // Transfer nft to contract
        nft.safeTransferFrom(msg.sender, address(this), tokenId, "");

        stakes[msg.sender].push(
            StakeInfo({
                tokenAddress: tokenAddress,
                tokenId: tokenId,
                amount: 1,
                timeStamp: block.timestamp,
                isERC1155: false
            })
        );

        emit Staked(msg.sender, tokenAddress, tokenId, 1);
    }

    function stakeERC1155(address tokenAddress, uint256 tokenId, uint256 amount) external nonReentrant {
        if (tokenAddress == address(0)) {
            revert NFTStaking__WrongDataFilled();
        }

        IERC1155 nft = IERC1155(tokenAddress);

        if (nft.balanceOf(msg.sender, tokenId) < amount) {
            revert NFTStaking__InsufficientBalance();
        }

        nft.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        stakes[msg.sender].push(
            StakeInfo({
                tokenAddress: tokenAddress,
                tokenId: tokenId,
                amount: amount,
                timeStamp: block.timestamp,
                isERC1155: true
            })
        );

        emit Staked(msg.sender, tokenAddress, tokenId, amount);
    }

    function unStake(uint256 index) external {}
}
