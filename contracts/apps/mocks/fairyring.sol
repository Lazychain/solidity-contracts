// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MockFairyRing
 * @notice A mock implementation of the FairyRing randomness contract using commit-reveal scheme
 * @dev This contract simulates the FairyBlock randomness for testing purposes
 */
contract MockFairyRing {
    ////////////
    // ERRORS //
    ////////////
    error MockFairyRing__OnlyOperator();
    error MockFairyRing__InvalidCommitment();
    error MockFairyRing__NoCommitmentFound();
    error MockFairyRing__CommitmentAlreadyRevealed();

    ///////////
    // EVENT //
    ///////////
    event RandomnessRevealed(address indexed operator, bytes32 indexed commitment, uint256 indexed blockHeight);
    event RandomnessCommited(address indexed operator, bytes32 indexed randomness, uint256 indexed blockHeight);

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
    bytes32 public latestRandomness;
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
            revert MockFairyRing__InvalidCommitment();
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
        latestRandomness = randomValue;
        latestHeight = commitment.blockHeight;

        emit RandomnessRevealed(msg.sender, randomValue, latestHeight);
    }

    /**
     * @notice Gets the latest randomness value and its block height
     * @return The latest random value and its block height
     */
    function latestRandomnessWithHeight() external view returns (bytes32, uint256) {
        return (latestRandomness, latestHeight);
    }

    /**
     * @notice Gets the latest randomness value
     * @return Latest random value
     */
    function getLatestRandomness() external view returns (bytes32) {
        return latestRandomness;
    }

    /**
     * @notice Gets randomness for a specific block height
     * @param commiter The commiter to query
     * @return The random value for that height
     */
    function getRandomnessByAddress(address commiter) external view returns (uint256) {
        return uint256(operatorCommitment[commiter].revealed);
    }
}
