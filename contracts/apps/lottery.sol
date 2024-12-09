// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/IERC721A.sol";
import { PriorityQueue } from "../utils/PriorityQueue.sol";
import { LazyNFT } from "./nft.sol";

interface IFairyringContract {
    function latestRandomness() external view returns (bytes32, uint256);
    function getRandomnessByHeight(uint256 height) external view returns (uint256);
}

interface IDecrypter {
    function decrypt(uint8[] memory c, uint8[] memory skbytes) external returns (uint8[] memory);
}

/**
 * @title Simple NFT Lottery App
 * @author Lazychain
 * @notice Contract that allow simple user interaction with a lottery App.
 * @dev FLOW OF CONTRACT:
 * Deploy Contract: Deploys Lottery on the Forma testnet.
 * Submit draw(gues_number) for nft lottery: User sends a guess number to the contract.
 * The contract get a random_number from Fairblock Technologies and compare with the guess_number
 * and determine if win or not.
 * If wyn, it transfer ownership of a nft from a list
 */
contract NFTLottery is Ownable {
    event LotteryInitialized(address decrypter, uint256 fee);
    event RewardWithdrawn(address by, uint256 amount);
    event LotteryDrawn(address indexed player, bool result, uint256 nftId, uint256 totalDraws);
    event CampaignStatusChanged(bool isFinalized);
    event PlayerNameSet(address indexed player, string name);

    error NFTContractDoesNotSupportTotalSupply();
    error NFTLotteryOnlyOwnerCanWithdraw();
    error NFTLotteryOnlyOwnerCanFinalizeCampaign();
    error NFTLotteryOnlyOwnerCanStartCampaign();
    error NFTLotteryCampaignOver();
    error NFTLotteryInsufficientFundsSent();
    error NFTLotteryGuessValueOutOfRange();
    error NFTLotteryTooFewNFTs();
    error NFTLotteryTooFewPooPoints();
    error NFTLotteryInternalError();

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);
    string private constant _VERSION = "1.00"; // Private as to not clutter the ABI

    /// @notice Represents a user name space entry and data
    struct UserNameSpace {
        uint256 drawsCount; // How many times the user have draw
        uint256 winCount; // How many times the user have win
        uint256 height; // Last user height registered to avoid multiple draw calls on the same height.
        uint256 pooPoints; // Points accumulated by the user
    }

    mapping(address => UserNameSpace) public userDetails; //other details of users

    /// @notice Fee in TIA
    uint256 public fee = 0.01 ether;

    /// @notice Total number of draws that have occurred
    uint256 public totalDraws = 0;

    /// @notice Reference to an external decryption contract
    IDecrypter public decrypterContract;

    /// @notice This will help with generating random numbers
    IFairyringContract public fairyringContract;

    /// @notice This will maintain the NFTs
    IERC721A public nftContract;

    /// @notice Indicates if the campaign is live or not.
    bool public isCampaignOpen = false;

    /// @notice Maximum number of NFTs minted 1% prob Guess == Random
    uint256 public maxNftsCase1 = 1;

    /// @notice Pointer to the next NFT ID Case 1 NFT Range: 0 to 999 (maxNftsCase1-1)
    uint256 public nextNftIdCase1 = 0;

    /// @notice Maximum number of NFTs minted 2% prob distance between Guess and Random < 1
    uint256 public maxNftsCase2 = 2;

    /// @notice Pointer to the next NFT ID Case 2 NFT Range: 1000 to 2999 (maxNftsCase1+maxNftsCase2-1)
    uint256 public nextNftIdCase2 = 0;

    /// @notice Maximum number of NFTs minted 3% prob distance between Guess and Random < 2
    uint256 public maxNftsCase3 = 4;

    /// @notice Pointer to the next NFT ID Case 3 NFT Range: 3000 to 6999 (maxNftsCase1+maxNftsCase2+maxNftsCase3-1)
    uint256 public nextNftIdCase3 = 0;

    /// @notice Maximum number of NFTs minted 4% prob distance between Guess and Random < 3
    uint256 public maxNftsCase4 = 8;

    /// @notice Pointer to the next NFT ID Case 4 NFT  Range: 7000 to 14999 (maxNftsCase1+maxNftsCase2+maxNftsCase3+maxNftsCase4-1)
    uint256 public nextNftIdCase4 = 0;

    /// @notice Maximum number of NFTs minted
    uint256 public maxNfts = 16;

    /**
     * @notice Initializes the lottery with a decryption contract and a fee.
     * @param _decrypter Address of the decryption contract
     * @param _fee The fee required to submit a draw
     * @param _fairyringContract Address of the fairy ring contract
     * @param _nftContract Address of the contract maintaining the NFTs
     */
    constructor(
        address _decrypter,
        uint256 _fee,
        address _fairyringContract,
        address _nftContract,
        uint128 factor
    ) Ownable(msg.sender) {
        nftContract = LazyNFT(_nftContract);
        if (_getMaxNFTs() < 1) revert NFTLotteryTooFewNFTs();

        decrypterContract = IDecrypter(_decrypter);
        fee = _fee;
        fairyringContract = IFairyringContract(_fairyringContract);

        maxNftsCase1 = 1 * factor;
        maxNftsCase2 = 2 * factor;
        maxNftsCase3 = 4 * factor;
        maxNftsCase4 = 8 * factor;

        emit LotteryInitialized(_decrypter, _fee);
    }

    // EXECUTE:OWNER:Open or close campaign
    function setCampaign(bool _isCampaignOpen) external onlyOwner {
        isCampaignOpen = _isCampaignOpen;
        emit CampaignStatusChanged(_isCampaignOpen);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        emit RewardWithdrawn(msg.sender, balance);
        Address.sendValue(payable(msg.sender), balance);
    }

    // EXECUTE:ANYONE:draw(guess: number) -> Result(draw:boolean, error)
    // code: uint(FairyringContract.latestRandomness()) % 20
    // check if generated random number == guess number
    // true:
    //  Increase total_draws
    //  Transfer an NFT ownership to info.address.
    //  Update lucky_10_ranking{}.
    //  get player_name from addr map
    //  update player_name: count if new record.
    //  Send response
    //      { result: true, "ipfs_hash/id", total_draws }
    //  Emit Winner Event
    // false:
    //  Increase total_draws
    //  Send Response:
    //      { result: false, total_draws }
    //      Emit Lose Event
    function draw(uint256 userGuess) public payable noContractCall openCampaign fees returns (uint256) {
        bool isWinner = false;
        uint256 nftId = 15001; // Ensure that this nft id doesnt exist
        // check pre-conditions
        if (userGuess > 100) revert NFTLotteryGuessValueOutOfRange();

        ++totalDraws;

        // check user pre-conditions
        UserNameSpace storage user = userDetails[msg.sender];

        // Only one draw call per height, to avoid bots calling
        // We dont thrown an error, we want the bots to spend as much as possible
        if (user.height >= block.number) {
            ++user.drawsCount;
            emit LotteryDrawn(msg.sender, isWinner, nftId, totalDraws);
            return nftId;
        } else {
            // update user height
            user.height = block.number;
        }

        (, uint256 randomValue) = fairyringContract.latestRandomness();
        uint256 normalizedGuess = userGuess % 100;
        uint256 normalizedRandom = randomValue % 100;

        // For this particular campaign will be 4 nfts types, each one with differents probabilities
        // 1:  1000 probability 1% _abs(userGuess - randomValue) = 0
        // 2:  2000 probability 2% _abs(userGuess - randomValue) = 1
        // 3:  4000 probability 4% _abs(userGuess - randomValue) = 2
        // 4:  8000 probability 8% _abs(userGuess - randomValue) = 3
        // T: 15000
        uint256 winner = _abs(normalizedGuess, normalizedRandom);

        ++user.drawsCount;

        ++user.pooPoints;

        if (winner < 4) {
            // Winner case
            isWinner = true;
            if (winner == 0) {
                nftId = nextNftIdCase1;
                ++nextNftIdCase1;
            } else if (winner == 1) {
                nftId = maxNftsCase1 + nextNftIdCase2;
                ++nextNftIdCase2;
            } else if (winner == 2) {
                nftId = maxNftsCase1 + maxNftsCase2 + nextNftIdCase3;
                ++nextNftIdCase4;
            } else if (winner == 3) {
                nftId = maxNftsCase1 + maxNftsCase2 + maxNftsCase3 + nextNftIdCase4;
                ++nextNftIdCase4;
            } else {
                revert NFTLotteryInternalError();
            }

            // Check if there are NFTs remaining
            if (nftId >= maxNfts) {
                revert NFTLotteryTooFewNFTs();
            }

            // Select and transfer a random NFT
            nftContract.transferFrom(address(this), msg.sender, nftId);
            ++user.winCount;

            // if (nextNftIdCase1 + nextNftIdCase2 + nextNftIdCase3 + nextNftIdCase4 >= maxNfts) {
            //     // End the campaign if all NFTs are used
            //     // TODO: here a user addr can call this? Make a test.
            //     finalizeCampaign();
            // }
        }

        emit LotteryDrawn(msg.sender, isWinner, nftId, totalDraws);
        userDetails[msg.sender] = user;

        return nftId;
    }

    function claimNFT() public payable openCampaign fees {
        UserNameSpace storage user = userDetails[msg.sender];

        // Check if the user has enough poo points
        if (user.pooPoints < 100) {
            revert NFTLotteryTooFewPooPoints();
        }

        // Check if there are NFTs remaining
        if (nextNftIdCase1 >= maxNfts) {
            revert NFTLotteryTooFewNFTs();
        }

        // Deduct 100 poo points
        user.pooPoints -= 100;
        userDetails[msg.sender] = user;

        // Transfer NFT to the user
        uint256 nftId = nextNftIdCase1;
        nftContract.transferFrom(address(this), msg.sender, nftId);
        ++nextNftIdCase1;
    }

    // QUERY:ANYONE:total_draws() -> Result(count: number)
    function points() external view returns (uint256) {
        UserNameSpace storage user = userDetails[msg.sender];
        return user.pooPoints;
    }

    // QUERY:ANYONE:total_draws() -> Result(count: number)
    function totaldraws() external view returns (uint256) {
        return totalDraws;
    }

    function campaign() external view returns (bool) {
        return isCampaignOpen;
    }

    /**
     * @dev Version of the rewards module.
     */
    function version() external pure returns (string memory) {
        return _VERSION;
    }

    function _getMaxNFTs() private view returns (uint256) {
        try nftContract.totalSupply() returns (uint256 totalSupply) {
            return totalSupply;
        } catch {
            revert NFTContractDoesNotSupportTotalSupply();
        }
    }

    modifier noContractCall() {
        // Check if a smart contract calling -> 0 if EOA, >0 if smart contract
        if (msg.sender.code.length > 0) {
            revert AddressEmptyCode(msg.sender);
        }
        _;
    }

    modifier openCampaign() {
        if (!isCampaignOpen) revert NFTLotteryCampaignOver();
        _;
    }

    modifier fees() {
        if (msg.value < fee) revert NFTLotteryInsufficientFundsSent();
        _;
    }

    function _abs(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return b - a;
        }
    }
}
