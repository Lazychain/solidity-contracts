// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IIntegers } from "../interfaces/precompile/IIntegers.sol";

/**
 * @dev String operations.
 */
library Integers {
    // solhint-disable private-vars-leading-underscore
    IIntegers internal constant INTEGERS = IIntegers(0x00000000000000000000000000000f043A000006);
    // solhint-enable private-vars-leading-underscore

    error InvalidHexString();
    error InvalidHexCharacter();

    /// @dev Converts a `uint256` to its ASCII `string` decimal representation.
    function toString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            ++digits;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            --digits;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    /// @dev Converts an `int256` to its ASCII `string` decimal representation.
    function toString(int256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        bool negative = _value < 0;
        uint256 absValue = uint256(negative ? -_value : _value);
        string memory result = toString(absValue);
        return negative ? string(abi.encodePacked("-", result)) : result;
    }

    /// @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x0";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            ++length;
            temp >>= 4;
        }
        bytes memory buffer = new bytes(2 + length);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 + length - 1; i >= 2; --i) {
            buffer[i] = _toHexChar(uint8(value & 0x0f));
            value >>= 4;
        }
        return string(buffer);
    }

    /// @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 + length);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 + length - 1; i >= 2; --i) {
            buffer[i] = _toHexChar(uint8(value & 0x0f));
            value >>= 4;
        }
        for (uint256 i = 2; i < 2 + length; ++i) {
            if (buffer[i] == 0) {
                buffer[i] = "0";
            }
        }
        return string(buffer);
    }

    function _toHexChar(uint8 value) private pure returns (bytes1) {
        return value < 10 ? bytes1(uint8(value) + 0x30) : bytes1(uint8(value) + 0x57);
    }

    /// @dev Converts a hexadecimal `string` to its `uint256` representation.
    function fromHexString(string memory _str) internal pure returns (uint256) {
        bytes memory strBytes = bytes(_str);
        uint256 strBytesLength = strBytes.length;
        if (strBytesLength < 3) revert InvalidHexString();

        // Check for 0x prefix
        if (strBytes[0] != "0" || (strBytes[1] != "x" && strBytes[1] != "X")) 
            revert InvalidHexString();

        uint256 result = 0;

        for (uint256 i = 2; i < strBytesLength; ++i) {
            result = result * 16 + _fromHexChar(strBytes[i]);
        }
        return result;
    }

    /// @dev Converts a hexadecimal ASCII character to its value (0-15).
    function _fromHexChar(bytes1 _char) private pure returns (uint256) {
        uint8 charValue = uint8(_char);
        if (charValue >= 48 && charValue <= 57) {
            // '0' - '9'
            return charValue - 48;
        } else if (charValue >= 97 && charValue <= 102) {
            // 'a' - 'f'
            return charValue - 87;
        } else if (charValue >= 65 && charValue <= 70) {
            // 'A' - 'F'
            return charValue - 55;
        } else {
            revert InvalidHexCharacter();
        }
    }
}
