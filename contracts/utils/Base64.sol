// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IBase64 } from "../interfaces/precompile/IBase64.sol";

library Base64 {
    IBase64 internal constant BASE64 = IBase64(0x00000000000000000000000000000f043a000004);

    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    string internal constant _TABLE_URL = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    /**
     * @dev Internal encoding function supporting table lookup and optional padding.
     */
    function _encode(bytes memory data, string memory table, bool withPadding) private pure returns (string memory) {
        if (data.length == 0) return "";

        uint256 resultLength = withPadding ? 4 * ((data.length + 2) / 3) : (4 * data.length + 2) / 3;
        string memory result = new string(resultLength);

        assembly("memory-safe") {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 0x20)
            let dataPtr := data
            let endPtr := add(data, mload(data))
            let afterPtr := add(endPtr, 0x20)
            let afterCache := mload(afterPtr)
            mstore(afterPtr, 0x00)

            for { } lt(dataPtr, endPtr) { } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            if withPadding {
                switch mod(mload(data), 3)
                case 1 {
                    mstore8(sub(resultPtr, 1), 0x3d)
                    mstore8(sub(resultPtr, 2), 0x3d)
                }
                case 2 {
                    mstore8(sub(resultPtr, 1), 0x3d)
                }
            }
        }
        return result;
    }

    /**
     * @dev Internal decoding function supporting table lookup.
     */
    function _decode(string memory encoded, string memory table) private pure returns (bytes memory) {
        bytes memory input = bytes(encoded);
        if (input.length == 0) return "";

        uint256 decodedLen = input.length * 3 / 4;
        bytes memory decoded = new bytes(decodedLen);

        assembly ("memory-safe") {
            let tablePtr := add(table, 1)
            let inputPtr := add(input, 0x20)
            let endPtr := add(inputPtr, mload(input))
            let decodedPtr := add(decoded, 0x20)

            for { } lt(inputPtr, endPtr) { } {
                let sextetA := mload(add(tablePtr, byte(0, mload(inputPtr))))
                inputPtr := add(inputPtr, 1)
                let sextetB := mload(add(tablePtr, byte(0, mload(inputPtr))))
                inputPtr := add(inputPtr, 1)
                let sextetC := mload(add(tablePtr, byte(0, mload(inputPtr))))
                inputPtr := add(inputPtr, 1)
                let sextetD := mload(add(tablePtr, byte(0, mload(inputPtr))))
                inputPtr := add(inputPtr, 1)

                let triple := or(shl(18, sextetA), or(shl(12, sextetB), or(shl(6, sextetC), sextetD)))
                
                mstore8(decodedPtr, byte(2, triple))
                decodedPtr := add(decodedPtr, 1)
                mstore8(decodedPtr, byte(1, triple))
                decodedPtr := add(decodedPtr, 1)
                mstore8(decodedPtr, byte(0, triple))
                decodedPtr := add(decodedPtr, 1)
            }
        }

        return decoded;
    }

    /// @dev Encodes the input data into a base64 string
    function encode(bytes memory _data) internal pure returns (string memory) {
            return _encode(_data, _TABLE, true);
    }

    /// @dev Encodes the input data into a URL-safe base64 string
    function encodeURL(bytes memory _data) internal pure returns (string memory) {
        return _encode(_data, _TABLE_URL, false);
    }

    /// @dev Decodes the input base64 string into bytes
    function decode(string memory _data) internal pure returns (bytes memory) {
        return _decode(_data, _TABLE);
    }

    /// @dev Decodes the input URL-safe base64 string into bytes
    function decodeURL(string memory _data) internal pure returns (bytes memory) {
        return _decode(_data, _TABLE_URL);
    }
}