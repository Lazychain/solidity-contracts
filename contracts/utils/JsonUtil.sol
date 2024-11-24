// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { JsonParser } from "../utils/JsonParser.sol";

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

    function get(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 index = findPath(tokens, _path, _jsonBlob);
        if (index == 0) revert JsonUtil__PathNotFound();

        return JsonParser.getBytes(_jsonBlob, tokens[index].start, tokens[index].end);
    }

    function getRaw(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        // @dev: For now getRaw() == get()
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 tokenIndex = findPath(tokens, _path, _jsonBlob);
        if (tokenIndex == 0) revert JsonUtil__PathNotFound();

        return JsonParser.getBytes(_jsonBlob, tokens[tokenIndex].start, tokens[tokenIndex].end);
    }

    function getInt(string memory _jsonBlob, string memory _path) internal pure returns (int256) {
        string memory value = getRaw(_jsonBlob, _path);
        return JsonParser.parseInt(value);
    }

    function getUint(string memory _jsonBlob, string memory _path) internal pure returns (uint256) {
        int256 value = getInt(_jsonBlob, _path);
        if (value < 0) revert JsonUtil__TypeMismatch(); // uint can't be -ve
        return uint256(value);
    }

    function getBool(string memory _jsonBlob, string memory _path) internal pure returns (bool) {
        string memory value = getRaw(_jsonBlob, _path);
        return JsonParser.parseBool(value);
    }

    function dataURI(string memory _jsonBlob) internal pure returns (string memory) {}

    function exists(string memory _jsonBlob, string memory _path) internal pure returns (bool) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) return false;
        return findPath(tokens, _path, _jsonBlob) != 0;
    }

    function validate(string memory _jsonBlob) internal pure returns (bool) {
        (uint8 returnCode, , ) = JsonParser.parse(_jsonBlob, MAX_TOKENS);
        return returnCode == JsonParser.RETURN_SUCCESS;
    }

    function compact(string memory _jsonBlob) internal pure returns (string memory) {}

    function set(
        string memory _jsonBlob,
        string memory _path,
        string memory _value
    ) internal pure returns (string memory) {
        return setValueAtPath(_jsonBlob, _path, _value, false);
    }

    function set(
        string memory _jsonBlob,
        string[] memory _paths,
        string[] memory _values
    ) internal pure returns (string memory) {
        require(_paths.length == _values.length, "Length mismatch");
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < _paths.length; i++) {
            result = set(result, _paths[i], _values[i]);
        }
        return result;
    }

    function setRaw(
        string memory _jsonBlob,
        string memory _path,
        string memory _rawBlob
    ) internal pure returns (string memory) {
        return setValueAtPath(_jsonBlob, _path, _rawBlob, true);
    }

    function setRaw(
        string memory _jsonBlob,
        string[] memory _paths,
        string[] memory _rawBlobs
    ) internal pure returns (string memory) {}

    function setInt(string memory _jsonBlob, string memory _path, int256 _value) internal pure returns (string memory) {
        return set(_jsonBlob, _path, JsonParser.uint2str(uint256(_value)));
    }

    function setInt(
        string memory _jsonBlob,
        string[] memory _paths,
        int256[] memory _values
    ) internal pure returns (string memory) {
        require(_paths.length == _values.length, "Length mismatch");
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < _paths.length; i++) {
            result = setInt(result, _paths[i], _values[i]);
        }
        return result;
    }

    function setUint(
        string memory _jsonBlob,
        string memory _path,
        uint256 _value
    ) internal pure returns (string memory) {
        return set(_jsonBlob, _path, JsonParser.uint2str(_value));
    }

    function setUint(
        string memory _jsonBlob,
        string[] memory _paths,
        uint256[] memory _values
    ) internal pure returns (string memory) {
        require(_paths.length == _values.length, "Length mismatch");
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < _paths.length; i++) {
            result = setUint(result, _paths[i], _values[i]);
        }
        return result;
    }

    function setBool(string memory _jsonBlob, string memory _path, bool _value) internal pure returns (string memory) {
        return set(_jsonBlob, _path, _value ? "true" : "false");
    }

    function setBool(
        string memory _jsonBlob,
        string[] memory _paths,
        bool[] memory _values
    ) internal pure returns (string memory) {
        require(_paths.length == _values.length, "Length mismatch");
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < _paths.length; i++) {
            result = setBool(result, _paths[i], _values[i]);
        }
        return result;
    }

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
        require(_replacePaths.length == _values.length, "Length mismatch");
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < _replacePaths.length; i++) {
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
        require(_replacePaths.length == _values.length, "Length mismatch");
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < _replacePaths.length; i++) {
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
        require(_replacePaths.length == _values.length, "Length mismatch");
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < _replacePaths.length; i++) {
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
        require(_replacePaths.length == _values.length, "Length mismatch");
        string memory result = _jsonBlob;
        for (uint256 i = 0; i < _replacePaths.length; i++) {
            result = subReplaceBool(result, _searchPath, _replacePaths[i], _values[i]);
        }
        return result;
    }

    function remove(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 tokenIndex = findPath(tokens, _path, _jsonBlob);
        if (tokenIndex == 0) revert JsonUtil__PathNotFound();

        // Create new JSON without the removed path
        bytes memory result = new bytes(bytes(_jsonBlob).length);
        uint256 resultIndex = 0;

        // Copy everything before the token
        for (uint256 i = 0; i < tokens[tokenIndex].start; i++) {
            result[resultIndex++] = bytes(_jsonBlob)[i];
        }

        // Skip the token and trailing comma if present
        uint256 skipTo = tokens[tokenIndex].end;
        if (skipTo < bytes(_jsonBlob).length && bytes(_jsonBlob)[skipTo] == ",") {
            skipTo++;
        }

        // Copy everything after
        for (uint256 i = skipTo; i < bytes(_jsonBlob).length; i++) {
            result[resultIndex++] = bytes(_jsonBlob)[i];
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
    function parseJson(string memory _jsonBlob) internal pure returns (JsonParser.Token[] memory, uint256) {
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(_jsonBlob, MAX_TOKENS);
        if (returnCode != JsonParser.RETURN_SUCCESS || count == 0) revert JsonUtil__InvalidJson();
        return (tokens, count);
    }

    function findPath(
        JsonParser.Token[] memory tokens,
        string memory path,
        string memory jsonBlob
    ) internal pure returns (uint256) {
        bytes memory pathBytes = bytes(path);
        if (pathBytes.length == 0) revert JsonUtil__InvalidJsonPath();

        uint256 currentToken = 0;
        uint256 startIndex = 0;
        bool foundDot = false;

        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (pathBytes[i] == ".") {
                if (i == 0 || i == pathBytes.length - 1 || foundDot) {
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
        if (startIndex < pathBytes.length) {
            string memory finalSegment = substring(path, startIndex, pathBytes.length);
            currentToken = processPathSegment(tokens, currentToken, finalSegment, jsonBlob);
            if (currentToken == 0) revert JsonUtil__PathNotFound();
        }

        return currentToken;
    }

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
        for (uint256 i = parentToken + 1; i < tokens.length && arrayIndex <= index; i++) {
            if (tokens[i].startSet && arrayIndex == index) {
                return i;
            }
            arrayIndex++;
        }

        revert JsonUtil__PathNotFound();
    }

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

    function substring(string memory str, uint256 startIndex, uint256 endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex <= endIndex && endIndex <= strBytes.length, "Invalid substring indices");

        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

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

        // Create new JSON with updated value
        bytes memory result = new bytes(bytes(_jsonBlob).length + bytes(_value).length);
        uint256 resultIndex = 0;

        // Copy until value position
        for (uint256 i = 0; i < tokens[tokenIndex].start; i++) {
            result[resultIndex++] = bytes(_jsonBlob)[i];
        }

        // Insert new value
        bytes memory valueBytes = bytes(isRaw ? _value : formatJsonValue(_value));
        for (uint256 i = 0; i < valueBytes.length; i++) {
            result[resultIndex++] = valueBytes[i];
        }

        // Copy rest of JSON
        for (uint256 i = tokens[tokenIndex].end; i < bytes(_jsonBlob).length; i++) {
            result[resultIndex++] = bytes(_jsonBlob)[i];
        }

        // Trim to actual size
        bytes memory finalResult = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            finalResult[i] = result[i];
        }

        return string(finalResult);
    }

    function formatJsonValue(string memory value) private pure returns (string memory) {
        return string(abi.encodePacked('"', value, '"'));
    }

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
