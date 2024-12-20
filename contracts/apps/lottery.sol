// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IFairyringContract, IDecrypter } from "./Ifairyring.sol";
// import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { Lazy1155 } from "./lazy1155.sol";
import "hardhat/console.sol";
// import { console } from "forge-std/console.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @title Simple NFT Lottery App
 * @author Lazychain
 * @notice Contract that allow simple user interaction with a lottery App.
 * @dev FLOW OF CONTRACT:
 * Deploy Contract: Deploys Lottery on the Forma testnet.
 * Submit draw(gues_number) for nft lottery: User sends a guess number to the contract.
 * The contract get a random_number from Fairblock Technologies and compare with the guess_number
 * and determine if win or not.
 * If win, it transfer ownership of a nft from a list
 */
contract NFTLottery is Ownable, ERC1155Holder {
    event LotteryInitialized(address decrypter, uint256 fee);
    event RewardWithdrawn(address by, uint256 amount);
    event LotteryDrawn(address indexed player, bool result, uint256 nftId, uint256 totalDraws);
    event MintedNft(address indexed player, uint256 nftId);
    event CampaignStatusChanged(bool status);

    error NFTLottery__DoesNotSupportTotalSupply();
    error NFTLottery__OnlyOwnerCanWithdraw();
    error NFTLottery__CampaignOver();
    error NFTLottery__InsufficientFundsSent();
    error NFTLottery__GuessValueOutOfRange();
    error NFTLottery__TooFewNFTs(string message);
    error NFTLottery__TooFewPooPoints();
    error NFTLottery__InternalError(string message);
    error NFTLottery__NFTContractDoesNotSupportTotalSupply();

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

    /// @notice Collection
    Lazy1155 private _nft;

    uint256 private _tokensIdCap;

    /// @notice Indicates if the campaign is live or not.
    bool public isCampaignOpen = false;

    /// @notice Maximum number of NFTs minted
    uint256 public totalCollectionItems = 0;

    /**
     * @notice Initializes the lottery with a decryption contract and a fee.
     * @param _decrypter Address of the decryption contract
     * @param _fee The fee required to submit a draw
     * @param _fairyringContract Address of the fairy ring contract
     * @param _erc1155 A list of NFTs Addresses
     */
    constructor(address _erc1155, uint256 _fee, address _fairyringContract, address _decrypter) Ownable(msg.sender) {
        _nft = Lazy1155(_erc1155);
        _tokensIdCap = 0;
        for (uint256 i = 0; i < 255; i++) {
            // Scan from zero all tokensId assigned to owner
            if (_nft.tokenExists(i)) {
                _tokensIdCap++;
            }
        }
        decrypterContract = IDecrypter(_decrypter);
        fee = _fee;
        fairyringContract = IFairyringContract(_fairyringContract);
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
        payable(msg.sender).transfer(balance);
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

    function draw(
        uint256 userGuess
    ) external payable noContractCall noZeroAddress openCampaign fees returns (uint256 nftId) {
        bool isWinner = false; // default not win as start
        nftId = totalCollectionItems + 1; // Ensure that this nft id doesnt exist
        if (userGuess > 100) revert NFTLottery__GuessValueOutOfRange();
        ++totalDraws;

        UserNameSpace storage user = userDetails[msg.sender];

        // Only one draw call per height, to avoid bots calling
        // We dont thrown an error, we want the bots to spend as much as possible
        if (user.height >= block.number) {
            ++user.drawsCount;
            emit LotteryDrawn(msg.sender, false, nftId, totalDraws);
            return nftId;
        } else {
            user.height = block.number;
        }

        (, uint256 randomValue) = fairyringContract.latestRandomness();
        uint256 normalizedGuess = userGuess % 100;
        uint256 normalizedRandom = randomValue % 100;
        //console.log("guess[%s] random[%s]", normalizedGuess, normalizedRandom);

        // get distance between guess and random
        uint256 distance = _distance(normalizedGuess, normalizedRandom);

        ++user.drawsCount;
        ++user.pooPoints;

        //console.log("guess[%s] random[%s] distance [%s]", normalizedGuess, normalizedRandom, distance);
        // If distance is less than 4, we got a winner
        if (distance < _tokensIdCap) {
            // Winner case
            isWinner = true;
            // We start from the Top winning according to distance and
            // if there are no more nft tokens, we increase distance by one
            // to check if there are tokens in other levels
            // Here, could be the case that the winner win an nft, but there are no more
            // on low levels prices. In this case, is a lose.
            for (uint256 tokenId = distance; tokenId < _tokensIdCap; tokenId++) {
                // Check if there are quantity of NFT id TokenId remaining
                if (_nft.balanceOf(address(this), tokenId) > 0) {
                    _nft.safeTransferFrom(address(this), msg.sender, tokenId, 1, "0x0");
                    emit LotteryDrawn(msg.sender, isWinner, tokenId, totalDraws);
                    emit MintedNft(msg.sender, tokenId);
                    ++user.winCount;
                    userDetails[msg.sender] = user;
                    return tokenId;
                }
            }
            revert NFTLottery__TooFewNFTs("No more NFTs");
        } else {
            emit LotteryDrawn(msg.sender, false, 0, totalDraws);
        }
    }

    function claimNFT() external payable openCampaign noZeroAddress fees returns (uint256 nftId) {
        UserNameSpace storage user = userDetails[msg.sender];

        // Check if the user has enough poo points
        if (user.pooPoints < 100) {
            revert NFTLottery__TooFewPooPoints();
        }

        console.log(" Points[%s]", user.pooPoints);
        // Check if there are NFTs remaining starting from low nfts types
        for (uint256 tokenId = _tokensIdCap - 1; tokenId > 0; tokenId--) {
            // i = 3,2,1,0
            console.log("TokenId[%s]", tokenId);
            uint256 balance = _nft.balanceOf(address(this), tokenId);
            console.log("TokenId[%s] max[%s]", tokenId, balance);

            // Check if there are NFTs remaining
            if (balance > 0) {
                // Deduct 100 poo points
                user.pooPoints -= 100;
                userDetails[msg.sender] = user;

                // Transfer NFT to the user
                _nft.safeTransferFrom(address(this), msg.sender, tokenId, 1, "0x0");
                emit MintedNft(msg.sender, tokenId);
                return tokenId;
            }
        }

        revert NFTLottery__TooFewNFTs("No more NFTs. Collection is over.");
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
        //console.log("%s", _VERSION);
        return _VERSION;
    }

    function _getMaxNFTs(Lazy1155 nftContract) private view returns (uint256) {
        try nftContract.totalSupply() returns (uint256 totalSupply) {
            return totalSupply;
        } catch {
            revert NFTLottery__NFTContractDoesNotSupportTotalSupply();
        }
    }

    modifier noContractCall() {
        // Check if a smart contract calling -> 0 if regular Ethereum account (EOA), >0 if smart contract
        if (msg.sender.code.length > 0) {
            revert AddressEmptyCode(msg.sender);
        }
        _;
    }

    modifier noZeroAddress() {
        // The zero address is a special address that doesn't correspond to any account.
        if (msg.sender == address(0)) {
            revert AddressEmptyCode(msg.sender);
        }
        _;
    }

    modifier openCampaign() {
        if (!isCampaignOpen) revert NFTLottery__CampaignOver();
        _;
    }

    modifier fees() {
        // console.log("Fee sent [%s]", msg.value);
        if (msg.value < fee) revert NFTLottery__InsufficientFundsSent();
        _;
    }

    /**
     * @dev For this particular campaign will be 4 nfts types, each one with differents probabilities
     * distance = 0 NFT type 1
     * distance = 1 NFT type 2
     * distance = 2 NFT type 3
     * distance = 3 NFT type 4
     * distance > 3 No NFT win
     * distance become the `index` if the `nftContracts`
     */
    function _distance(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return b - a;
        }
    }
}
