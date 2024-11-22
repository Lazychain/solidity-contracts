// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { PriorityQueue } from "../utils/PriorityQueue.sol";

interface IFairyringContract {
    function latestRandomness() external view returns (bytes32, uint256);
    function getRandomnessByHeight(uint256 height) external view returns (uint256);
}

interface IDecrypter {
    function decrypt(
        uint8[] memory c,
        uint8[] memory skbytes
    ) external returns (uint8[] memory);
}

/**
 * @title Simple NFT Lottery App
 * @author Lazychain
 * @notice Contract that allow simple user interaction with a lottery App.
 * @dev FLOW OF CONTRACT:
 * Deploy Contract: Deploys Lottery on the Forma testnet.
 * Submit draw(gues_number) for nft lottery: User sends a guess number to the contract.
 * The contract get a random_number from Fairblock Technologies and compare with the guess_number and determine if win or not.
 * If wyn, it transfer ownership of a nft from a list
 */
contract NFTLottery {
    event LotteryInitialized(address decrypter, uint256 fee);
    event RewardWithdrawn(address by, uint256 amount);
    event LotteryDrawn(address indexed player, bool result, uint256 totalDraws);
    event CampaignStatusChanged(bool isFinalized);
    event PlayerNameSet(address indexed player, string name);

    error OnlyOwnerCanWithdraw();
    error CampaignOver();
    error InsufficientFundsSent();
    error InvalidThreshold();

    string private constant VERSION = "1.00"; // Private as to not clutter the ABI

    /// @notice Represents a user name space entry and data
    struct UserNameSpace {
        address userAddress; // User address
        string nickName; // Nick name of the user
        uint256 draws_count; // How many times the user have draw
        uint256 win_count; // How many times the user have win
    }

    /// @notice List of all users
    UserNameSpace[] public users;
    mapping(address => string) public playerNames; //names corresponding to addresses
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
    IERC721 public nftContract;

    /// @notice Owner of the auctionlottery
    address public owner;

    /// @notice Indicates if the campaign is live or not.
    bool public campaignFinalized;

    /// @notice value that represents the win rate % in a modulo way, default 5% = 20.
    uint8 threshold = 20;

    /// @notice holds the best users based on their win count
    // TODO: what if two guys have same win count? we should give priority to the
    //       one with less draws as he has a better winning rate
    //       We need to see if that logic can be added
    using PriorityQueue for PriorityQueue.Queue;
    PriorityQueue.Queue private leaderboard;

    /**
     * @notice Initializes the lottery with a decryption contract and a fee.
     * @param _decrypter Address of the decryption contract
     * @param _fee The fee required to submit a draw
     * @param _threshold Number to decide  if draw success or fail. Must be less than 100.
     * @param _fairyringContract Address of the fairy ring contract
     * @param _nftContract Address of the contract maintaining the NFTs
     */
    constructor(address _decrypter, uint256 _fee, uint8 _threshold, address _fairyringContract,
        address _nftContract) {
        if (_threshold >= 100) revert InvalidThreshold();

        owner = msg.sender;
        decrypterContract = IDecrypter(_decrypter);
        fee = _fee;
        campaignFinalized = true;
        threshold = _threshold;
        fairyringContract = IFairyringContract(_fairyringContract);
        nftContract = IERC721(_nftContract);

        emit LotteryInitialized(_decrypter, _fee);
    }

    // EXECUTE:OWNER:finalizeCampaign()
    function finalizeCampaign() public {
        require(msg.sender == owner, "Only owner can finalize campaign");
        campaignFinalized = true;
        emit CampaignStatusChanged(true);
    }

    // EXECUTE:OWNER:startCampaign()
    function startCampaign() public {
        require(msg.sender == owner, "Only owner can start campaign");
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
        if (campaignFinalized) revert CampaignOver();
        if (msg.value < fee) revert InsufficientFundsSent();

        uint256 height = block.number;
        uint256 randomness = fairyringContract.getRandomnessByHeight(height);

        uint256 randomNumber = randomness % 100;
        uint256 combinedResult = (userGuess + randomNumber) % 100;
        bool isWinner = combinedResult <= threshold;
        
        UserNameSpace storage user = userDetails[msg.sender];
        if (user.userAddress == address(0)) {
            user.userAddress = msg.sender;
        }
        user.draws_count++;
        totalDraws++;

        if (isWinner) {
            // Select and transfer a random NFT
            uint256 nftId = uint256(randomness) % nftContract.balanceOf(address(this));
            nftContract.transferFrom(address(this), msg.sender, nftId);
            
            user.win_count++;
            //a potential top10, so insert him
            leaderboard.insert(msg.sender, user.win_count);
        }

        emit LotteryDrawn(msg.sender, isWinner, totalDraws);
        userDetails[msg.sender] = user;
        return isWinner;
    }


    // EXECUTE:ANYONE:setPlayerName(name: string) -> Result((), error)
    //  use info.address and set name in a Map{address: name}
    function setPlayerName(string memory name) public {
        playerNames[msg.sender] = name;
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
        return playerNames[player];
    }    

    function dashboard() public returns (UserNameSpace[10] memory) {
        return getTop10Winners();
    }

    function getTop10Winners() private returns (UserNameSpace[10] memory) {
        UserNameSpace[10] memory top10winners;
        // Extract the top 10 winners from the priority queue
        PriorityQueue.Queue storage tempQueue = leaderboard; // Copy the queue so we can safely pop without affecting original
        for (uint256 i = 0; i < 10 && tempQueue.size() > 0; i++) {
            address winnerAddress = tempQueue.extractMax(); // Extract user with highest win_count
            UserNameSpace storage winner = userDetails[winnerAddress];
            top10winners[i] = winner; // Add the winner to the result array
        }

        return top10winners;
    }

    /**
     * @dev Version of the rewards module.
     */
    function version() public pure returns (string memory) {
        return VERSION;
    }

    function claim() public {
        if (msg.sender != owner) revert OnlyOwnerCanWithdraw();
        emit RewardWithdrawn(owner, address(this).balance);
        Address.sendValue(payable(owner), address(this).balance);
    }
}
