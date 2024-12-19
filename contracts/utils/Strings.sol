// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IStrings } from "../interfaces/precompile/IStrings.sol";

/**
 * @dev String operations.
 */
library Strings {
    // solhint-disable private-vars-leading-underscore
    IStrings internal constant STRINGS = IStrings(0x00000000000000000000000000000F043A000005);
    // solhint-enable private-vars-leading-underscore

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);

        if (a.length != b.length) return false;
        uint256 length = a.length;
        // Compare each byte
        for (uint256 i = 0; i < length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }

    /**
     * @dev Returns true if the two strings are equal, ignoring case.
     */
    function equalCaseFold(string memory _a, string memory _b) internal pure returns (bool) {
        return equal(toLowerCase(_a), toLowerCase(_b));
    }

    /**
     * @dev Checks if a string contains a given substring.
     * @param _str The string to search within.
     * @param _substr The substring to search for.
     * @return A boolean indicating whether the substring is found within the string.
     */
    function contains(string memory _str, string memory _substr) internal pure returns (bool) {
        bytes memory str = bytes(_str);
        bytes memory substr = bytes(_substr);

        if (substr.length > str.length) return false;

        uint256 length = str.length - substr.length;
        uint256 subStrLength = substr.length;
        for (uint256 i = 0; i <= length; i++) {
            bool same = true;
            for (uint256 j = 0; j < subStrLength; j++) {
                if (str[i + j] != substr[j]) {
                    same = false;
                    break;
                }
            }
            if (same) return true;
        }
        return false;
    }

    /**
     * @dev Checks if a string starts with a given substring.
     * @param _str The string to check.
     * @param _substr The substring to check for.
     * @return A boolean indicating whether the string starts with the substring.
     */
    function startsWith(string memory _str, string memory _substr) internal pure returns (bool) {
        bytes memory str = bytes(_str);
        bytes memory substr = bytes(_substr);

        if (substr.length > str.length) return false;

        uint256 subStrLength = substr.length;
        for (uint256 i = 0; i < subStrLength; i++) {
            if (str[i] != substr[i]) return false;
        }
        return true;
    }

    /**
     * @dev Checks if a string ends with a given substring.
     * @param _str The string to check.
     * @param _substr The substring to check for.
     * @return A boolean indicating whether the string ends with the substring.
     */
    function endsWith(string memory _str, string memory _substr) internal pure returns (bool) {
        bytes memory str = bytes(_str);
        bytes memory substr = bytes(_substr);

        if (substr.length > str.length) return false;

        uint256 offset = str.length - substr.length;
        uint256 subStrLength = substr.length;
        for (uint256 i = 0; i < subStrLength; i++) {
            if (str[offset + i] != substr[i]) return false;
        }
        return true;
    }

    /**
     * @dev Returns the index of the first occurrence of a substring within a string.
     */
    function indexOf(string memory _str, string memory _substr) internal pure returns (uint256) {
        bytes memory str = bytes(_str);
        bytes memory substr = bytes(_substr);

        if (substr.length > str.length) return type(uint256).max;

        uint256 length = str.length - substr.length;
        uint256 subStrLength = substr.length;
        for (uint256 i = 0; i <= length; i++) {
            bool same = true;
            for (uint256 j = 0; j < subStrLength; j++) {
                if (str[i + j] != substr[j]) {
                    same = false;
                    break;
                }
            }
            if (same) return i;
        }
        return type(uint256).max; // Returns max value if not found
    }

    /**
     * @dev Converts all the characters of a string to uppercase.
     */
    function toUpperCase(string memory _str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        uint256 length = strBytes.length;
        for (uint256 i = 0; i < length; i++) {
            // Check if character is a lowercase letter (a-z)
            if (strBytes[i] >= 0x61 && strBytes[i] <= 0x7A) {
                // Convert to uppercase by subtracting 32
                strBytes[i] = bytes1(uint8(strBytes[i]) - 32);
            }
        }
        return string(strBytes);
    }

    /**
     * @dev Converts all the characters of a string to lowercase.
     */
    function toLowerCase(string memory _str) internal pure returns (string memory) {
        bytes memory bStr = bytes(_str);
        bytes memory bLower = new bytes(bStr.length);
        uint256 length = bStr.length;
        for (uint256 i = 0; i < length; i++) {
            // Check if the byte is an uppercase letter
            if (bStr[i] >= 0x41 && bStr[i] <= 0x5A) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32); // Convert to lowercase
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /**
     * @dev Pads the start of a string with a given pad string up to a specified length.
     */
    function padStart(string memory _str, uint16 _len, string memory _pad) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        uint256 strLen = strBytes.length;
        if (strLen >= _len) return _str;

        uint256 padCount = (_len - strLen) / bytes(_pad).length;
        bytes memory padBytes = bytes(_pad);
        bytes memory result = new bytes(_len);

        uint256 k = 0;
        uint256 length = padCount * padBytes.length;
        for (uint256 i = 0; i < length; i++) {
            result[k++] = padBytes[i % padBytes.length];
        }
        for (uint256 i = 0; i < strLen; i++) {
            result[k++] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev Pads the end of a string with a given pad string up to a specified length.
     */
    function padEnd(string memory _str, uint16 _len, string memory _pad) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        uint256 strLen = strBytes.length;
        if (strLen >= _len) return _str;

        uint256 padCount = (_len - strLen) / bytes(_pad).length;
        bytes memory padBytes = bytes(_pad);
        bytes memory result = new bytes(_len);

        uint256 k = 0;
        for (uint256 i = 0; i < strLen; ++i) {
            result[k++] = strBytes[i];
        }
        uint256 padBytesLength = padBytes.length;
        uint256 length = padCount * padBytesLength;
        for (uint256 i = 0; i < length; ++i) {
            result[k++] = padBytes[i % padBytesLength];
        }
        return string(result);
    }

    /**
     * @dev Repeats a string a specified number of times.
     */
    function repeat(string memory _str, uint16 _count) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        uint256 strBytesLength = strBytes.length;
        bytes memory result = new bytes(strBytesLength * _count);

        for (uint256 i = 0; i < _count; ++i) {
            for (uint256 j = 0; j < strBytesLength; ++j) {
                result[i * strBytesLength + j] = strBytes[j];
            }
        }
        return string(result);
    }

    /**
     * @dev Replaces a specified number of occurrences of a substring within a string with a new substring.
     * @param _str The original string.
     * @param _old The substring to be replaced.
     * @param _new The new substring to replace the old substring.
     * @param _n The number of occurrences to replace.
     * @return A new string with the specified number of occurrences of the old substring replaced by the new substring.
     */
    function replace(
        string memory _str,
        string memory _old,
        string memory _new,
        uint16 _n
    ) internal pure returns (string memory) {
        return replaceInternal(_str, _old, _new, _n);
    }

    /**
     * @dev Replaces all occurrences of a substring within a string with a new substring.
     */
    function replaceAll(
        string memory _str,
        string memory _old,
        string memory _new
    ) internal pure returns (string memory) {
        return replaceInternal(_str, _old, _new, type(uint16).max);
    }

    /**
     * @dev Splits a string into an array of substrings using a specified delimiter.
     */
    function split(string memory _str, string memory _delim) internal pure returns (string[] memory) {
        if (bytes(_delim).length == 0) return new string[](0);
        bytes memory strBytes = bytes(_str);
        bytes memory delimBytes = bytes(_delim);

        uint256[] memory positions = findDelimiterPositions(strBytes, delimBytes);
        return extractSubstrings(strBytes, positions, delimBytes.length);
    }

    /**
     * @dev Trims whitespace from the start and end of a string.
     */
    function trim(string memory _str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        uint256 strBytesLength = strBytes.length;
        uint256 start = 0;
        uint256 end = strBytesLength - 1;

        while (start < strBytesLength && strBytes[start] == 0x20) start++;
        while (end > start && strBytes[end] == 0x20) end--;

        bytes memory result = new bytes(end - start + 1);
        for (uint256 i = start; i <= end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }

    /*
    internal/helper functions
    */

    function replaceInternal(
        string memory _str,
        string memory _old,
        string memory _new,
        uint16 _limit
    ) internal pure returns (string memory) {
        if (bytes(_old).length == 0 || bytes(_str).length == 0 || _limit == 0) {
            return _str;
        }

        bytes memory strBytes = bytes(_str);
        bytes memory oldBytes = bytes(_old);
        bytes memory newBytes = bytes(_new);

        uint256 matches = 0;
        uint256 position = 0;
        bytes memory result;

        uint256 strBytesLength = strBytes.length;
        while (position < strBytesLength && matches < _limit) {
            uint256 matchIndex = findSubstring(strBytes, oldBytes, position);
            if (matchIndex == strBytesLength) break; // No more matches found
            // TODO: I underestand that strBytes is not mutated here.
            result = concatenateBytes(result, sliceBytes(strBytes, position, matchIndex - position), newBytes);

            position = matchIndex + oldBytes.length;
            matches++;
        }
        // im gonna leave strBytes.length here cause im not sure if mutated.
        result = concatenateBytes(result, sliceBytes(strBytes, position, strBytes.length - position), "");
        return string(result);
    }

    // Helper function to find substring index
    function findSubstring(bytes memory str, bytes memory sub, uint256 from) private pure returns (uint256) {
        uint256 subLength = sub.length;
        uint256 length = str.length - subLength;
        for (uint256 i = from; i <= length; i++) {
            bool matchFound = true;
            for (uint256 j = 0; j < subLength; j++) {
                if (str[i + j] != sub[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) return i;
        }
        return str.length; // No match found
    }

    // Helper function to concatenate bytes arrays
    function concatenateBytes(bytes memory a, bytes memory b, bytes memory c) private pure returns (bytes memory) {
        uint256 aLength = a.length;
        uint256 bLength = b.length;
        uint256 cLength = c.length;

        bytes memory combined = new bytes(aLength + bLength + cLength);
        uint256 k = 0;

        for (uint256 i = 0; i < aLength; i++) combined[k++] = a[i];
        for (uint256 i = 0; i < bLength; i++) combined[k++] = b[i];
        for (uint256 i = 0; i < cLength; i++) combined[k++] = c[i];

        return combined;
    }

    // Helper function to slice bytes array
    function sliceBytes(bytes memory data, uint256 start, uint256 length) private pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }

    // Helper function to find all positions of the delimiter in the string
    function findDelimiterPositions(bytes memory str, bytes memory delim) private pure returns (uint256[] memory) {
        uint256[] memory tempPositions = new uint256[](str.length);
        uint256 posCount = 0;
        uint256 position = 0;
        uint256 length = str.length;
        while (position < length) {
            uint256 delimIndex = findSubstring(str, delim, position);
            if (delimIndex == str.length) break;

            tempPositions[posCount++] = delimIndex;
            position = delimIndex + delim.length;
        }

        uint256[] memory positions = new uint256[](posCount);
        for (uint256 i = 0; i < posCount; i++) {
            positions[i] = tempPositions[i];
        }
        return positions;
    }

    // Helper function to extract substrings based on delimiter positions
    function extractSubstrings(
        bytes memory str,
        uint256[] memory positions,
        uint256 delimLength
    ) private pure returns (string[] memory) {
        uint256 positionsLength = positions.length;
        uint256 partCount = positionsLength + 1;
        string[] memory parts = new string[](partCount);
        uint256 start = 0;

        for (uint256 i = 0; i < positionsLength; i++) {
            parts[i] = string(sliceBytes(str, start, positions[i] - start));
            start = positions[i] + delimLength;
        }
        parts[positionsLength] = string(sliceBytes(str, start, str.length - start));

        return parts;
    }
}
