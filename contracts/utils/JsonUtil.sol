// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
    error JsonUtil__InvalidJsonPath();
    error LengthMismatch();
    error InvalidSubstringIndices();

    /// @notice Retrieves a string value from a JSON blob at a specified path
    /// @param _jsonBlob The JSON string to parse
    /// @param _path The path to the desired value (e.g., "user.name")
    /// @return The string value at the specified path
    function get(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 index = findPath(tokens, _path, _jsonBlob);
        if (index == 0) revert JsonUtil__PathNotFound();

        return JsonParser.getBytes(_jsonBlob, tokens[index].start, tokens[index].end);
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
        string memory value = getRaw(_jsonBlob, _path);
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
        if (pathsLength == _values.length) revert LengthMismatch();
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
        if (pathsLength == _values.length) revert LengthMismatch();
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
        if (pathsLength == _values.length) revert LengthMismatch();
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
        if (pathsLength == _values.length) revert LengthMismatch();
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
        if (replacePathsLength == _values.length) revert LengthMismatch();
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
        if (replacePathsLength == _values.length) revert LengthMismatch();
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
        if (replacePathsLength == _values.length) revert LengthMismatch();
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
        if (replacePathsLength == _values.length) revert LengthMismatch();
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
        uint256 pathBytesLength = pathBytes.length;
        if (pathBytesLength == 0) revert JsonUtil__InvalidJsonPath();

        uint256 currentToken = 0;
        uint256 startIndex = 0;
        bool foundDot = false;

        for (uint256 i = 0; i < pathBytesLength; i++) {
            if (pathBytes[i] == ".") {
                if (i == 0 || i == pathBytesLength - 1 || foundDot) {
                    revert JsonUtil__InvalidJsonPath();
                }
                if (startIndex < i) {
                    string memory segment = substring(path, startIndex, i);
                    currentToken = processPathSegment(tokens, currentToken, segment, jsonBlob);
                    if (currentToken == 0) revert JsonUtil__PathNotFound();
                }
                startIndex = i + 1;
                foundDot = true;
            } else {
                foundDot = false;
            }
        }

        // Process final segment
        if (startIndex < pathBytesLength) {
            string memory finalSegment = substring(path, startIndex, pathBytesLength);
            currentToken = processPathSegment(tokens, currentToken, finalSegment, jsonBlob);
            if (currentToken == 0) revert JsonUtil__PathNotFound();
        }

        return currentToken;
    }

    /// @notice Processes a segment of a JSON path
    /// @dev Handles both object properties and array indices
    /// @param tokens Array of parsed tokens
    /// @param parentToken Index of parent token
    /// @param segment Path segment to process
    /// @param jsonBlob Original JSON string
    /// @return Index of found token
    function processPathSegment(
        JsonParser.Token[] memory tokens,
        uint256 parentToken,
        string memory segment,
        string memory jsonBlob
    ) private pure returns (uint256) {
        bytes memory segBytes = bytes(segment);

        // Check if segment is array access
        if (segBytes.length > 2 && segBytes[0] == "[" && segBytes[segBytes.length - 1] == "]") {
            // Extract the index part without using slice notation
            string memory indexStr = substring(segment, 1, segBytes.length - 1);
            return processArrayAccess(tokens, parentToken, indexStr);
        }

        return findToken(tokens, parentToken, segment, jsonBlob);
    }

    /// @notice Processes array access in JSON path
    /// @dev Handles numeric index access for arrays
    /// @param tokens Array of parsed tokens
    /// @param parentToken Index of parent token
    /// @param indexStr String representation of array index
    /// @return Index of found token
    function processArrayAccess(
        JsonParser.Token[] memory tokens,
        uint256 parentToken,
        string memory indexStr
    ) private pure returns (uint256) {
        uint256 index = uint256(JsonParser.parseInt(indexStr));
        JsonParser.Token memory parent = tokens[parentToken];

        if (parent.jsonType != JsonParser.JsonType.ARRAY) {
            revert JsonUtil__PathNotFound();
        }

        uint256 arrayIndex = 0;
        uint256 tokensLength = tokens.length;
        for (uint256 i = parentToken + 1; i < tokensLength && arrayIndex <= index; i++) {
            if (tokens[i].startSet && arrayIndex == index) {
                return i;
            }
            arrayIndex++;
        }

        revert JsonUtil__PathNotFound();
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
        if (parentToken >= tokens.length) return 0;

        JsonParser.Token memory parent = tokens[parentToken];
        bool isObject = parent.jsonType == JsonParser.JsonType.OBJECT;
        bool isArray = parent.jsonType == JsonParser.JsonType.ARRAY;

        // For array access, try to parse key as index
        if (isArray) {
            return findArrayToken(tokens, parentToken, key);
        }

        // Calculate how many tokens to search through
        uint256 searchEnd = parent.size > 0 ? parentToken + parent.size : tokens.length;
        if (searchEnd > tokens.length) searchEnd = tokens.length;

        // For objects, look for key:value pairs
        if (isObject) {
            for (uint256 i = parentToken + 1; i < searchEnd; i += 2) {
                // Step by 2 for key:value pairs
                if (!tokens[i].startSet) continue;

                // Get the key name without quotes
                string memory keyName = JsonParser.getBytes(
                    jsonBlob,
                    tokens[i].start + 1, // Skip opening quote
                    tokens[i].end - 1 // Skip closing quote
                );

                if (JsonParser.strCompare(keyName, key) == 0) {
                    if (i + 1 >= tokens.length) return 0; // Safety check
                    return i + 1; // Return index of value
                }
            }
        }

        return 0;
    }

    /// @notice Finds a token in an array by index
    /// @dev Converts string index to number and finds corresponding token
    /// @param tokens Array of parsed tokens
    /// @param parentToken Index of parent token
    /// @param indexStr String representation of array index
    /// @return Index of found token
    function findArrayToken(
        JsonParser.Token[] memory tokens,
        uint256 parentToken,
        string memory indexStr
    ) private pure returns (uint256) {
        // Try to parse index
        int256 index = JsonParser.parseInt(indexStr);
        if (index < 0) return 0;

        JsonParser.Token memory parent = tokens[parentToken];
        uint256 arrayIndex = 0;
        uint256 searchEnd = parentToken + parent.size;

        if (searchEnd > tokens.length) searchEnd = tokens.length;

        for (uint256 i = parentToken + 1; i < searchEnd; i++) {
            if (tokens[i].startSet) {
                if (arrayIndex == uint256(index)) {
                    return i;
                }
                arrayIndex++;
            }
        }

        return 0;
    }

    /// @notice Extracts substring from a string
    /// @dev Used for path parsing and value extraction
    /// @param str Source string
    /// @param startIndex Start index of substring
    /// @param endIndex End index of substring
    /// @return Extracted substring
    function substring(string memory str, uint256 startIndex, uint256 endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (startIndex <= endIndex && endIndex <= strBytes.length) revert InvalidSubstringIndices();

        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
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

    /// @notice Extracts value from a token
    /// @dev Handles different token types (string, primitive)
    /// @param token Token to extract value from
    /// @param jsonString Original JSON string
    /// @return Extracted value as string
    function getTokenValue(
        JsonParser.Token memory token,
        string memory jsonString
    ) private pure returns (string memory) {
        if (token.jsonType == JsonParser.JsonType.STRING) {
            return JsonParser.getBytes(jsonString, token.start + 1, token.end - 1); // -1 to skip closing quote
        } else if (token.jsonType == JsonParser.JsonType.PRIMITIVE) {
            return JsonParser.getBytes(jsonString, token.start, token.end);
        }
        return "";
    }
}
