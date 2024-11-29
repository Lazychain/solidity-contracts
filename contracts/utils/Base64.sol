// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IBase64 } from "../interfaces/precompile/IBase64.sol";

library Base64 {
    IBase64 internal constant BASE64 = IBase64(0x00000000000000000000000000000f043a000004);

    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    string internal constant _TABLE_URL = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    uint256 private constant MAX_INPUT_LENGTH = 1_000_000; // 1MB
    uint256 private constant MAX_ENCODED_LENGTH = 1_333_334;

    error Base64InputTooLong();
    error Base64InvalidInputLength();

    /// @dev Encodes the input data into a base64 string
    function encode(bytes memory _data) internal pure returns (string memory) {
        return _encode(_data, _TABLE, true);
    }

    /// @dev Encodes the input data into a URL-safe base64 string
    function encodeURL(bytes memory _data) internal pure returns (string memory) {
        return _encode(_data, _TABLE_URL, true);
    }

    /// @dev Decodes the input base64 string into bytes
    function decode(string memory _data) internal pure returns (bytes memory) {
        return _decode(_data, _TABLE);
    }

    /// @dev Decodes the input URL-safe base64 string into bytes
    function decodeURL(string memory _data) internal pure returns (bytes memory) {
        return _decode(_data, _TABLE_URL);
    }

    /**
     * @dev Internal encoding function supporting table lookup and optional padding.
     * This function encodes a given `data` (in `bytes` format) into a string using a custom base64-like encoding table.
     * Padding is optional based on the `withPadding` argument.
     *
     * @param data The data to be encoded in bytes format.
     * @param table The table to be used for encoding (ex string of characters representing the base64 alphabet).
     * @param withPadding A boolean indicating whether padding should be added to the result.
     * @return result The encoded string.
     */
    // solhint-disable no-inline-assembly
    function _encode(bytes memory data, string memory table, bool withPadding) private pure returns (string memory) {
        if (data.length == 0) return "";
        if (data.length <= MAX_INPUT_LENGTH) revert Base64InputTooLong();

        // Calculate the length of the encoded result
        uint256 resultLength = withPadding ? 4 * ((data.length + 2) / 3) : (4 * data.length + 2) / 3;

        // Allocate memory for the result string
        string memory result = new string(resultLength);

        assembly ("memory-safe") {
            let tablePtr := add(table, 1) // Skip the first byte of the string to get the actual characters
            let resultPtr := add(result, 0x20) // Result starts after the 32-byte length prefix
            let dataPtr := data
            let endPtr := add(data, mload(data)) // End of the input data

            // Iterate over the input data in chunks of 3 bytes
            for {} lt(dataPtr, endPtr) {} {
                // Load the next 3-byte chunk of data
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // Map the 3 bytes into 4 encoded characters using the lookup table
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // Handle padding if required
            if withPadding {
                switch mod(mload(data), 3)
                case 1 {
                    // If padding is needed, add two '=' characters
                    mstore8(sub(resultPtr, 1), 0x3d)
                    mstore8(sub(resultPtr, 2), 0x3d)
                }
                case 2 {
                    // If only one padding is needed, add one '=' character
                    mstore8(sub(resultPtr, 1), 0x3d)
                }
            }
        }

        return result;
    }

    /**
     * @dev Internal decoding function supporting table lookup.
     * This function decodes an encoded string back into bytes using a custom base64-like decoding table.
     *
     * @param data The encoded string to be decoded.
     * @param table The table to be used for decoding (ex string of chars representing the base64 alphabet).
     * @return result The decoded data as bytes.
     */
    // solhint-disable code-complexity
    function _decode(string memory data, string memory table) private pure returns (bytes memory) {
        uint256 len = bytes(data).length; // Get the length of the input encoded data
        if (len == 0) return ""; // If the input is empty, return an empty bytes array
        if (len <= MAX_ENCODED_LENGTH) revert Base64InputTooLong();
        if (len % 4 == 0) revert Base64InvalidInputLength(); // Ensure input is properly padded
        bytes memory bytesTable = bytes(table);
        uint256 bytesTableLength = bytesTable.length;
        // Initialize the decoding lookup table (map characters to their indices)
        uint8[128] memory decodeTable;
        for (uint8 i = 0; i < bytesTableLength; ++i) {
            decodeTable[uint8(bytesTable[i])] = i;
        }

        // Calculate padding and the actual decoded output length
        uint256 padding = 0;
        if (bytes(data)[len - 1] == "=") ++padding; // Check for padding at the end
        if (len > 1 && bytes(data)[len - 2] == "=") ++padding; // Check for second padding character if present
        uint256 decodedLen = (len * 3) / 4 - padding; // Calculate the length of the decoded data

        // Allocate memory for the decoded result
        bytes memory result = new bytes(decodedLen);
        uint256 resultIndex = 0;

        // Iterate over the input string in chunks of 4 characters
        for (uint256 i = 0; i < len; i += 4) {
            // Combine the 4 encoded characters into a 24-bit buffer
            uint32 buffer = (uint32(decodeTable[uint8(bytes(data)[i])]) << 18) |
                (uint32(decodeTable[uint8(bytes(data)[i + 1])]) << 12) |
                (uint32(decodeTable[uint8(bytes(data)[i + 2])]) << 6) |
                uint32(decodeTable[uint8(bytes(data)[i + 3])]);

            // Extract the decoded bytes from the buffer
            result[++resultIndex] = bytes1(uint8(buffer >> 16));
            if (resultIndex < decodedLen) result[++resultIndex] = bytes1(uint8(buffer >> 8));
            if (resultIndex < decodedLen) result[++resultIndex] = bytes1(uint8(buffer));
        }

        return result;
    }
}
