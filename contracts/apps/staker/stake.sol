// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Lazy721 } from "../lazy721.sol";
import { Lazy721A } from "../lazy721a.sol";
import { Lazy1155 } from "../lazy1155.sol";
import { ILazy1155 } from "../../interfaces/token/ILazy1155.sol";
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
    error NFTStaking__NFTNotEligible();
    error NFTStaking__WrongDataFilled();
    error NFTStaking__AlreadyUnstaked();
    error NFTStaking__InvalidIPFSHash();
    error NFTStaking__NFTAlreadyStaked();
    error NFTStaking__FeeTransferFailed();
    error NFTStaking__UnsupportedNFTType();
    error NFTStaking__InsufficientBalance();
    error NFTStaking__InvalidStakingPeriod();
    error NFTStaking__RewardsNotConfigured();
    error NFTStaking__StakingPeriodNotEnded();
    error NFTStaking__MaxStakingLimitReached();
    error NFTStaking__InsufficientStakingFee();
    error NFTStaking__InsufficientUnstakingFee();
    error NFTStaking__RewardDistributionFailed();

    ////////////
    // EVENTS //
    ////////////
    event IPFSHashAdded(string ipfsHash);
    event MaxStakesUpdated(uint256 newMax);
    event StakingFeeUpdated(uint256 newFee);
    event RewardRateUpdated(uint256 newRate);
    event UnstakingFeeUpdated(uint256 newFee);
    event StakingPeriodUpdated(uint256 newPeriod);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event RewardsDistributed(address indexed staker, uint256 amount);
    event CollectionWhitelisted(address indexed collection, bool status);
    event UnstakingInitiated(address indexed staker, uint256 indexed tokenId);
    event Staked(address indexed staker, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);
    event UnStaked(address indexed staker, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);

    /**
     * @dev Enum to identify different token standards
     */
    enum TokenType {
        ERC721,
        ERC1155
    }
    enum StakingStatus {
        STAKED,
        UNSTAKING_INITIATED,
        UNSTAKED
    }

    struct StakeInfo {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 startBlock; // Instead of timeStamp
        uint256 lastRewardBlock;
        bool isERC1155;
        StakingStatus status;
        uint256 accumulatedRewards;
        // string ipfsHash;
    }

    uint256 public stakingFee;
    uint256 public rewardRate; // Rewards/block
    uint256 public unstakingFee;
    uint256 public maxStakesPerUser;
    uint256 public stakingPeriodInBlocks; // minimum block passed
    mapping(address => StakeInfo[]) public stakes; // Staker Address => Stake Info
    mapping(string => bool) public validIPFSHashes;
    mapping(address => uint256) public stakingCount;
    mapping(address => bool) public rewardsDistributed;
    mapping(address => bool) public whitelistedCollections;

    /////////////////
    // CONSTRUCTOR //
    /////////////////
    constructor(
        uint256 _initialStakingPeriod,
        uint256 _stakingFee,
        uint256 _unstakingFee,
        uint256 _rewardRate,
        uint256 _maxStakesPerUser
    ) Ownable(msg.sender) {
        if (_initialStakingPeriod == 0) revert NFTStaking__InvalidStakingPeriod();
        stakingPeriodInBlocks = _initialStakingPeriod;
        stakingFee = _stakingFee;
        unstakingFee = _unstakingFee;
        rewardRate = _rewardRate;
        maxStakesPerUser = _maxStakesPerUser;
    }

    //////////////
    // FUNCTION //
    //////////////

    /**
     * @dev Internal function to handle staking of both ERC721 and ERC1155 tokens
     * @param tokenAddress Address of the token contract
     * @param tokenId ID of the token to stake
     * @param amount Amount of tokens to stake (1 for ERC721)
     * @param tokenType Type of token being staked (ERC721 or ERC1155)
     */
    function _stake(address tokenAddress, uint256 tokenId, uint256 amount, TokenType tokenType) internal {
        if (msg.value != stakingFee) {
            revert NFTStaking__InsufficientStakingFee();
        }

        bool isERC1155 = tokenType == TokenType.ERC1155;

        if (!verifyNFTEligibility(tokenAddress, tokenId, isERC1155)) {
            revert NFTStaking__NFTNotEligible();
        }

        if (!verifyNFTOwnership(tokenAddress, msg.sender, tokenId, isERC1155, amount)) {
            revert NFTStaking__UnAuthorized();
        }

        if (tokenAddress == address(0)) {
            revert NFTStaking__WrongDataFilled();
        }

        if (stakingCount[msg.sender] >= maxStakesPerUser) {
            revert NFTStaking__MaxStakingLimitReached();
        }

        // Interface compliance check
        if (tokenType == TokenType.ERC721) {
            if (!IERC721(tokenAddress).supportsInterface(type(IERC721).interfaceId)) {
                revert NFTStaking__WrongDataFilled();
            }
        } else {
            if (!IERC1155(tokenAddress).supportsInterface(type(IERC1155).interfaceId)) {
                revert NFTStaking__WrongDataFilled();
            }
        }

        // Transfer tokens
        // nonreentrant is for this part
        if (tokenType == TokenType.ERC721) {
            IERC721 nft = IERC721(tokenAddress);
            nft.safeTransferFrom(msg.sender, address(this), tokenId, "");
        } else {
            IERC1155 nft = IERC1155(tokenAddress);
            nft.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        }

        stakingCount[msg.sender]++;

        // Store stake info
        stakes[msg.sender].push(
            StakeInfo({
                tokenAddress: tokenAddress,
                tokenId: tokenId,
                amount: amount,
                startBlock: block.number,
                lastRewardBlock: block.number,
                isERC1155: tokenType == TokenType.ERC1155,
                status: StakingStatus.STAKED,
                accumulatedRewards: 0
            })
        );

        emit Staked(msg.sender, tokenAddress, tokenId, amount);
    }

    /**
     * @notice Stakes an ERC721 token
     * @param tokenAddress Address of the ERC721 contract
     * @param tokenId ID of the token to stake
     * @dev Ensures the token is ERC721 compliant and caller is the owner
     */
    function stakeERC721(address tokenAddress, uint256 tokenId) external payable nonReentrant {
        _stake(tokenAddress, tokenId, 1, TokenType.ERC721);
    }

    /**
     * @notice Stakes ERC1155 tokens
     * @param tokenAddress Address of the ERC1155 contract
     * @param tokenId ID of the tokens to stake
     * @param amount Amount of tokens to stake
     * @dev Ensures the token is ERC1155 compliant and caller has sufficient balance
     */
    function stakeERC1155(address tokenAddress, uint256 tokenId, uint256 amount) external payable nonReentrant {
        if (amount < 0) {
            revert NFTStaking__WrongDataFilled();
        }
        _stake(tokenAddress, tokenId, amount, TokenType.ERC1155);
    }

    /**
     * @dev Withdraws staked tokens
     * @param index The index of the stake in the user's stakes array
     */
    function unStake(uint256 index) external payable nonReentrant {
        if (msg.value != unstakingFee) {
            revert NFTStaking__InsufficientUnstakingFee();
        }

        if (stakes[msg.sender].length <= index) {
            revert NFTStaking__WrongDataFilled();
        }

        StakeInfo memory stake = stakes[msg.sender][index];

        if (stake.status != StakingStatus.STAKED) {
            revert NFTStaking__AlreadyUnstaked();
        }

        if (block.number < stake.startBlock + stakingPeriodInBlocks) {
            revert NFTStaking__StakingPeriodNotEnded();
        }

        // Calculate rewards before status change
        uint256 rewards = calculateRewards(stake.lastRewardBlock, block.number);
        stake.accumulatedRewards = rewards;
        stake.accumulatedRewards = rewards;

        stake.status = StakingStatus.UNSTAKING_INITIATED;
        emit UnstakingInitiated(msg.sender, stake.tokenId);

        if (stake.isERC1155) {
            IERC1155(stake.tokenAddress).safeTransferFrom(address(this), msg.sender, stake.tokenId, stake.amount, "");
        } else {
            IERC721(stake.tokenAddress).safeTransferFrom(address(this), msg.sender, stake.tokenId, "");
        }

        // Distribute rewards
        // nonreentrant is for this part
        if (rewards > 0) {
            (bool success, ) = msg.sender.call{ value: rewards }("");
            if (!success) {
                stake.status = StakingStatus.STAKED; // Revert status if reward distribution fails
                revert NFTStaking__RewardDistributionFailed();
            }
            rewardsDistributed[msg.sender] = true;
            emit RewardsDistributed(msg.sender, rewards);
        }

        // // replace current index -> Last element >>> then pop it.
        // stakes[msg.sender][index] = stakes[msg.sender][stakes[msg.sender].length - 1];
        // stakes[msg.sender].pop();
        stake.status = StakingStatus.UNSTAKED;

        emit UnStaked(msg.sender, stake.tokenAddress, stake.tokenId, stake.amount);
    }

    /**
     * @notice Adds or removes a collection from the whitelist
     * @param collection Address of the NFT collection
     * @param status Whitelist status to set
     * @dev Only callable by owner
     */
    function setCollectionWhitelist(address collection, bool status) external onlyOwner {
        whitelistedCollections[collection] = status;
        emit CollectionWhitelisted(collection, status);
    }

    /**
     * @notice Adds valid IPFS hashes for NFT metadata
     * @param ipfsHash IPFS hash to validate
     * @dev Only callable by owner
     */
    function addValidIPFSHash(string memory ipfsHash) external onlyOwner {
        validIPFSHashes[ipfsHash] = true;
        emit IPFSHashAdded(ipfsHash);
    }

    /**
     * @notice Updates maximum stakes allowed per user
     * @param _maxStakes New maximum stakes limit
     * @dev Only callable by owner
     */
    function setMaxStakesPerUser(uint256 _maxStakes) external onlyOwner {
        maxStakesPerUser = _maxStakes;
        emit MaxStakesUpdated(_maxStakes);
    }

    /**
     * @notice Sets the reward rate for staking
     * @param _newRate New reward rate per second in wei
     * @dev Only callable by owner, updates reward calculation rate
     * @custom:security non-reentrant
     */
    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
        emit RewardRateUpdated(_newRate);
    }

    /**
     * @notice Calculates rewards based on staking duration
     * @param startBlock block number at the time of staking
     * @param currentBlock current block in blockchain
     * @return uint256 Amount of rewards in wei
     * @dev Reverts if reward rate is not configured
     */
    function calculateRewards(uint256 startBlock, uint256 currentBlock) public view returns (uint256) {
        uint256 blocksPassed = currentBlock - startBlock;
        return blocksPassed * rewardRate;
    }

    /**
     * @notice Updates the staking fee
     * @param _newFee New fee amount in native token
     * @dev Only callable by owner
     */
    function setStakingFee(uint256 _newFee) external onlyOwner {
        stakingFee = _newFee;
        emit StakingFeeUpdated(_newFee);
    }

    /**
     * @notice Updates the unstaking fee
     * @param _newFee New fee amount in native token
     * @dev Only callable by owner
     */
    function setUnstakingFee(uint256 _newFee) external onlyOwner {
        unstakingFee = _newFee;
        emit UnstakingFeeUpdated(_newFee);
    }

    /**
     * @notice Withdraws accumulated fees to owner
     * @dev Only callable by owner
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{ value: balance }("");
        if (!success) revert NFTStaking__FeeTransferFailed();
        emit FeesWithdrawn(msg.sender, balance);
    }

    /**
     * @notice Updates the staking period
     * @param _stakingDays New staking period in seconds
     * @dev Only callable by owner
     */
    function setStakingPeriod(uint256 _stakingDays) external onlyOwner {
        if (_stakingDays == 0) revert NFTStaking__InvalidStakingPeriod();
        stakingPeriodInBlocks = _stakingDays;
        emit StakingPeriodUpdated(stakingPeriodInBlocks);
    }

    /**
     * @notice Verifies if an NFT is eligible for staking
     * @param tokenAddress The address of the NFT contract
     * @param tokenId The ID of the NFT
     * @param isERC1155 Whether the NFT is an ERC1155 token
     * @return bool True if the NFT is eligible for staking, false otherwise
     */
    function verifyNFTEligibility(address tokenAddress, uint256 tokenId, bool isERC1155) public view returns (bool) {
        if (isERC1155) {
            try ILazy1155(tokenAddress).tokenExists(tokenId) returns (bool exists) {
                return exists;
            } catch {
                return false;
            }
        } else {
            // Try Lazy721 first
            try Lazy721(tokenAddress).tokenURI(tokenId) returns (string memory uri) {
                return bytes(uri).length > 0;
            } catch {
                // Try Lazy721A if Lazy721 fails
                try Lazy721A(tokenAddress).tokenURI(tokenId) returns (string memory uri) {
                    return bytes(uri).length > 0;
                } catch {
                    return false;
                }
            }
        }
    }

    /**
     * @notice Verifies the ownership of an NFT
     * @param tokenAddress The address of the NFT contract
     * @param owner The address of the claimed owner
     * @param tokenId The ID of the NFT
     * @param isERC1155 Whether the NFT is an ERC1155 token
     * @param amount The amount of tokens being verified (relevant for ERC1155)
     * @return bool True if the owner holds the specified token, false otherwise
     */
    function verifyNFTOwnership(
        address tokenAddress,
        address owner,
        uint256 tokenId,
        bool isERC1155,
        uint256 amount
    ) public view returns (bool) {
        if (isERC1155) {
            try ILazy1155(tokenAddress).isOwnerOfToken(owner, tokenId) returns (bool isOwner) {
                if (!isOwner) return false;
                return ILazy1155(tokenAddress).balanceOf(owner, tokenId) >= amount;
            } catch {
                return false;
            }
        } else {
            try Lazy721(tokenAddress).ownerOf(tokenId) returns (address tokenOwner) {
                return tokenOwner == owner;
            } catch {
                try Lazy721A(tokenAddress).ownerOf(tokenId) returns (address tokenOwner) {
                    return tokenOwner == owner;
                } catch {
                    return false;
                }
            }
        }
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
     * @notice Retrieves the status of a specific stake
     * @param staker The address of the staker
     * @param index The index of the stake in the user's stakes array
     * @return StakingStatus The current status of the stake (STAKED, UNSTAKING_INITIATED, or UNSTAKED)
     * @dev Reverts if the index is invalid
     */
    function getStakeStatus(address staker, uint256 index) external view returns (StakingStatus) {
        if (stakes[staker].length <= index) revert NFTStaking__WrongDataFilled();
        return stakes[staker][index].status;
    }

    /**
     * @notice Gets the staking duration for a specific stake
     * @param staker The address of the staker
     * @param index The index of the stake in the user's stakes array
     * @return uint256 The duration of the stake in blocks
     * @dev Reverts if the index is invalid
     */
    function getStakeDuration(address staker, uint256 index) external view returns (uint256) {
        if (stakes[msg.sender].length <= index) {
            revert NFTStaking__WrongDataFilled();
        }
        // Calculate duration in blocks
        return block.number - stakes[staker][index].startBlock;
    }

    /**
     * @notice Gets unclaimed rewards for a specific stake
     * @param staker Address of the staker
     * @param index Index of the stake
     * @return uint256 Amount of pending rewards in wei
     * @dev Returns 0 if stake is not in STAKED status
     */
    function getPendingRewards(address staker, uint256 index) external view returns (uint256) {
        if (stakes[staker].length <= index) revert NFTStaking__WrongDataFilled();
        StakeInfo memory stake = stakes[staker][index];
        if (stake.status != StakingStatus.STAKED) return 0;
        return calculateRewards(stake.lastRewardBlock, block.number);
    }

    /**
     * @notice Retrieves the remaining blocks for a specific stake
     * @param staker The address of the staker
     * @param index The index of the stake in the user's stakes array
     * @return uint256 The number of blocks remaining until the stake period ends
     * @dev Returns 0 if the stake period has already ended
     */
    function getRemainingBlocks(address staker, uint256 index) external view returns (uint256) {
        if (stakes[staker].length <= index) revert NFTStaking__WrongDataFilled();
        StakeInfo memory stake = stakes[staker][index];
        uint256 endBlock = stake.startBlock + stakingPeriodInBlocks;
        if (block.number >= endBlock) return 0;
        return endBlock - block.number;
    }
}
