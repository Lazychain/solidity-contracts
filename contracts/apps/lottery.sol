// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
// import { Heap } from "@openzeppelin/contracts/utils/structs/Heap.sol";

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

    error OnlyOwnerCanWithdraw();

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

    /// @notice Fee in TIA
    uint256 public fee = 0.01 ether;

    /// @notice Reference to an external decryption contract
    IDecrypter public decrypterContract;

    /// @notice Owner of the auctionlottery
    address public owner;

    /// @notice Indicates if the campaign is live or not.
    bool public campaignFinalized;

    /// @notice value that represents the win rate % in a modulo way, default 5% = 20.
    uint8 threshold = 20;

    /**
     * @notice Initializes the lottery with a decryption contract and a fee.
     * @param _decrypter Address of the decryption contract
     * @param _fee The fee required to submit a draw
     * @param _threshold Number to decide  if draw success or fail. Must be less than 100.
     */
    constructor(address _decrypter, uint256 _fee, uint8 _threshold) {
        owner = msg.sender;
        decrypterContract = IDecrypter(_decrypter);
        fee = _fee;
        campaignFinalized = true;
        threshold = _threshold;
        emit LotteryInitialized(_decrypter, _fee);
    }

    // EXECUTE:OWNER:finalizeCampaign()

    // EXECUTE:OWNER:startCampaign()

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

    // EXECUTE:ANYONE:setPlayerName(name: string) -> Result((), error)
    //  use info.address and set name in a Map{address: name}

    // QUERY:ANYONE:total_draws() -> Result(count: number)
    // QUERY:ANYONE:getPlayerName() -> Result(name: string)
    

    function getTop10Winners() public view returns (UserNameSpace[] memory) {
        // Sort the userSpaces array by win_count in descending order
        UserNameSpace[] memory sortedUsers = sortUserSpacesByWinCount(users);

        // Return the top 10 winners
        UserNameSpace[] memory top10Winners = new UserNameSpace[](10);
        for (uint256 i = 0; i < 10 && i < sortedUsers.length; i++) {
            top10Winners[i] = sortedUsers[i];
        }

        return top10Winners;
    }

    function sortUserSpacesByWinCount(UserNameSpace[] memory userSpaces) private pure returns (UserNameSpace[] memory) {
        // TODO: Try to use Heap openzeppelin impl instead of simple bubble 
        // For now Implemented simple bubble sorting algorithm but could be others e.g., bubble sort, insertion sort, or quicksort
        // I think Heap is the most fit for this.
        for (uint256 i = 0; i < userSpaces.length - 1; i++) {
            for (uint256 j = 0; j < userSpaces.length - i - 1; j++) {
                if (userSpaces[j].win_count < userSpaces[j + 1].win_count) {
                    // Swap userSpaces[j] and userSpaces[j+1]
                    UserNameSpace memory temp = userSpaces[j];
                    userSpaces[j] = userSpaces[j + 1];
                    userSpaces[j + 1] = temp;
                }
            }
        }
        return userSpaces;
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
