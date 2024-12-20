// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
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
    MockTokenMetadata private mockTokenComplex;
    uint256 private constant TOKEN_ID = 1;

    string constant BASIC_METADATA = '{"name":"Test Token","description":"A test token"}';
    string constant COMPLEX_METADATA =
        '{"name":"Test Token","description":"A test token","attributes":[{"trait_type":"Color","value":"Blue"},{"trait_type":"Size","value":"10"},{"trait_type":"Active","value":"true"},{"trait_type":"Score","value":"-5"}]}';

    function setUp() public {
        mockToken = new MockTokenMetadata();
        mockTokenComplex = new MockTokenMetadata();
        mockToken.setTokenMetadata(TOKEN_ID, BASIC_METADATA);
        mockTokenComplex.setTokenMetadata(TOKEN_ID, COMPLEX_METADATA);
    }

    function testExists() public view {
        // PASS
        assertTrue(TokenMetadataReader.exists(address(mockToken), TOKEN_ID));
        assertFalse(TokenMetadataReader.exists(address(mockToken), 999));

        assertTrue(TokenMetadataReader.exists(address(mockTokenComplex), TOKEN_ID));
        assertFalse(TokenMetadataReader.exists(address(mockTokenComplex), 999));
    }

    function testGetTokenMetadata() public view {
        // PASS
        string memory metadata = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID);
        assertEq(metadata, BASIC_METADATA);
        string memory metadatac = TokenMetadataReader.getTokenMetadata(address(mockTokenComplex), TOKEN_ID);
        assertEq(metadatac, COMPLEX_METADATA);
    }

    function testFailGetNonExistentToken() public view {
        // PASS
        TokenMetadataReader.getTokenMetadata(address(mockToken), 999);
        TokenMetadataReader.getTokenMetadata(address(mockTokenComplex), 999);
    }

    function testFailInvalidTokenMetadata() public {
        // PASS
        mockToken.setTokenMetadata(TOKEN_ID, "invalid json");
        vm.expectRevert(JsonUtil.JsonUtil__InvalidJson.selector);
        TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID);

        mockTokenComplex.setTokenMetadata(TOKEN_ID, "invalid json");
        vm.expectRevert(JsonUtil.JsonUtil__InvalidJson.selector);
        TokenMetadataReader.getTokenMetadata(address(mockTokenComplex), TOKEN_ID);
    }

    function testFuzz_TokenIdExists(uint256 tokenId) public {
        // PASS
        vm.assume(tokenId != 0);
        string memory metadata = '{"name":"Test"}';
        mockToken.setTokenMetadata(tokenId, metadata);
        assertTrue(TokenMetadataReader.exists(address(mockToken), tokenId));
    }

    function testJsonPath() public view {
        // First, let's test the path creation
        string memory path = TokenMetadataReader._tavp("Color");
        console.log("Generated path:", path);

        // Then test the direct JSON access
        string memory metadata = TokenMetadataReader.getTokenMetadata(address(mockTokenComplex), TOKEN_ID);
        console.log("Metadata:", metadata);

        // Try the JsonUtil directly
        string memory value = JsonUtil.get(metadata, path);
        console.log("Retrieved value:", value);
    }

    function testGetTokenAttribute() public view {
        // FAILING
        string memory colorValue = TokenMetadataReader.getTokenAttribute(address(mockTokenComplex), TOKEN_ID, "Color");
        assertEq(colorValue, "Blue");
    }

    function testGetTokenAttributeInt() public view {
        // FAILING
        int256 scoreValue = TokenMetadataReader.getTokenAttributeInt(address(mockTokenComplex), TOKEN_ID, "Score");
        assertEq(scoreValue, -5);
    }

    function testGetTokenAttributeUint() public view {
        // FAILING
        uint256 sizeValue = TokenMetadataReader.getTokenAttributeUint(address(mockTokenComplex), TOKEN_ID, "Size");
        assertEq(sizeValue, 10);
    }

    function testGetTokenAttributeBool() public {
        // FAILING
        bool activeValue = TokenMetadataReader.getTokenAttributeBool(address(mockToken), TOKEN_ID, "Active");
        assertTrue(activeValue);
    }

    function testHasTokenAttribute() public {
        // FAILING
        assertTrue(TokenMetadataReader.hasTokenAttribute(address(mockToken), TOKEN_ID, "Color"));
        assertFalse(TokenMetadataReader.hasTokenAttribute(address(mockToken), TOKEN_ID, "NonExistent"));
    }

    function testFailGetNonExistentAttribute() public {
        // FAILING
        vm.expectRevert();
        TokenMetadataReader.getTokenAttribute(address(mockToken), TOKEN_ID, "NonExistent");
    }

    function testGetTokenMetadataWithPath() public view {
        // FAILING
        string memory name = TokenMetadataReader.getTokenMetadata(address(mockTokenComplex), TOKEN_ID, "name");
        assertEq(name, "Test Token");

        string memory description = TokenMetadataReader.getTokenMetadata(
            address(mockTokenComplex),
            TOKEN_ID,
            "description"
        );
        assertEq(description, "A test token");
    }

    function testExistsWithPath() public view {
        // FAILING
        assertTrue(TokenMetadataReader.exists(address(mockTokenComplex), TOKEN_ID, "name"));
        assertTrue(TokenMetadataReader.exists(address(mockTokenComplex), TOKEN_ID, "attributes"));
        assertFalse(TokenMetadataReader.exists(address(mockTokenComplex), TOKEN_ID, "non_existent"));
    }

    function testFuzzGetTokenMetadata(string memory name, string memory description) public {
        // FAILING
        vm.assume(bytes(name).length > 0 && bytes(name).length < 100);
        vm.assume(bytes(description).length > 0 && bytes(description).length < 100);

        string memory metadata = string(abi.encodePacked('{"name":"', name, '","description":"', description, '"}'));

        mockToken.setTokenMetadata(TOKEN_ID, metadata);
        string memory retrievedName = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID, "name");
        assertEq(retrievedName, name);
    }
}
