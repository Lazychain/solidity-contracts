// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { TokenMetadataReader } from "../../contracts/metadata/TokenMetadataReader.sol";
import { ITokenMetadata } from "../../contracts/interfaces/metadata/ITokenMetadata.sol";
import { JsonUtil } from "../../contracts/utils/JsonUtil.sol";

contract MockTokenMetadata is ITokenMetadata {
    mapping(uint256 => string) private tokenMetadata;
    mapping(uint256 => bool) private tokenExists;

    function setTokenMetadata(uint256 _tokenId, string memory _metadata) external {
        tokenMetadata[_tokenId] = _metadata;
        tokenExists[_tokenId] = true;
    }

    function uri(uint256 _tokenId) external view returns (string memory) {
        return tokenMetadata[_tokenId];
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenMetadata[_tokenId];
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return tokenExists[_tokenId];
    }

    function getTokenMetadata(uint256 _tokenId) external view returns (string memory) {
        require(tokenExists[_tokenId], "Token does not exist");
        return tokenMetadata[_tokenId];
    }
}

contract TokenMetadataReaderTest is Test {
    MockTokenMetadata private mockToken;
    uint256 private constant TOKEN_ID = 1;

    string constant BASIC_METADATA = '{"name":"Test Token","description":"A test token"}';
    string constant COMPLEX_METADATA =
        '{"name":"Test Token","description":"A test token","attributes":[{"trait_type":"Color","value":"Blue"},{"trait_type":"Size","value":"10"},{"trait_type":"Active","value":"true"},{"trait_type":"Score","value":"-5"}]}';

    function setUp() public {
        mockToken = new MockTokenMetadata();
        mockToken.setTokenMetadata(TOKEN_ID, BASIC_METADATA);
    }

    function testExists() public view {
        assertTrue(TokenMetadataReader.exists(address(mockToken), TOKEN_ID));

        assertFalse(TokenMetadataReader.exists(address(mockToken), 999));
    }

    function testGetTokenMetadata() public view {
        string memory metadata = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID);
        assertEq(metadata, BASIC_METADATA);
    }

    function testFailGetNonExistentToken() public view {
        TokenMetadataReader.getTokenMetadata(address(mockToken), 999);
    }

    function testFailInvalidTokenMetadata() public {
        mockToken.setTokenMetadata(TOKEN_ID, "invalid json");

        vm.expectRevert(JsonUtil.JsonUtil__InvalidJson.selector);
        TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID);
    }
}
