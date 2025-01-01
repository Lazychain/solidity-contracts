// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Strings } from "../utils/Strings.sol";
import { JsonUtil } from "../utils/JsonUtil.sol";
import { JsonStore } from "../utils/JsonStore.sol";
import { JsonParser } from "../utils/JsonParser.sol";
import { ITokenMetadata, Attribute, StdTokenMetadata } from "../interfaces/metadata/ITokenMetadata.sol";

contract TokenMetadata is ITokenMetadata {
    using JsonStore for JsonStore.Store;
    JsonStore.Store internal _store;

    error TokenMetadata__InvalidType();
    error TokenMetadata__TraitNotFound(string);

    /// @dev Indicates whether any token exist with a given id, or not.
    function exists(uint256 _tokenId) external view virtual returns (bool) {
        return _exists(_tokenId);
    }

    /// @dev Returns the URI of the token with the given id.
    function uri(uint256 _tokenId) external view virtual returns (string memory) {
        return _uri(_tokenId);
    }

    /// @dev Returns the URI of the token with the given id.
    function tokenURI(uint256 _tokenId) external view virtual returns (string memory) {
        return _uri(_tokenId);
    }

    function getTokenMetadata(uint256 _tokenId) external view virtual returns (string memory) {
        return _getTokenMetadata(_tokenId);
    }

    function _uri(uint256 _tokenId) internal view virtual returns (string memory) {
        return JsonStore.uri(_store, _getTokenMetadataKey(_tokenId));
    }

    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return JsonStore.exists(_store, _getTokenMetadataKey(_tokenId));
    }

    function _exists(uint256 _tokenId, string memory _path) internal view virtual returns (bool) {
        if (!_exists(_tokenId)) {
            return false;
        }

        string memory metadata = _getTokenMetadata(_tokenId);
        return JsonUtil.exists(metadata, _path);
    }

    function _getTokenMetadata(uint256 _tokenId) internal view virtual returns (string memory) {
        return JsonStore.get(_store, _getTokenMetadataKey(_tokenId));
    }

    function _getTokenMetadata(uint256 _tokenId, string memory _path) internal view returns (string memory) {
        string memory metadata = _getTokenMetadata(_tokenId);
        return JsonUtil.get(metadata, _path);
    }

    function _getTokenMetadataInt(uint256 _tokenId, string memory _path) internal view returns (int256) {
        string memory metadata = _getTokenMetadata(_tokenId);
        return JsonUtil.getInt(metadata, _path);
    }

    function _getTokenMetadataUint(uint256 _tokenId, string memory _path) internal view returns (uint256) {
        string memory metadata = _getTokenMetadata(_tokenId);
        return JsonUtil.getUint(metadata, _path);
    }

    function _getTokenMetadataBool(uint256 _tokenId, string memory _path) internal view returns (bool) {
        string memory metadata = _getTokenMetadata(_tokenId);
        return JsonUtil.getBool(metadata, _path);
    }

    /// @dev Returns the attribute of the token with the given id and trait type as a string.
    function _getTokenAttribute(uint256 _tokenId, string memory _traitType) internal view returns (string memory) {
        string memory metadata = _getTokenMetadata(_tokenId);
        (JsonParser.Token[] memory tokens, uint256 count) = JsonUtil.parseJson(metadata);

        uint256 pos = 3; // Start at first object in attributes array
        while (pos < count) {
            if (tokens[pos].jsonType == JsonParser.JsonType.OBJECT) {
                string memory trait = JsonParser.getBytes(metadata, tokens[pos + 2].start, tokens[pos + 2].end);
                if (bytes(trait).length >= 2 && bytes(trait)[0] == '"') {
                    trait = JsonParser.getBytes(metadata, tokens[pos + 2].start + 1, tokens[pos + 2].end - 1);
                }

                if (JsonParser.strCompare(trait, _traitType) == 0) {
                    string memory value = JsonParser.getBytes(metadata, tokens[pos + 4].start, tokens[pos + 4].end);
                    if (bytes(value).length >= 2 && bytes(value)[0] == '"') {
                        return JsonParser.getBytes(metadata, tokens[pos + 4].start + 1, tokens[pos + 4].end - 1);
                    }
                    return value;
                }
                pos += 5;
            } else {
                pos++;
            }
        }
        revert TokenMetadata__TraitNotFound(_traitType);
    }

    /// @dev Returns the attribute of the token with the given id and trait type as `int256`.
    function _getTokenAttributeInt(uint256 _tokenId, string memory _traitType) internal view returns (int256) {
        string memory metadata = _getTokenMetadata(_tokenId);
        (JsonParser.Token[] memory tokens, uint256 count) = JsonUtil.parseJson(metadata);

        uint256 pos = 3;
        while (pos < count) {
            if (tokens[pos].jsonType == JsonParser.JsonType.OBJECT) {
                string memory trait = JsonParser.getBytes(metadata, tokens[pos + 2].start, tokens[pos + 2].end);
                if (bytes(trait).length >= 2 && bytes(trait)[0] == '"') {
                    trait = JsonParser.getBytes(metadata, tokens[pos + 2].start + 1, tokens[pos + 2].end - 1);
                }

                if (JsonParser.strCompare(trait, _traitType) == 0) {
                    string memory value = JsonParser.getBytes(metadata, tokens[pos + 4].start, tokens[pos + 4].end);
                    // Strip quotes if present
                    if (bytes(value).length >= 2 && bytes(value)[0] == '"') {
                        value = JsonParser.getBytes(metadata, tokens[pos + 4].start + 1, tokens[pos + 4].end - 1);
                    }
                    return JsonParser.parseInt(value);
                }
                pos += 5;
            } else {
                pos++;
            }
        }
        revert TokenMetadata__TraitNotFound(_traitType);
    }

    /// @dev Returns the attribute of the token with the given id and trait type as `uint256`.
    function _getTokenAttributeUint(uint256 _tokenId, string memory _traitType) internal view returns (uint256) {
        int256 value = _getTokenAttributeInt(_tokenId, _traitType);
        if (value < 0) revert TokenMetadata__InvalidType();
        return uint256(value);
    }

    /// @dev Returns the attribute of the token with the given id and trait type as `bool`.
    function _getTokenAttributeBool(uint256 _tokenId, string memory _traitType) internal view returns (bool) {
        string memory metadata = _getTokenMetadata(_tokenId);
        (JsonParser.Token[] memory tokens, uint256 count) = JsonUtil.parseJson(metadata);

        uint256 pos = 3;
        while (pos < count) {
            if (tokens[pos].jsonType == JsonParser.JsonType.OBJECT) {
                string memory trait = JsonParser.getBytes(metadata, tokens[pos + 2].start, tokens[pos + 2].end);
                if (bytes(trait).length >= 2 && bytes(trait)[0] == '"') {
                    trait = JsonParser.getBytes(metadata, tokens[pos + 2].start + 1, tokens[pos + 2].end - 1);
                }

                if (JsonParser.strCompare(trait, _traitType) == 0) {
                    string memory value = JsonParser.getBytes(metadata, tokens[pos + 4].start, tokens[pos + 4].end);
                    // Strip quotes if present before parsing bool
                    if (bytes(value).length >= 2 && bytes(value)[0] == '"') {
                        value = JsonParser.getBytes(metadata, tokens[pos + 4].start + 1, tokens[pos + 4].end - 1);
                    }
                    return JsonParser.parseBool(value);
                }
                pos += 5;
            } else {
                pos++;
            }
        }
        revert TokenMetadata__TraitNotFound(_traitType);
    }

    function _hasTokenAttribute(uint256 _tokenId, string memory _traitType) internal view returns (bool) {
        return _exists(_tokenId, _getTokenAttributePath(_traitType));
    }

    function _getTokenAttributePath(string memory _traitType) internal pure returns (string memory) {
        return string(abi.encodePacked('attributes.#(trait_type=="', _traitType, '")'));
    }

    function _getTokenAttributeValuePath(string memory _traitType) internal pure returns (string memory) {
        return string(abi.encodePacked('attributes.#(trait_type=="', _traitType, '").value'));
    }

    function _tokenMetadataToJson(StdTokenMetadata memory _data) internal pure returns (string memory) {
        // Create more compact JSON
        string memory metadata = "{";
        if (bytes(_data.name).length > 0) {
            metadata = string.concat(metadata, '"name":"', _data.name, '",');
        }
        if (bytes(_data.description).length > 0) {
            metadata = string.concat(metadata, '"description":"', _data.description, '",');
        }
        if (bytes(_data.image).length > 0) {
            metadata = string.concat(metadata, '"image":"', _data.image, '",');
        }
        if (bytes(_data.externalURL).length > 0) {
            metadata = string.concat(metadata, '"external_url":"', _data.externalURL, '",');
        }
        if (bytes(_data.animationURL).length > 0) {
            metadata = string.concat(metadata, '"animation_url":"', _data.animationURL, '",');
        }

        metadata = string.concat(metadata, '"attributes":[');

        uint256 length = _data.attributes.length;
        for (uint8 i = 0; i < length; ++i) {
            metadata = string.concat(metadata, _tokenAttributeToJson(_data.attributes[i]));
            if (i < length - 1) {
                metadata = string.concat(metadata, ",");
            }
        }

        metadata = string.concat(metadata, "]}");
        return metadata;
    }

    function _tokenAttributeToJson(Attribute memory _attribute) internal pure returns (string memory) {
        string memory attribute = "{";
        attribute = string.concat(attribute, '"trait_type":"', _attribute.traitType, '",');
        attribute = string.concat(attribute, '"value":"', _attribute.value, '"');

        if (bytes(_attribute.displayType).length > 0) {
            attribute = string.concat(attribute, ',"display_type":"', _attribute.displayType, '"');
        }

        attribute = string.concat(attribute, "}");
        return attribute;
    }

    function _setTokenMetadata(uint256 _tokenId, string memory _metadata) internal virtual {
        if (_exists(_tokenId)) {
            revert ITokenMetadata.TokenMetadataImmutable(_tokenId);
        }
        _setTokenMetadataForced(_tokenId, _metadata);
    }

    function _setTokenMetadata(uint256 _tokenId, StdTokenMetadata memory _data) internal virtual {
        _setTokenMetadata(_tokenId, _tokenMetadataToJson(_data));
    }

    function _setTokenMetadataForced(uint256 _tokenId, string memory _metadata) internal virtual {
        JsonStore.set(_store, _getTokenMetadataKey(_tokenId), _metadata);
    }

    function _setTokenMetadataForced(bytes32 _key, string memory _metadata) internal virtual {
        JsonStore.set(_store, _key, _metadata);
    }

    function _getTokenMetadataKey(uint256 _tokenId) internal view virtual returns (bytes32) {
        return bytes32(_tokenId);
    }
}
