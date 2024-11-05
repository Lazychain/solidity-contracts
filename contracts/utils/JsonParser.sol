// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library JsonParser {
    ////////////
    // ERRORS //
    ////////////
    error JsonParser__InvalidPath(string path);
    error JsonParser__PathNotFound(string path);
    error JsonParser__InvalidJsonFormat(string json);
    error JsonParser__TypeMismatch(string path, string expectedType);

    ////////////
    // STRUCT //
    ////////////
    /// @dev  Represents any JSON value with type information
    struct JsonValue {
        string value;
        bool isObject;
        bool isArray;
        bool isString;
        bool isNumber;
        bool isBoolean;
        bool isNull;
    }

    /// @dev  For handling complex data types
    struct JsonObject {
        string[] keys;
        JsonValue[] values;
    }

    /// @dev  For handling complex data types
    struct JsonArray {
        JsonValue[] elements;
    }

    function parse(string memory _jsonBlob) external pure returns (JsonValue memory) {
        bytes memory jsonBytes = bytes(_jsonBlob);
        uint256 index = 0;

        // Ignore whitespaces
        while (
            index < jsonBytes.length &&
            (jsonBytes[index] == 0x20 || // space
                jsonBytes[index] == 0x09 || // tab
                jsonBytes[index] == 0x0A || // newline
                jsonBytes[index] == 0x0D) // carriage return
        ) {
            index++;
        }

        if (index == jsonBytes.length) {
            revert JsonParser__InvalidJsonFormat(_jsonBlob);
        }

        // Determine type of object
        if (jsonBytes[index] == 0x7B) {
            // {
            return parseObject(jsonBytes, index);
        } else if (jsonBytes[index] == 0x5B) {
            // [
            return parseArray(jsonBytes, index);
        } else if (jsonBytes[index] == 0x22) {
            // "
            return parseString(jsonBytes, index);
        } else if (
            jsonBytes[index] == 0x2D || // -
            (jsonBytes[index] >= 0x30 && jsonBytes[index] <= 0x39) // 0-9
        ) {
            return parseNumber(jsonBytes, index);
        } else if (jsonBytes[index] == 0x74) {
            // t (true)
            return parseTrue(jsonBytes, index);
        } else if (jsonBytes[index] == 0x66) {
            // f (false)
            return parseFalse(jsonBytes, index);
        } else if (jsonBytes[index] == 0x6E) {
            // n (null)
            return parseNull(jsonBytes, index);
        }

        revert JsonParser__InvalidJsonFormat(_jsonBlob);
    }

    function parseObject(bytes memory _json, uint256 _index) internal pure returns (JsonValue memory) {}

    function parseArray(bytes memory _json, uint256 _index) internal pure returns (JsonValue memory) {}

    function parseString(bytes memory _json, uint256 _index) internal pure returns (JsonValue memory) {}

    function parseNumber(bytes memory _json, uint256 _index) internal pure returns (JsonValue memory) {}

    function parseTrue(bytes memory _json, uint256 _index) internal pure returns (JsonValue memory) {}

    function parseFalse(bytes memory _json, uint256 _index) internal pure returns (JsonValue memory) {}

    function parseNull(bytes memory _json, uint256 _index) internal pure returns (JsonValue memory) {}
}
