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

    // solhint-enable private-vars-leading-underscore

    function get(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 index = findPath(tokens, _path);
        if (index == 0) revert JsonUtil__PathNotFound();

        return JsonParser.getBytes(_jsonBlob, tokens[index].start, tokens[index].end);
    }

    function getRaw(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {
        // @dev: For now getRaw() == get()
        (JsonParser.Token[] memory tokens, uint256 count) = parseJson(_jsonBlob);
        if (count == 0) revert JsonUtil__InvalidJson();

        uint256 tokenIndex = findPath(tokens, _path);
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
        try this.findPath(_jsonBlob, _path) returns (uint256 index) {
            return index > 0;
        } catch {
            return false;
        }
    }

    function validate(string memory _jsonBlob) internal pure returns (bool) {
        try this.parseJson(_jsonBlob) returns (JsonParser.Token[] memory, uint256 count) {
            return count > 0;
        } catch {
            return false;
        }
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
    ) internal pure returns (string memory) {}

    function subReplace(
        string memory _jsonBlob,
        string memory _searchPath,
        string[] memory _replacePaths,
        string[] memory _values
    ) internal pure returns (string memory) {}

    function subReplaceInt(
        string memory _jsonBlob,
        string memory _searchPath,
        string memory _replacePath,
        int256 _value
    ) internal pure returns (string memory) {}

    function subReplaceInt(
        string memory _jsonBlob,
        string memory _searchPath,
        string[] memory _replacePaths,
        int256[] memory _values
    ) internal pure returns (string memory) {}

    function subReplaceUint(
        string memory _jsonBlob,
        string memory _searchPath,
        string memory _replacePath,
        uint256 _value
    ) internal pure returns (string memory) {}

    function subReplaceUint(
        string memory _jsonBlob,
        string memory _searchPath,
        string[] memory _replacePaths,
        uint256[] memory _values
    ) internal pure returns (string memory) {}

    function subReplaceBool(
        string memory _jsonBlob,
        string memory _searchPath,
        string memory _replacePath,
        bool _value
    ) internal pure returns (string memory) {}

    function subReplaceBool(
        string memory _jsonBlob,
        string memory _searchPath,
        string[] memory _replacePaths,
        bool[] memory _values
    ) internal pure returns (string memory) {}

    function remove(string memory _jsonBlob, string memory _path) internal pure returns (string memory) {}

    /////////////
    // HELPERS //
    /////////////
    function parseJson(string memory _jsonBlob) internal pure returns (JsonParser.Token[] memory, uint256) {
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(_jsonBlob, MAX_TOKENS);
        if (returnCode != JsonParser.RETURN_SUCCESS) revert JsonUtil__InvalidJson();
        return (tokens, count);
    }

    function findPath(JsonParser.Token[] memory tokens, string memory path) internal pure returns (uint256) {
        // need to take care of `.` to get correct vals
        bytes memory pathBytes = bytes(path);
        (uint256 currentToken, uint256 startIndex) = (0, 0);

        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (i == pathBytes.length || pathBytes[i] == ".") {
                if (startIndex == i) revert JsonUtil__InvalidJsonPath();

                string memory segment = substring(path, startIndex, i);

                currentToken = findToken(tokens, currentToken, segment);
                if (currentToken == 0) revert JsonUtil__PathNotFound();

                startIndex = i + 1;
            }
        }
    }

    function findToken(
        JsonParser.Token[] memory tokens,
        uint256 parentToken,
        string memory key
    ) private pure returns (uint256) {
        JsonParser.Token memory parent = tokens[parentToken];

        // Traverse child tokens
        for (uint256 i = parentToken + 1; i < tokens.length; i++) {
            if (tokens[i].startSet && JsonParser.strCompare(key, getTokenValue(tokens[i])) == 0) {
                // ToDo: getTokenValue impl
                return i;
            }
        }

        return 0;
    }

    function substring(string memory str, uint256 startIndex, uint256 endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
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

        uint256 tokenIndex = findPath(tokens, _path);
        if (tokenIndex == 0) revert JsonUtil__PathNotFound();

        // Create new JSON with updated value
        bytes memory result = new bytes(_jsonBlob.length + _value.length);
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

    function getTokenValue(JsonParser.Token memory token) private pure returns (string memory) {
        if (token.jsonType == JsonParser.JsonType.STRING) {
            return
                JsonParser.getBytes(
                    string(token.start + 1, token.end) // +1 to skip opening quote
                );
        } else if (token.jsonType == JsonParser.JsonType.PRIMITIVE) {
            return JsonParser.getBytes(string(token.start, token.end));
        }
        return "";
    }
}
