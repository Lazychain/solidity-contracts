// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFairyringContract {
    // function commitRandomness(bytes32 commitment) external;
    // function revealRandomness(bytes32 randomValue, bytes32 secret) external;
    // function latestRandomnessWithHeight() external view returns (bytes32, uint256);
    // function latestRandomnessHashOnly() external view returns (bytes32);
    // function getLatestRandomness() external view returns (bytes32, uint256);
    // function getRandomnessByAddress(address commiter) external view returns (uint256);
    // function renounceOwnership() external view;
    // function submitDecryptionKey(bytes memory encryptionKey, bytes memory decryptionKey, uint256 height) external;
    // function submitEncryptionKey(bytes memory encryptionKey) external;
    // function owner() external view returns (address);
    // function transferOwnership(address newOwner) external;
    // function decrypt(uint8[] memory c, uint8[] memory skbytes) external returns (uint8[] memory);
    function latestRandomness() external view returns (bytes32, uint256);
    function getRandomnessByHeight(uint256 height) external view returns (uint256);
}

interface IDecrypter {
    function decrypt(uint8[] memory c, uint8[] memory skbytes) external returns (uint8[] memory);
}
