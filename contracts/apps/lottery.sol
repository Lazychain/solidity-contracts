// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { PriorityQueue } from "../utils/PriorityQueue.sol";

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
contract NFTLottery {
    event LotteryInitialized(address decrypter, uint256 fee);
    event RewardWithdrawn(address by, uint256 amount);
    event LotteryDrawn(address indexed player, bool result, uint256 totalDraws);
    event CampaignStatusChanged(bool isFinalized);
    event PlayerNameSet(address indexed player, string name);

    error NFTContractDoesNotSupportTotalSupply();
    error OnlyOwnerCanWithdraw();
    error OnlyOwnerCanFinalizeCampaign();
    error OnlyOwnerCanStartCampaign();
    error CampaignOver();
    error InsufficientFundsSent();
    error InvalidThreshold();
    error GuessValueOutOfRange();
    error NicknameTooLong();
    error NicknameTooShort();
    error InvalidCharactersInNickname();
    error NoNicknameSet();
    error TooFewNFTs();

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);
    string private constant _VERSION = "1.00"; // Private as to not clutter the ABI

    /// @notice Represents a user name space entry and data
    struct UserNameSpace {
        string nickName; // Nick name of the user
        uint256 drawsCount; // How many times the user have draw
        uint256 winCount; // How many times the user have win
        uint256 height; // Last user height registered to avoid multiple draw calls on the same height.
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
    IERC721Enumerable public nftContract;

    /// @notice Owner of the auctionlottery
    address public owner;

    /// @notice Indicates if the campaign is live or not.
    bool public campaignFinalized;

    /// @notice value that represents the win rate % in a modulo way, default 5% = 20.
    uint8 public threshold = 20;

    /// @notice Maximun user nick lenght
    uint8 public maxNicknameLen = 7;

    /// @notice Minimun user nick lenght
    uint8 public minNicknameLen = 1;

    /// @notice Pointer to the next NFT ID
    uint256 public nextNftId = 0;

    /// @notice Maximum number of NFTs minted
    uint256 public maxNfts;

    /// @notice holds the best users based on their win count
    // TODO: what if two guys have same win count? we should give priority to the
    //       one with less draws as he has a better winning rate
    //       We need to see if that logic can be added
    using PriorityQueue for PriorityQueue.Queue;
    PriorityQueue.Queue private _leaderboard;

    /**
     * @notice Initializes the lottery with a decryption contract and a fee.
     * @param _decrypter Address of the decryption contract
     * @param _fee The fee required to submit a draw
     * @param _threshold Number to decide  if draw success or fail. Must be less than 100.
     * @param _fairyringContract Address of the fairy ring contract
     * @param _nftContract Address of the contract maintaining the NFTs
     */

    constructor(address _decrypter, uint256 _fee, uint8 _threshold, address _fairyringContract, address _nftContract) {

        if (_threshold >= 100) revert InvalidThreshold();

        nftContract = IERC721Enumerable(_nftContract);
        maxNfts = _getMaxNFTs();
        if (maxNfts < 1) revert TooFewNFTs();

        owner = msg.sender;
        decrypterContract = IDecrypter(_decrypter);
        fee = _fee;
        campaignFinalized = true;
        threshold = _threshold;
        fairyringContract = IFairyringContract(_fairyringContract);

        emit LotteryInitialized(_decrypter, _fee);
    }

    // EXECUTE:OWNER:finalizeCampaign()
    function finalizeCampaign() public {
        if (msg.sender != owner) revert OnlyOwnerCanFinalizeCampaign();
        campaignFinalized = true;
        emit CampaignStatusChanged(true);
    }

    // EXECUTE:OWNER:startCampaign()
    function startCampaign() public {
        if (msg.sender != owner) revert OnlyOwnerCanStartCampaign();
        campaignFinalized = false;
        emit CampaignStatusChanged(false);
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
    function draw(uint256 userGuess) public payable returns (bool) {
        // check pre-conditions
        if (campaignFinalized) revert CampaignOver();
        if (msg.value < fee) revert InsufficientFundsSent();
        if (userGuess > 100) revert GuessValueOutOfRange();
        _noContractCall();

        // check user pre-conditions
        UserNameSpace storage user = userDetails[msg.sender];

        // Only one draw call per height, to avoid bots calling
        // We dont thrown an error, we want the bots to spend as much as possible
        if (user.height >= block.number) {
            ++user.drawsCount;
            emit LotteryDrawn(msg.sender, false, user.drawsCount);
            return false;
        } else {
            // update user height
            user.height = block.number;
        }

        // TODO: remove this, since setPlayerName check this first.
        // if (bytes(user.nickName).length == 0) {
        //     revert NoNicknameSet();
        // }

        (bytes32 randomSeed, ) = fairyringContract.latestRandomness();
        uint256 randomValue = uint256(randomSeed);

        uint256 randomNumber = randomValue % threshold;

        bool isWinner = (userGuess % threshold) == randomNumber;

        ++user.drawsCount;
        ++totalDraws;

        if (isWinner) {
            // Select and transfer a random NFT
            uint256 nftId = nextNftId;
            nftContract.transferFrom(address(this), msg.sender, nftId);

            ++user.winCount;
            ++nextNftId;
            //a potential top10, so insert him
            _leaderboard.insert(msg.sender, user.winCount);

            if (nextNftId >= maxNfts) {
                // End the campaign if all NFTs are used
                // TODO: here a user addr can call this? Make a test.
                finalizeCampaign();
            }
        }

        emit LotteryDrawn(msg.sender, isWinner, totalDraws);
        userDetails[msg.sender] = user;

        return isWinner;
    }

    // EXECUTE:ANYONE:setPlayerName(name: string) -> Result((), error)
    //  use info.address and set name in a Map{address: name}
    function setPlayerName(string memory name) public {
        _isValidNickname(name);

        UserNameSpace storage userSpace = userDetails[msg.sender];

        userSpace.nickName = name;
        userDetails[msg.sender] = userSpace;
        emit PlayerNameSet(msg.sender, name);
    }

    // QUERY:ANYONE:total_draws() -> Result(count: number)
    function totaldraws() public view returns (uint256) {
        return totalDraws;
    }

    // QUERY:ANYONE:getPlayerName() -> Result(name: string)
    function getPlayerName(address player) public view returns (string memory) {
        UserNameSpace storage userSpace = userDetails[player];
        return userSpace.nickName;
    }

    function dashboard() public view returns (UserNameSpace[10] memory) {
        return _getTop10Winners();
    }

    // TODO: move this code inside PriorityQueue as a Query top `n` registries.
    function _getTop10Winners() private view returns (UserNameSpace[10] memory) {
        UserNameSpace[10] memory top10winners;
        // Extract the top 10 winners from the priority queue
        // PriorityQueue.Queue memory tempQueue = _leaderboard.copy();
        // or use the assembly copy if there is significant gas

        // Since we dont mutate the leaderboard, just get values, we dont need to copy().
        uint256 lenght = _leaderboard.heap.length;
        for (uint256 i = 0; i < 10 && lenght > 0; ++i) {
            address winnerAddress = _leaderboard.heap[i].value;
            if (winnerAddress != address(0)) {
                UserNameSpace storage winner = userDetails[winnerAddress];
                top10winners[i] = winner; // Add the winner to the result array
            } else {
                // case where no more address in the priority queue
                // maybe we could do this directly on the PriorityQueue struct.
                break;
            }
        }

        return top10winners;
    }

    function _getMaxNFTs() private view returns (uint256) {
        try nftContract.totalSupply() returns (uint256 totalSupply) {
            return totalSupply;
        } catch {
            revert NFTContractDoesNotSupportTotalSupply();
        }
    }

    function _isValidNickname(string memory name) internal view {
        bytes memory nameBytes = bytes(name);

        if (nameBytes.length == 0) {
            revert NoNicknameSet();
        }

        if (nameBytes.length > maxNicknameLen) {
            revert NicknameTooLong();
        }
        if (nameBytes.length <= minNicknameLen) {
            revert NicknameTooShort();
        }

        uint256 lenght = nameBytes.length;
        for (uint256 i = 0; i < lenght; ++i) {

            bytes1 char = nameBytes[i];

            // Check if the character is a valid UTF-8 character
            if (!(char >= 0x20 && char <= 0x7E)) {
                // Basic printable ASCII range
                revert InvalidCharactersInNickname();
            }

            // Allow only letters, digits, '.', and '-'
            if (
                !(char >= "a" && char <= "z") &&
                !(char >= "A" && char <= "Z") &&
                !(char >= "0" && char <= "9") &&
                char != "." &&
                char != "-"
            ) {
                revert InvalidCharactersInNickname();
            }
        }
    }

    /**
     * @dev Version of the rewards module.
     */
    function version() public pure returns (string memory) {
        return _VERSION;
    }

    function claim() public {
        if (msg.sender != owner) revert OnlyOwnerCanWithdraw();
        emit RewardWithdrawn(owner, address(this).balance);
        Address.sendValue(payable(owner), address(this).balance);
    }

    function _noContractCall() internal view {
        // Check if a smart contract calling -> 0 if EOA, >0 if smart contract
        if (msg.sender.code.length > 0) {
            revert AddressEmptyCode(msg.sender);
        }
    }
}
