// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import { IFairyringContract } from "../../../lib/FairyringContract/src/IFairyringContract.sol";
// import "hardhat/console.sol";

/**
 * @title MockFairyRing
 * @notice A mock implementation of the FairyRing randomness contract using commit-reveal scheme
 * @dev This contract simulates the FairyBlock randomness for testing purposes
 */
contract MockFairyRing is IFairyringContract {
    ////////////
    // ERRORS //
    ////////////
    error MockFairyRing__OnlyOperator();
    error MockFairyRing__InvalidCommitment();
    error MockFairyRing__NoCommitmentFound();
    error MockFairyRing__CommitmentAlreadyRevealed();
    error MockFairyRing__UnRevealedCommitmentExist();
    error OwnableInvalidOwner();
    error OwnableUnauthorizedAccount();

    ///////////
    // EVENT //
    ///////////
    event RandomnessRevealed(address indexed operator, bytes32 indexed commitment, uint256 indexed blockHeight);
    event RandomnessCommited(address indexed operator, bytes32 indexed randomness, uint256 indexed blockHeight);
    event OwnershipTransferred(address indexed newOwner);

    ////////////
    // STRUCT //
    ////////////
    struct Commitment {
        bytes32 commitment;
        bytes32 revealed;
        uint256 blockHeight;
        bool isRevealed;
    }

    ///////////////////////////
    // MAPPINGS + STATE_VARS //
    ///////////////////////////
    address public operator;
    uint256 public latestHeight;
    bytes32 public latestRandom;
    mapping(address => Commitment) public operatorCommitment;

    constructor() {
        operator = msg.sender;
    }

    /**
     * @notice Commits a hash of the random value and secret
     * @param commitment to be ahved as commitment
     * @dev The commitment should be keccak256(abi.encodePacked(randomValue, secret))
     */
    function commitRandomness(bytes32 commitment) external /*onlyOperator*/ {
        if (operatorCommitment[msg.sender].commitment != bytes32(0) && !operatorCommitment[msg.sender].isRevealed) {
            revert MockFairyRing__UnRevealedCommitmentExist();
        }

        uint256 bh = block.number;
        operatorCommitment[msg.sender] = Commitment({
            commitment: commitment,
            revealed: bytes32(0),
            blockHeight: bh,
            isRevealed: false
        });

        emit RandomnessCommited(msg.sender, commitment, bh);
    }

    /**
     * @notice Reveals the committed random value
     * @param randomValue The original random value
     * @param secret The secret used in commitment
     */
    function revealRandomness(bytes32 randomValue, bytes32 secret) external /*onlyOperator*/ {
        Commitment storage commitment = operatorCommitment[msg.sender];

        if (commitment.commitment == bytes32(0)) revert MockFairyRing__NoCommitmentFound();
        if (commitment.isRevealed) revert MockFairyRing__CommitmentAlreadyRevealed();

        bytes32 calcCommitment = keccak256(abi.encodePacked(randomValue, secret));
        if (commitment.commitment != calcCommitment) revert MockFairyRing__InvalidCommitment();

        // state change
        commitment.revealed = randomValue;
        commitment.isRevealed = true;
        latestRandom = randomValue;
        latestHeight = commitment.blockHeight;

        emit RandomnessRevealed(msg.sender, randomValue, latestHeight);
    }

    /**
     * @notice Gets the latest randomness value and its block height
     * @return The latest random value and its block height
     */
    function latestRandomnessWithHeight() external view returns (bytes32, uint256) {
        return (latestRandom, latestHeight);
    }

    /**
     * @notice Gets the latest randomness value
     * @return The latest random value
     */
    function latestRandomnessHashOnly() external view returns (bytes32) {
        return (latestRandom);
    }

    /**
     * @notice Gets the latest randomness value
     * @return Latest random value
     */
    function latestRandomness() external view returns (bytes32, uint256) {
        return (latestRandom, uint256(latestRandom));
    }

    /**
     * @notice Gets the latest randomness value
     * @return Latest random value
     */
    function getLatestRandomness() external view returns (bytes32, uint256) {
        return (latestRandom, uint256(latestRandom));
    }

    function getRandomnessByHeight(uint256) external view returns (bytes32) {
        // TOD: impl getting from heigth instead of latest
        return bytes32(latestHeight);
    }

    /**
     * @notice Gets randomness for a specific block height
     * @param commiter The commiter to query
     * @return The random value for that height
     */
    function getRandomnessByAddress(address commiter) external view returns (uint256) {
        return uint256(operatorCommitment[commiter].revealed);
    }

    // solhint-disable no-empty-blocks
    function renounceOwnership() external view {
        // TODO: we dont know what this function do.
    }

    // solhint-disable no-empty-blocks
    function submitDecryptionKey(bytes memory encryptionKey, bytes memory decryptionKey, uint256 height) external {
        // TODO: must be similar to revealRandomness().
    }

    // solhint-disable no-empty-blocks
    function submitEncryptionKey(bytes memory encryptionKey) external {
        // TODO: must be similar to commitRandomness()
    }

    function decrypt(uint8[] memory c, uint8[] memory skbytes) external returns (uint8[] memory) {
        // TODO: we dont know at this point what should be here.
    }

    /**
     * @notice Who is the owner?
     * @return The owner of the contract
     */
    function owner() external view returns (address) {
        return operator;
    }

    /**
     * @notice Change owner
     * @param newOwner The new Owner
     */
    function transferOwnership(address newOwner) external {
        if (msg.sender != operator) revert OwnableUnauthorizedAccount();
        // Check if a smart contract calling -> 0 if EOA, >0 if smart contract
        if (msg.sender.code.length > 0) {
            revert OwnableInvalidOwner();
        }
        operator = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function latestEncryptionKey() external pure returns (bytes memory) {
        return new bytes(0);
    }

    function encryptionKeyExists(bytes memory) external pure returns (bool) {
        return false;
    }
}
