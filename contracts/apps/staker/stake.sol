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
    error NFTStaking__NFTNotEligible();
    error NFTStaking__WrongDataFilled();
    error NFTStaking__AlreadyUnstaked();
    error NFTStaking__InvalidIPFSHash();
    error NFTStaking__NFTAlreadyStaked();
    error NFTStaking__FeeTransferFailed();
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
        uint256 timeStamp;
        bool isERC1155;
        StakingStatus status;
        uint256 accumulatedRewards;
        string ipfsHash;
    }

    uint256 public stakingFee;
    uint256 public rewardRate; // Rewards/day ???
    uint256 public unstakingFee;
    uint256 public stakingPeriod;
    uint256 public maxStakesPerUser;
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
        stakingPeriod = _initialStakingPeriod;
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
    function _stake(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        TokenType tokenType,
        string memory ipfsHash
    ) internal {
        if (msg.value != stakingFee) {
            revert NFTStaking__InsufficientStakingFee();
        }

        if (!verifyNFTEligibility(tokenAddress, tokenId, ipfsHash)) {
            revert NFTStaking__NFTNotEligible();
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
        if (tokenType == TokenType.ERC721) {
            IERC721 nft = IERC721(tokenAddress);
            if (nft.ownerOf(tokenId) != msg.sender) {
                revert NFTStaking__UnAuthorized();
            }
            nft.safeTransferFrom(msg.sender, address(this), tokenId, "");
        } else {
            IERC1155 nft = IERC1155(tokenAddress);
            if (nft.balanceOf(msg.sender, tokenId) < amount) {
                revert NFTStaking__InsufficientBalance();
            }
            nft.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        }

        stakingCount[msg.sender]++;

        // Store stake info
        stakes[msg.sender].push(
            StakeInfo({
                tokenAddress: tokenAddress,
                tokenId: tokenId,
                amount: amount,
                timeStamp: block.timestamp,
                isERC1155: tokenType == TokenType.ERC1155,
                status: StakingStatus.STAKED,
                accumulatedRewards: 0,
                ipfsHash: ipfsHash
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
    function stakeERC721(address tokenAddress, uint256 tokenId, string memory ipfsHash) external payable nonReentrant {
        _stake(tokenAddress, tokenId, 1, TokenType.ERC721, ipfsHash);
    }

    /**
     * @notice Stakes ERC1155 tokens
     * @param tokenAddress Address of the ERC1155 contract
     * @param tokenId ID of the tokens to stake
     * @param amount Amount of tokens to stake
     * @dev Ensures the token is ERC1155 compliant and caller has sufficient balance
     */
    function stakeERC1155(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        string memory ipfsHash
    ) external payable nonReentrant {
        if (amount < 0) {
            revert NFTStaking__WrongDataFilled();
        }
        _stake(tokenAddress, tokenId, amount, TokenType.ERC1155, ipfsHash);
    }

    /**
     * @dev Withdraws staked tokens
     * @param index The index of the stake in the user's stakes array
     */
    function unStake(uint256 index) external payable {
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

        if (block.timestamp < stake.timeStamp + stakingPeriod) {
            revert NFTStaking__StakingPeriodNotEnded();
        }

        // Calculate rewards before status change
        uint256 stakeDuration = block.timestamp - stake.timeStamp;
        uint256 rewards = calculateRewards(stakeDuration);
        stake.accumulatedRewards = rewards;

        stake.status = StakingStatus.UNSTAKING_INITIATED;
        emit UnstakingInitiated(msg.sender, stake.tokenId);

        if (stake.isERC1155) {
            IERC1155(stake.tokenAddress).safeTransferFrom(address(this), msg.sender, stake.tokenId, stake.amount, "");
        } else {
            IERC721(stake.tokenAddress).safeTransferFrom(address(this), msg.sender, stake.tokenId, "");
        }

        // Distribute rewards
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

    function setCollectionWhitelist(address collection, bool status) external onlyOwner {
        whitelistedCollections[collection] = status;
        emit CollectionWhitelisted(collection, status);
    }

    function addValidIPFSHash(string memory ipfsHash) external onlyOwner {
        validIPFSHashes[ipfsHash] = true;
        emit IPFSHashAdded(ipfsHash);
    }

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
     * @param stakeDuration Duration of stake in seconds
     * @return uint256 Amount of rewards in wei
     * @dev Reverts if reward rate is not configured
     */
    function calculateRewards(uint256 stakeDuration) public view returns (uint256) {
        if (rewardRate == 0) revert NFTStaking__RewardsNotConfigured();
        return stakeDuration * rewardRate;
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
     * @param _newStakingPeriod New staking period in seconds
     * @dev Only callable by owner
     */
    function setStakingPeriod(uint256 _newStakingPeriod) external onlyOwner {
        if (_newStakingPeriod == 0) revert NFTStaking__InvalidStakingPeriod();
        stakingPeriod = _newStakingPeriod;
        emit StakingPeriodUpdated(_newStakingPeriod);
    }

    function verifyNFTEligibility(
        address tokenAddress,
        uint256 tokenId,
        string memory ipfsHash
    ) public view returns (bool) {
        if (!whitelistedCollections[tokenAddress]) return false;
        if (!validIPFSHashes[ipfsHash]) return false;

        // Check if NFT is already staked
        StakeInfo[] memory userStakes = stakes[msg.sender];
        for (uint i = 0; i < userStakes.length; i++) {
            if (
                userStakes[i].tokenAddress == tokenAddress &&
                userStakes[i].tokenId == tokenId &&
                userStakes[i].status == StakingStatus.STAKED
            ) {
                return false;
            }
        }

        return true;
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
     * @notice Retrieves the current status of a stake
     * @param staker Address of the staker
     * @param index Index of the stake in staker's array
     * @return StakingStatus Current status of the stake
     * @dev Returns one of: STAKED, UNSTAKING_INITIATED, UNSTAKED
     */
    function getStakeStatus(address staker, uint256 index) external view returns (StakingStatus) {
        if (stakes[staker].length <= index) revert NFTStaking__WrongDataFilled();
        return stakes[staker][index].status;
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
        uint256 stakeDuration = block.timestamp - stake.timeStamp;
        return calculateRewards(stakeDuration);
    }
}
