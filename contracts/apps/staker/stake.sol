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

    ////////////
    // EVENTS //
    ////////////
    event Staked(address indexed staker, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);
    event UnStaked(address indexed staker, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);

    struct StakeInfo {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 timeStamp;
        bool isERC1155;
    }

    mapping(address => StakeInfo[]) public stakes; // Staker Address => Stake Info

    constructor() Ownable(msg.sender) {}

    //////////////
    // FUNCTION //
    //////////////

    /**
     * @dev Stakes an ERC721 token
     * @param tokenAddress The address of the ERC721 contract
     * @param tokenId The ID of the token to stake
     */
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

    /**
     * @dev Stakes ERC1155 tokens
     * @param tokenAddress The address of the ERC1155 contract
     * @param tokenId The ID of the tokens to stake
     * @param amount The amount of tokens to stake
     */
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

    /**
     * @dev Withdraws staked tokens
     * @param index The index of the stake in the user's stakes array
     */
    function unStake(uint256 index) external {
        if (stakes[msg.sender].length <= index) {
            revert NFTStaking__WrongDataFilled();
        }

        StakeInfo memory stake = stakes[msg.sender][index];

        if (stake.isERC1155) {
            IERC1155(stake.tokenAddress).safeTransferFrom(address(this), msg.sender, stake.tokenId, stake.amount, "");
        } else {
            IERC721(stake.tokenAddress).safeTransferFrom(address(this), msg.sender, stake.tokenId, "");
        }

        // replace current index -> Last element >>> then pop it.
        stakes[msg.sender][index] = stakes[msg.sender][stakes[msg.sender].length - 1];
        stakes[msg.sender].pop();

        emit UnStaked(msg.sender, stake.tokenAddress, stake.tokenId, stake.amount);
    }

    /**
     * @dev Gets all stakes for a user
     * @param staker The address of the staker
     * @return StakeInfo[] Array of stake information
     */
    function getStakes(address staker) external view returns (StakeInfo[] memory) {
        return stakes[staker];
    }

    /**
     * @dev Gets the stake duration for a specific stake
     * @param staker The address of the staker
     * @param index The index of the stake
     * @return uint256 The duration of the stake in seconds
     */
    function getStakeDuration(address staker, uint256 index) external view returns (uint256) {
        if (stakes[msg.sender].length <= index) {
            revert NFTStaking__WrongDataFilled();
        }
        return block.timestamp - stakes[staker][index].timeStamp;
    }
}
