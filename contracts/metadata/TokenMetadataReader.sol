// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { JsonUtil } from "../utils/JsonUtil.sol";
import { Strings } from "../utils/Strings.sol";
import { ITokenMetadata } from "../interfaces/metadata/ITokenMetadata.sol";

library TokenMetadataReader {
    error TokenDoesNotExist(uint256 tokenId);
    error InvalidMetadata(uint256 tokenId);

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
        revert("Attribute not found");
    }

    // function getTokenAttributeInt(
    //     address _tokenAddress,
    //     uint256 _tokenId,
    //     string memory _traitType
    // ) internal view returns (int256) {
    //     return getTokenMetadataInt(_tokenAddress, _tokenId, _tavp(_traitType));
    // }

    // function getTokenAttributeUint(
    //     address _tokenAddress,
    //     uint256 _tokenId,
    //     string memory _traitType
    // ) internal view returns (uint256) {
    //     return getTokenMetadataUint(_tokenAddress, _tokenId, _tavp(_traitType));
    // }

    // function getTokenAttributeBool(
    //     address _tokenAddress,
    //     uint256 _tokenId,
    //     string memory _traitType
    // ) internal view returns (bool) {
    //     return getTokenMetadataBool(_tokenAddress, _tokenId, _tavp(_traitType));
    // }

    /// @dev Main function remains simple
    function hasTokenAttribute(
        address _tokenAddress,
        uint256 _tokenId,
        string memory _traitType
    ) internal view returns (bool) {
        string memory metadata = getTokenMetadata(_tokenAddress, _tokenId);

        // Try indices 0 through 9 for attributes array
        for (uint256 i = 0; i < 10; i++) {
            string memory path = _tap(i);

            if (!JsonUtil.exists(metadata, path)) {
                break; // No more attributes to check
            }

            string memory traitType = JsonUtil.get(metadata, path);

            if (stringsEqual(traitType, _traitType)) {
                return true;
            }
        }
        return false;
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

    /// @dev Constructs path to trait_type at given array index
    function _tap(uint256 index) internal pure returns (string memory) {
        return string(abi.encodePacked("attributes[", toString(index), "].trait_type"));
    }

    /// @dev Constructs path to get value of an attribute at a specific index
    function _tavp(uint256 index) internal pure returns (string memory) {
        return string(abi.encodePacked("attributes[", toString(index), "].value"));
    }
}
