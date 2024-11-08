// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IBase64 } from "../interfaces/precompile/IBase64.sol";

library Base64 {
    // solhint-disable private-vars-leading-underscore
    IBase64 internal constant BASE64 = IBase64(0x00000000000000000000000000000f043a000004);
    // solhint-enable private-vars-leading-underscore

    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    string internal constant TABLE_URL_SAFE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    /// @dev Encodes the input data into a base64 string
    function encode(bytes memory _data) internal pure returns (string memory) {
        // return BASE64.encode(_data);
        if (_data.length == 0) return "";

        // Load the table into memory
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((_data.length + 2) / 3);

        // Prepare the output string
        string memory result = new string(encodedLen + 32);

        
        //This section uses inline assembly for efficient bitwise manipulation 
        //and to directly access memory addresses, which saves gas.
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, mload(_data)) { i := add(i, 3) } {
                let input := and(mload(add(_data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                out := shl(8, out)
                out := add(out, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                out := shl(8, out)
                out := add(out, mload(add(tablePtr, and(input, 0x3F))))
                out := shl(224, out)

                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }

            switch mod(mload(_data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }
        return result;

    }

    /// @dev Encodes the input data into a URL-safe base64 string
    function encodeURL(bytes memory _data) internal pure returns (string memory) {
        // return BASE64.encodeURL(_data);

        string memory base64 = encode(_data);
        bytes memory base64Bytes = bytes(base64);

        // Replace '+' and '/' with '-' and '_'
        for (uint256 i = 0; i < base64Bytes.length; i++) {
            if (base64Bytes[i] == "+") {
                base64Bytes[i] = "-";
            } else if (base64Bytes[i] == "/") {
                base64Bytes[i] = "_";
            }
        }

        return string(base64Bytes);
    }

    /// @dev Decodes the input base64 string into bytes
    function decode(string memory _data) internal pure returns (bytes memory) {
        // return BASE64.decode(_data);
        // Calculate the length of the decoded output
        uint256 dataLen = bytes(_data).length;
        require(dataLen % 4 == 0, "Invalid base64 input");
        
        uint256 decodedLen = (dataLen * 3) / 4;
        bytes memory result = new bytes(decodedLen);

        string memory table = TABLE;
        
        assembly {
            let tablePtr := add(table, 1) // Pointer to the start of the table
            let resultPtr := add(result, 0x20) // Point to the start of the result

            for { let i := 0 } lt(i, dataLen) { i := add(i, 4) } {
                // Read 4 bytes from the input
                let input := mload(add(_data, i))

                // Convert the Base64 characters to bytes
                input := and(input, 0xffffffff) // Ensure input is 4 bytes
                let out := add(
                    add(
                        add(
                            shl(18, mload(add(tablePtr, and(shr(24, input), 0x3F)))),
                            shl(12, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                        ),
                        shl(6, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                    ),
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )

                // Store the decoded bytes
                mstore(resultPtr, and(out, 0xffffff)) // Store 3 bytes
                resultPtr := add(resultPtr, 3)
            }

            // Handle padding
            switch mod(dataLen, 4)
            case 2 { mstore(sub(resultPtr, 1), 0) } // Remove the last byte for 2 padding characters
            case 3 { mstore(sub(resultPtr, 2), 0) } // Remove the last two bytes for 1 padding character

            mstore(result, decodedLen) // Store the actual length of the result
        }

        return result;
    }

    /// @dev Decodes the input URL-safe base64 string into bytes
    function decodeURL(string memory _data) internal pure returns (bytes memory) {
        // return BASE64.decodeURL(_data);
        string memory base64String = _data;
        base64String = replace(base64String, "-", "+");
        base64String = replace(base64String, "_", "/");

        // Handle padding
        uint256 len = bytes(base64String).length;
        if (len % 4 != 0) {
            uint256 padding = 4 - (len % 4);
            base64String = string(abi.encodePacked(base64String, new string(padding)));
        }

        return decode(base64String);
    }

    // Helper function to replace characters in a string
function replace(
    string memory str,
    string memory from,
    string memory to
) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bSearch = bytes(from);
    bytes memory bReplace = bytes(to);
    
    uint256 count = countOccurrences(bStr, bSearch);
    bytes memory result = new bytes(bStr.length + (bReplace.length - bSearch.length) * count);
    
    copyWithReplacement(bStr, bSearch, bReplace, result);
    
    return string(result);
}

function countOccurrences(bytes memory bStr, bytes memory bSearch) 
    internal 
    pure 
    returns (uint256 count) 
    {
        for (uint256 i = 0; i <= bStr.length - bSearch.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < bSearch.length; j++) {
                if (bStr[i + j] != bSearch[j]) {
                    found = false;
                    break;
                }
            }
            if (found) count++;
        }
    }

function copyWithReplacement(
    bytes memory bStr,
    bytes memory bSearch,
    bytes memory bReplace,
    bytes memory result) 
    internal pure {
        uint256 k;
        for (uint256 i = 0; i < bStr.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < bSearch.length; j++) {
                if (bStr[i + j] != bSearch[j]) {
                    found = false;
                    break;
                }
            }
            
            if (found) {
                for (uint256 j = 0; j < bReplace.length; j++) {
                    result[k++] = bReplace[j];
                }
                i += bSearch.length - 1; // Skip the search length
            } else {
                result[k++] = bStr[i];
            }
        }
    }

}
