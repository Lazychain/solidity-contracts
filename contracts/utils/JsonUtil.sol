// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { JsonParser } from "../utils/JsonParser.sol";

/// @title JsonUtil Library
/// @notice A utility library for working with JSON data in Solidity
/// @dev Uses JsonParser library for low-level JSON parsing operations
library JsonUtil {
    using JsonParser for JsonParser.Token;

    uint8 private constant MAX_TOKENS = 128; // Experimental constant

    ////////////
    // ERRORS //
    ////////////
    error JsonUtil__InvalidJson();
    error JsonUtil__PathNotFound();
    error JsonUtil__TypeMismatch();
    error JsonUtil__InvalidNumber();
    error JsonUtil__LengthMismatch();
    error JsonUtil__InvalidJsonPath();
    error JsonUtil__EndIndexOutofBounds();
    error JsonUtil__InvalidSubstringIndices();

    /// @notice Retrieves a string value from a JSON blob at a specified path
    /// @param _jsonBlob The JSON string to parse
    /// @param _path The path to the desired value (e.g., "user.name")
    /// @return The string value at the specified path
    function get(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 tokenIndex = findPath(tokens, _path, _jsonBlob);
        if (tokenIndex == 0) revert JsonUtil__PathNotFound();

        JsonParser.Token memory token = tokens[tokenIndex];

        // For string values, remove quotes
        if (token.jsonType == JsonParser.JsonType.STRING) {
            return JsonParser.getBytes(_jsonBlob, token.start + 1, token.end - 1);
        }

        // For other values (numbers, booleans), return as is
        return JsonParser.getBytes(_jsonBlob, token.start, token.end);
    }

    /// @notice Gets raw JSON value at specified path without processing
    /// @param _jsonBlob The JSON string to parse
    /// @param _path The path to the desired value
    /// @return Raw string value at the specified path
    function getRaw(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        // @dev: For now getRaw() == get()
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 tokenIndex = findPath(tokens, _path, _jsonBlob);
        if (tokenIndex == 0) revert JsonUtil__PathNotFound();

        return JsonParser.getBytes(_jsonBlob, tokens[tokenIndex].start, tokens[tokenIndex].end);
    }

    /// @notice Gets an integer value from JSON at specified path
    /// @param _jsonBlob The JSON string to parse
    /// @param _path The path to the desired value
    /// @return The integer value at the specified path
    function getInt(string memory _jsonBlob, string memory _path) internal pure returns (int256) {
        string memory value = getRaw(_jsonBlob, _path);
        return JsonParser.parseInt(value);
    }

    /// @notice Gets an unsigned integer value from JSON at specified path
    /// @param _jsonBlob The JSON string to parse
    /// @param _path The path to the desired value
    /// @return The unsigned integer value at the specified path
    function getUint(string memory _jsonBlob, string memory _path) internal pure returns (uint256) {
        int256 value = getInt(_jsonBlob, _path);
        if (value < 0) revert JsonUtil__TypeMismatch(); // uint can't be -ve
        return uint256(value);
    }

    /// @notice Gets a boolean value from JSON at specified path
    /// @param _jsonBlob The JSON string to parse
    /// @param _path The path to the desired value
    /// @return The boolean value at the specified path
    function getBool(string memory _jsonBlob, string memory _path) internal pure returns (bool) {
        string memory value = get(_jsonBlob, _path);
        return JsonParser.parseBool(value);
    }

    /// @notice Converts JSON to a data URI format
    /// @dev Creates data URI representation of JSON
    /// @param _jsonBlob JSON string to convert
    /// @return Data URI string
    // solhint-disable no-empty-blocks
    function dataURI(string memory _jsonBlob) internal pure returns (string memory) {}

    /// @notice Checks if a path exists in the JSON blob
    /// @param _jsonBlob The JSON string to parse
    /// @param _path The path to check
    /// @return True if the path exists, false otherwise
    function exists(string memory _jsonBlob, string memory _path) internal pure returns (bool) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) return false;
        return findPath(tokens, _path, _jsonBlob) != 0;
    }

    /// @notice Validates if a string is valid JSON
    /// @param _jsonBlob The JSON string to validate
    /// @return True if valid JSON, false otherwise
    function validate(string memory _jsonBlob) internal pure returns (bool) {
        (uint8 returnCode, , ) = JsonParser.parse(_jsonBlob, MAX_TOKENS);
        return returnCode == JsonParser.RETURN_SUCCESS;
    }

    /// @notice Compacts JSON by removing whitespace
    /// @dev Removes unnecessary spacing while preserving structure
    /// @param _jsonBlob JSON string to compact
    /// @return Compacted JSON string
    // solhint-disable no-empty-blocks
    function compact(string memory _jsonBlob) internal pure returns (string memory) {}

    /// @notice Sets a string value in JSON at specified path
    /// @param _jsonBlob The JSON string to modify
    /// @param _path The path where to set the value
    /// @param _value The string value to set
    /// @return Updated JSON string
    function set(
        string memory _jsonBlob,
        string memory _path,
        string memory _value
    ) internal pure returns (string memory) {
        return setValueAtPath(_jsonBlob, _path, _value, false);
    }

    /// @notice Sets multiple string values in JSON at specified paths
    /// @param _jsonBlob The JSON string to modify
    /// @param _paths Array of paths where to set values
    /// @param _values Array of values to set
    /// @return Updated JSON string
    function set(
        string memory _jsonBlob,
        string[] memory _paths,
        string[] memory _values
    ) internal pure returns (string memory) {
        uint256 pathsLength = _paths.length;
        if (pathsLength == _values.length) revert JsonUtil__LengthMismatch();
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < pathsLength; i++) {
            result = set(result, _paths[i], _values[i]);
        }
        return result;
    }

    /// @notice Sets a raw JSON value at specified path
    /// @param _jsonBlob The JSON string to modify
    /// @param _path The path where to set the value
    /// @param _rawBlob The raw JSON value to set
    /// @return Updated JSON string
    function setRaw(
        string memory _jsonBlob,
        string memory _path,
        string memory _rawBlob
    ) internal pure returns (string memory) {
        return setValueAtPath(_jsonBlob, _path, _rawBlob, true);
    }

    /// @notice Sets multiple raw JSON values at specified paths
    /// @dev Applies multiple raw value updates sequentially
    /// @param _jsonBlob JSON string to modify
    /// @param _paths Array of paths
    /// @param _rawBlobs Array of raw JSON values
    /// @return Modified JSON string
    function setRaw(
        string memory _jsonBlob,
        string[] memory _paths,
        string[] memory _rawBlobs
    ) internal pure returns (string memory) {}

    /// @notice Sets an integer value in JSON at specified path
    /// @param _jsonBlob The JSON string to modify
    /// @param _path The path where to set the value
    /// @param _value The integer value to set
    /// @return Updated JSON string
    function setInt(string memory _jsonBlob, string memory _path, int256 _value) internal pure returns (string memory) {
        return set(_jsonBlob, _path, JsonParser.uint2str(uint256(_value)));
    }

    /// @notice Sets multiple integer values in JSON at specified paths
    /// @param _jsonBlob The JSON string to modify
    /// @param _paths Array of paths where to set values
    /// @param _values Array of integer values to set
    /// @return Updated JSON string
    function setInt(
        string memory _jsonBlob,
        string[] memory _paths,
        int256[] memory _values
    ) internal pure returns (string memory) {
        uint256 pathsLength = _paths.length;
        if (pathsLength == _values.length) revert JsonUtil__LengthMismatch();
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < pathsLength; i++) {
            result = setInt(result, _paths[i], _values[i]);
        }
        return result;
    }

    /// @notice Sets an unsigned integer value in JSON at specified path
    /// @param _jsonBlob The JSON string to modify
    /// @param _path The path where to set the value
    /// @param _value The unsigned integer value to set
    /// @return Updated JSON string
    function setUint(
        string memory _jsonBlob,
        string memory _path,
        uint256 _value
    ) internal pure returns (string memory) {
        return set(_jsonBlob, _path, JsonParser.uint2str(_value));
    }

    /// @notice Sets multiple unsigned integer values in JSON at specified paths
    /// @param _jsonBlob The JSON string to modify
    /// @param _paths Array of paths where to set values
    /// @param _values Array of unsigned integer values to set
    /// @return Updated JSON string
    function setUint(
        string memory _jsonBlob,
        string[] memory _paths,
        uint256[] memory _values
    ) internal pure returns (string memory) {
        uint256 pathsLength = _paths.length;
        if (pathsLength == _values.length) revert JsonUtil__LengthMismatch();
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < pathsLength; i++) {
            result = setUint(result, _paths[i], _values[i]);
        }
        return result;
    }

    /// @notice Sets a boolean value in JSON at specified path
    /// @param _jsonBlob The JSON string to modify
    /// @param _path The path where to set the value
    /// @param _value The boolean value to set
    /// @return Updated JSON string
    function setBool(string memory _jsonBlob, string memory _path, bool _value) internal pure returns (string memory) {
        return set(_jsonBlob, _path, _value ? "true" : "false");
    }

    /// @notice Sets multiple boolean values in JSON at specified paths
    /// @param _jsonBlob The JSON string to modify
    /// @param _paths Array of paths where to set values
    /// @param _values Array of boolean values to set
    /// @return Updated JSON string
    function setBool(
        string memory _jsonBlob,
        string[] memory _paths,
        bool[] memory _values
    ) internal pure returns (string memory) {
        uint256 pathsLength = _paths.length;
        if (pathsLength == _values.length) revert JsonUtil__LengthMismatch();
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < pathsLength; i++) {
            result = setBool(result, _paths[i], _values[i]);
        }
        return result;
    }

    /// @notice Replaces values in JSON based on a search path
    /// @param _jsonBlob The JSON string to modify
    /// @param _searchPath Path to search for
    /// @param _replacePath Path where to replace value
    /// @param _value New value to set
    /// @return Updated JSON string
    function subReplace(
        string memory _jsonBlob,
        string memory _searchPath,
        string memory _replacePath,
        string memory _value
    ) internal pure returns (string memory) {
        // First find value at search path
        string memory searchValue = get(_jsonBlob, _searchPath);
        if (bytes(searchValue).length == 0) revert JsonUtil__PathNotFound();

        // Replace value in replacement path
        string memory replacePath = _replacePath;
        if (bytes(replacePath).length == 0) {
            replacePath = _searchPath;
        }

        return set(_jsonBlob, replacePath, _value);
    }

    function subReplace(
        string memory _jsonBlob,
        string memory _searchPath,
        string[] memory _replacePaths,
        string[] memory _values
    ) internal pure returns (string memory) {
        uint256 replacePathsLength = _replacePaths.length;
        if (replacePathsLength == _values.length) revert JsonUtil__LengthMismatch();
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < replacePathsLength; i++) {
            result = subReplace(result, _searchPath, _replacePaths[i], _values[i]);
        }
        return result;
    }

    function subReplaceInt(
        string memory _jsonBlob,
        string memory _searchPath,
        string memory _replacePath,
        int256 _value
    ) internal pure returns (string memory) {
        return subReplace(_jsonBlob, _searchPath, _replacePath, JsonParser.uint2str(uint256(_value)));
    }

    function subReplaceInt(
        string memory _jsonBlob,
        string memory _searchPath,
        string[] memory _replacePaths,
        int256[] memory _values
    ) internal pure returns (string memory) {
        uint256 replacePathsLength = _replacePaths.length;
        if (replacePathsLength == _values.length) revert JsonUtil__LengthMismatch();
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < replacePathsLength; i++) {
            result = subReplaceInt(result, _searchPath, _replacePaths[i], _values[i]);
        }
        return result;
    }

    function subReplaceUint(
        string memory _jsonBlob,
        string memory _searchPath,
        string memory _replacePath,
        uint256 _value
    ) internal pure returns (string memory) {
        return subReplace(_jsonBlob, _searchPath, _replacePath, JsonParser.uint2str(_value));
    }

    function subReplaceUint(
        string memory _jsonBlob,
        string memory _searchPath,
        string[] memory _replacePaths,
        uint256[] memory _values
    ) internal pure returns (string memory) {
        uint256 replacePathsLength = _replacePaths.length;
        if (replacePathsLength == _values.length) revert JsonUtil__LengthMismatch();
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < replacePathsLength; i++) {
            result = subReplaceUint(result, _searchPath, _replacePaths[i], _values[i]);
        }
        return result;
    }

    function subReplaceBool(
        string memory _jsonBlob,
        string memory _searchPath,
        string memory _replacePath,
        bool _value
    ) internal pure returns (string memory) {
        return subReplace(_jsonBlob, _searchPath, _replacePath, _value ? "true" : "false");
    }

    function subReplaceBool(
        string memory _jsonBlob,
        string memory _searchPath,
        string[] memory _replacePaths,
        bool[] memory _values
    ) internal pure returns (string memory) {
        uint256 replacePathsLength = _replacePaths.length;
        if (replacePathsLength == _values.length) revert JsonUtil__LengthMismatch();
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < replacePathsLength; i++) {
            result = subReplaceBool(result, _searchPath, _replacePaths[i], _values[i]);
        }
        return result;
    }

    /// @notice Removes a value at specified path from JSON
    /// @dev Handles deletion of properties and array elements
    /// @param _jsonBlob JSON string to modify
    /// @param _path Path to remove
    /// @return Modified JSON string
    function remove(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 tokenIndex = findPath(tokens, _path, _jsonBlob);
        if (tokenIndex == 0) revert JsonUtil__PathNotFound();

        // Create new JSON without the removed path
        bytes memory bytesJsonBlob = bytes(_jsonBlob);
        uint256 bytesJsonBlobLength = bytesJsonBlob.length;
        bytes memory result = new bytes(bytesJsonBlobLength);
        uint256 resultIndex = 0;

        // Copy everything before the token
        for (uint256 i = 0; i < tokens[tokenIndex].start; i++) {
            result[resultIndex++] = bytes(_jsonBlob)[i];
        }

        // Skip the token and trailing comma if present
        uint256 skipTo = tokens[tokenIndex].end;
        if (skipTo < bytesJsonBlobLength && bytesJsonBlob[skipTo] == ",") {
            skipTo++;
        }

        // Copy everything after
        for (uint256 i = skipTo; i < bytesJsonBlobLength; i++) {
            result[resultIndex++] = bytesJsonBlob[i];
        }

        bytes memory finalResult = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            finalResult[i] = result[i];
        }

        return string(finalResult);
    }

    /////////////
    // HELPERS //
    /////////////

    /// @notice Helper function to parse JSON into tokens
    /// @dev Throws JsonUtil__InvalidJson if parsing fails
    /// @param _jsonBlob The JSON string to parse
    /// @return tokens Array of parsed tokens and count
    function parseJson(string memory _jsonBlob) internal pure returns (JsonParser.Token[] memory, uint256) {
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(_jsonBlob, MAX_TOKENS);
        if (returnCode != JsonParser.RETURN_SUCCESS || count == 0) revert JsonUtil__InvalidJson();
        return (tokens, count);
    }

    /// @notice Helper function to find a token at specified path
    /// @dev Throws JsonUtil__PathNotFound if path is invalid
    /// @param tokens Array of parsed tokens
    /// @param path Path to search for
    /// @param jsonBlob Original JSON string
    /// @return Index of found token
    function findPath(
        JsonParser.Token[] memory tokens,
        string memory path,
        string memory jsonBlob
    ) internal pure returns (uint256) {
        bytes memory pathBytes = bytes(path);

        // Handle nested paths with dots
        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (pathBytes[i] == ".") {
                return handleNestedPath(tokens, path, i, jsonBlob);
            }
        }

        // Handle array access
        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (pathBytes[i] == "[") {
                return handleArrayAccess(tokens, path, i, jsonBlob);
            }
        }

        // Simple property access
        return findToken(tokens, 0, path, jsonBlob);
    }

    /// @notice Handles nested JSON path traversal with dot notation
    /// @dev Processes paths like "data.users" or "data.users[0].name"
    /// @param tokens Array of parsed JSON tokens
    /// @param path Full JSON path being processed
    /// @param dotIndex Index position of the dot in the path
    /// @param jsonBlob Original JSON string
    /// @return uint256 Token index of the found path, or 0 if not found
    /// @custom:throws JsonUtil__PathNotFound if path is invalid
    /// @custom:example path="data.users[0].name" dotIndex=4 (position of first dot)
    function handleNestedPath(
        JsonParser.Token[] memory tokens,
        string memory path,
        uint256 dotIndex,
        string memory jsonBlob
    ) private pure returns (uint256) {
        string memory firstPart = substring(path, 0, dotIndex);
        string memory remainingPath = substring(path, dotIndex + 1, bytes(path).length);

        // Check if first part contains array access
        bytes memory firstPartBytes = bytes(firstPart);
        for (uint256 i = 0; i < firstPartBytes.length; i++) {
            if (firstPartBytes[i] == "[") {
                uint256 arrayToken = handleArrayAccess(tokens, firstPart, i, jsonBlob);
                if (arrayToken == 0) return 0;
                return findPath(tokens, remainingPath, jsonBlob);
            }
        }

        uint256 firstToken = findToken(tokens, 0, firstPart, jsonBlob);
        if (firstToken == 0) return 0;

        return findPath(tokens, remainingPath, jsonBlob);
    }

    /// @notice Handles array access within JSON paths
    /// @dev Processes array indexing like "users[0]" or "[1]"
    /// @param tokens Array of parsed JSON tokens
    /// @param path JSON path containing array access
    /// @param bracketIndex Index position of the opening bracket
    /// @param jsonBlob Original JSON string
    /// @return uint256 Token index of the array element, or 0 if not found
    /// @custom:throws JsonUtil__PathNotFound if array index is invalid
    /// @custom:example path="numbers[1]" bracketIndex=7 (position of '[')
    function handleArrayAccess(
        JsonParser.Token[] memory tokens,
        string memory path,
        uint256 bracketIndex,
        string memory jsonBlob
    ) private pure returns (uint256) {
        string memory arrayName = substring(path, 0, bracketIndex);

        // Find the index of ']'
        uint256 bracketCloseIndex = bracketIndex;
        bytes memory pathBytes = bytes(path);
        for (uint256 i = bracketIndex; i < pathBytes.length; i++) {
            if (pathBytes[i] == "]") {
                bracketCloseIndex = i;
                break;
            }
        }
        require(bracketCloseIndex > bracketIndex, "No closing bracket found");

        // Extract the index string between '[' and ']'
        string memory indexStr = substring(path, bracketIndex + 1, bracketCloseIndex);
        uint256 targetIndex = strToUint(indexStr);

        // Find the ARRAY token corresponding to arrayName
        uint256 arrayToken = findToken(tokens, 0, arrayName, jsonBlob);
        if (arrayToken == 0 || tokens[arrayToken].jsonType != JsonParser.JsonType.ARRAY) return 0;

        // Now, iterate over the elements of the array to find the target index
        uint256 pos = arrayToken + 1;
        uint256 currentIndex = 0;
        uint256 arrayEnd = tokens[arrayToken].end;

        while (pos < tokens.length && tokens[pos].start < arrayEnd) {
            if (currentIndex == targetIndex) {
                return pos;
            }

            // Determine how to skip the current element
            if (
                tokens[pos].jsonType == JsonParser.JsonType.OBJECT || tokens[pos].jsonType == JsonParser.JsonType.ARRAY
            ) {
                // Skip the entire object or array by jumping to its end
                uint256 elementEnd = tokens[pos].end;
                // Find the token with end == elementEnd
                while (pos < tokens.length && tokens[pos].end < elementEnd) {
                    pos++;
                }
                pos++; // Move past the end
            } else {
                // For PRIMITIVE and STRING, just move to the next token
                pos++;
            }

            currentIndex++;
        }

        return 0; // Index out of bounds
    }

    /// @notice Converts a string representation of a number to uint256
    /// @dev Only processes positive integers
    /// @param str String containing the number to convert
    /// @return uint256 The converted number
    /// @custom:throws JsonUtil__InvalidNumber if string contains non-numeric characters
    /// @custom:example str="123" returns 123
    function strToUint(string memory str) private pure returns (uint256) {
        bytes memory b = bytes(str);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint8 digit = uint8(b[i]) - 48;
            if (digit > 9) revert JsonUtil__InvalidNumber();
            result = result * 10 + digit;
        }
        return result;
    }

    /// @notice Finds a token in an object by key
    /// @dev Handles both object and array parent tokens
    /// @param tokens Array of parsed tokens
    /// @param parentToken Index of parent token
    /// @param key Key to search for
    /// @param jsonBlob Original JSON string
    /// @return Index of found token
    function findToken(
        JsonParser.Token[] memory tokens,
        uint256 parentToken,
        string memory key,
        string memory jsonBlob
    ) private pure returns (uint256) {
        uint256 current = (parentToken == 0) ? 1 : parentToken + 1;
        JsonParser.Token memory endToken = tokens[parentToken];

        while (current < tokens.length && tokens[current].startSet) {
            // Break if we're past the parent's scope
            if (parentToken != 0 && tokens[current].start >= endToken.end) break;

            if (tokens[current].jsonType == JsonParser.JsonType.STRING) {
                string memory currentKey = JsonParser.getBytes(
                    jsonBlob,
                    tokens[current].start + 1,
                    tokens[current].end - 1
                );

                if (JsonParser.strCompare(currentKey, key) == 0) {
                    return current + 1; // Return next token which is the value
                }
            }
            current++;
        }

        return 0;
    }

    /// @notice Extracts substring from a string
    /// @dev Used for path parsing and value extraction
    /// @param str Source string
    /// @param startIndex Start index of substring
    /// @param endIndex End index of substring
    function substring(string memory str, uint256 startIndex, uint256 endIndex) private pure returns (string memory) {
        if (endIndex < startIndex) revert JsonUtil__InvalidSubstringIndices();
        if (bytes(str).length < endIndex) revert JsonUtil__EndIndexOutofBounds();

        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = 0; i < endIndex - startIndex; i++) {
            result[i] = strBytes[startIndex + i];
        }
        return string(result);
    }

    /// @notice Sets value at specified path in JSON
    /// @dev Handles both raw and formatted JSON values
    /// @param _jsonBlob JSON string to modify
    /// @param _path Path where to set value
    /// @param _value Value to set
    /// @param isRaw Whether value should be treated as raw JSON
    /// @return Modified JSON string
    function setValueAtPath(
        string memory _jsonBlob,
        string memory _path,
        string memory _value,
        bool isRaw
    ) private pure returns (string memory) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 tokenIndex = findPath(tokens, _path, _jsonBlob);
        if (tokenIndex == 0) revert JsonUtil__PathNotFound();
        bytes memory bytesJsonBlob = bytes(_jsonBlob);
        uint256 bytesJsonBlobLength = bytesJsonBlob.length;
        // Create new JSON with updated value
        bytes memory result = new bytes(bytesJsonBlobLength + bytes(_value).length);
        uint256 resultIndex = 0;

        // Copy until value position
        for (uint256 i = 0; i < tokens[tokenIndex].start; i++) {
            result[resultIndex++] = bytesJsonBlob[i];
        }

        // Insert new value
        bytes memory valueBytes = bytes(isRaw ? _value : formatJsonValue(_value));
        uint256 valueBytesLength = valueBytes.length;
        for (uint256 i = 0; i < valueBytesLength; i++) {
            result[resultIndex++] = valueBytes[i];
        }

        // Copy rest of JSON
        for (uint256 i = tokens[tokenIndex].end; i < bytesJsonBlobLength; i++) {
            result[resultIndex++] = bytesJsonBlob[i];
        }

        // Trim to actual size
        bytes memory finalResult = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            finalResult[i] = result[i];
        }

        return string(finalResult);
    }

    /// @notice Formats a string as a JSON value
    /// @dev Adds quotes around string values
    /// @param value String to format
    /// @return Formatted JSON string value
    function formatJsonValue(string memory value) private pure returns (string memory) {
        return string(abi.encodePacked('"', value, '"'));
    }
}
