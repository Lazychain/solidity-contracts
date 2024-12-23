// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { JsonUtil } from "../utils/JsonUtil.sol";
import { Strings } from "../utils/Strings.sol";
import { ITokenMetadata } from "../interfaces/metadata/ITokenMetadata.sol";
import {JsonParser} from "../utils/JsonParser.sol";

library TokenMetadataReader {
    error TokenMetadataReader__TraitNotFound(string);
    error TokenMetadataReader__InvalidType();

    function exists(address _tokenAddress, uint256 _tokenId) internal view returns (bool) {
        return ITokenMetadata(_tokenAddress).exists(_tokenId);
    }

    function exists(address _tokenAddress, uint256 _tokenId, string memory _path) internal view returns (bool) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        return JsonUtil.exists(metadata, _path);
    }

    function getTokenMetadata(address _tokenAddress, uint256 _tokenId) internal view returns (string memory) {
        return ITokenMetadata(_tokenAddress).getTokenMetadata(_tokenId);
    }

    function getTokenMetadata(
        address _tokenAddress,
        uint256 _tokenId,
        string memory _path
    ) internal view returns (string memory) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        return JsonUtil.get(metadata, _path);
    }

    function getTokenMetadataInt(
        address _tokenAddress,
        uint256 _tokenId,
        string memory _path
    ) internal view returns (int256) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        return JsonUtil.getInt(metadata, _path);
    }

    function getTokenMetadataUint(
        address _tokenAddress,
        uint256 _tokenId,
        string memory _path
    ) internal view returns (uint256) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        return JsonUtil.getUint(metadata, _path);
    }

    function getTokenMetadataBool(
        address _tokenAddress,
        uint256 _tokenId,
        string memory _path
    ) internal view returns (bool) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        return JsonUtil.getBool(metadata, _path);
    }

    /// @dev Get attribute value for a specific trait_type
    function getTokenAttribute(
        address _tokenAddress,
        uint256 _tokenId,
        string memory _traitType
    ) internal view returns (string memory) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);

        // Iterate through attributes array to find matching trait_type
        for (uint256 i = 0; i < 10; i++) {
            if (!JsonUtil.exists(metadata, _tap(i))) {
                break; // End of attributes array
            }

            string memory trait = JsonUtil.get(metadata, _tap(i));
            if (stringsEqual(trait, _traitType)) {
                return JsonUtil.get(metadata, _tavp(i));
            }
        }
        revert TokenMetadataReader__TraitNotFound(_traitType);
    }

    function slice(
        string memory str,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }

    function getTokenAttributeInt(
        address _tokenAddress,
        uint256 _tokenId,
        string memory _traitType
    ) internal view returns (int256) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        (JsonParser.Token[] memory tokens, uint256 count) = JsonUtil.parseJson(metadata);
        
        uint256 pos = 7;
        while (pos < count) {
            if (tokens[pos].jsonType == JsonParser.JsonType.OBJECT) {
                string memory trait = JsonParser.getBytes(metadata, tokens[pos + 2].start, tokens[pos + 2].end);
                
                // The trait value might have quotes
                if (bytes(trait).length >= 2 && bytes(trait)[0] == '"') {
                    trait = JsonParser.getBytes(metadata, tokens[pos + 2].start + 1, tokens[pos + 2].end - 1);
                }
                
                if (JsonParser.strCompare(trait, _traitType) == 0) {
                    string memory value = JsonParser.getBytes(metadata, tokens[pos + 4].start, tokens[pos + 4].end);
                    return JsonParser.parseInt(value);
                }
                pos += 5;
            } else {
                pos++;
            }
        }
        
        revert TokenMetadataReader__TraitNotFound(_traitType);
    }

    function getTokenAttributeUint(
        address _tokenAddress,
        uint256 _tokenId, 
        string memory _traitType
    ) internal view returns (uint256) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        (JsonParser.Token[] memory tokens, uint256 count) = JsonUtil.parseJson(metadata);
        
        uint256 pos = 7;
        while (pos < count) {
            if (tokens[pos].jsonType == JsonParser.JsonType.OBJECT) {
                string memory trait = JsonParser.getBytes(metadata, tokens[pos + 2].start, tokens[pos + 2].end);
                // Handle quotes in trait value
                if (bytes(trait).length >= 2 && bytes(trait)[0] == '"') {
                    trait = JsonParser.getBytes(metadata, tokens[pos + 2].start + 1, tokens[pos + 2].end - 1);
                }
                
                if (JsonParser.strCompare(trait, _traitType) == 0) {
                    string memory value = JsonParser.getBytes(metadata, tokens[pos + 4].start, tokens[pos + 4].end);
                    int256 parsedValue = JsonParser.parseInt(value);
                    if(parsedValue < 0) revert TokenMetadataReader__InvalidType();
                    return uint256(parsedValue);
                }
                pos += 5;
            } else {
                pos++;
            }
        }
        revert TokenMetadataReader__TraitNotFound(_traitType);
    }
 
    function getTokenAttributeBool(
        address _tokenAddress,
        uint256 _tokenId, 
        string memory _traitType
    ) internal view returns (bool) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        (JsonParser.Token[] memory tokens, uint256 count) = JsonUtil.parseJson(metadata);
        
        uint256 pos = 7;
        while (pos < count) {
            if (tokens[pos].jsonType == JsonParser.JsonType.OBJECT) {
                string memory trait = JsonParser.getBytes(metadata, tokens[pos + 2].start, tokens[pos + 2].end);
                // Handle quotes in trait value
                if (bytes(trait).length >= 2 && bytes(trait)[0] == '"') {
                    trait = JsonParser.getBytes(metadata, tokens[pos + 2].start + 1, tokens[pos + 2].end - 1);
                }
                
                if (JsonParser.strCompare(trait, _traitType) == 0) {
                    string memory value = JsonParser.getBytes(metadata, tokens[pos + 4].start, tokens[pos + 4].end);
                    return JsonParser.parseBool(value);
                }
                pos += 5;
            } else {
                pos++;
            }
        }
        revert TokenMetadataReader__TraitNotFound(_traitType);
    }

  function hasTokenAttribute(
    address _tokenAddress,
    uint256 _tokenId,
    string memory _traitType
    ) internal view returns (bool) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);
        (JsonParser.Token[] memory tokens, uint256 count) = JsonUtil.parseJson(metadata);
        
        uint256 pos = 7; // Start after attributes array token
        while (pos < count) {
            if (tokens[pos].jsonType == JsonParser.JsonType.OBJECT) {
                string memory trait = JsonParser.getBytes(metadata, tokens[pos + 2].start, tokens[pos + 2].end);
                
                // Handle quotes in trait value
                if (bytes(trait).length >= 2 && bytes(trait)[0] == '"') {
                    trait = JsonParser.getBytes(metadata, tokens[pos + 2].start + 1, tokens[pos + 2].end - 1);
                }
                
                if (stringsEqual(trait, _traitType)) {
                    return true;
                }
                pos += 5;
            } else {
                pos++;
            }
        }
        return false;
    }

    function _tap(uint256 index) internal pure returns (string memory) {
        return string(abi.encodePacked("attributes[", toString(index), "].trait_type"));
    }

    function _tavp(uint256 index) internal pure returns (string memory) {
        return string(abi.encodePacked("attributes[", toString(index), "].value"));
    }

    /// @dev Helper for number to string conversion
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /// @dev Helper for string comparison
    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
