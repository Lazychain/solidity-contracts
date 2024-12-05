// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { TokenMetadataReader } from "../../contracts/metadata/TokenMetadataReader.sol";
import { ITokenMetadata } from "../../contracts/interfaces/metadata/ITokenMetadata.sol";

// Mock contract implementing ITokenMetadata
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
        return tokenMetadata[_tokenId];
    }
}

contract TokenMetadataReaderTest is Test {
    MockTokenMetadata private mockToken;
    uint256 private constant TOKEN_ID = 1;
    string private constant SAMPLE_METADATA =
        '{"name":"Test Token","description":"A test token","attributes":[{"trait_type":"Color","value":"Blue"},{"trait_type":"Size","value":"10"},{"trait_type":"Active","value":"true"},{"trait_type":"Score","value":"-5"}]}';

    function setUp() public {
        mockToken = new MockTokenMetadata();
        mockToken.setTokenMetadata(TOKEN_ID, SAMPLE_METADATA);
    }

    function testExists() public {
        assertTrue(TokenMetadataReader.exists(address(mockToken), TOKEN_ID));
        assertFalse(TokenMetadataReader.exists(address(mockToken), 999)); // Non-existent token
    }

    function testExistsWithPath() public {
        assertTrue(TokenMetadataReader.exists(address(mockToken), TOKEN_ID, "name"));
        assertTrue(TokenMetadataReader.exists(address(mockToken), TOKEN_ID, "attributes"));
        assertFalse(TokenMetadataReader.exists(address(mockToken), TOKEN_ID, "non_existent_field"));
    }

    function testGetTokenMetadata() public {
        string memory metadata = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID);
        assertEq(metadata, SAMPLE_METADATA);
    }

    function testGetTokenMetadataWithPath() public {
        string memory name = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID, "name");
        assertEq(name, "Test Token");

        string memory description = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID, "description");
        assertEq(description, "A test token");
    }

    function testGetTokenMetadataInt() public {
        int256 score = TokenMetadataReader.getTokenMetadataInt(
            address(mockToken),
            TOKEN_ID,
            'attributes.#(trait_type=="Score").value'
        );
        assertEq(score, -5);
    }

    function testGetTokenMetadataUint() public {
        uint256 size = TokenMetadataReader.getTokenMetadataUint(
            address(mockToken),
            TOKEN_ID,
            'attributes.#(trait_type=="Size").value'
        );
        assertEq(size, 10);
    }

    function testGetTokenMetadataBool() public {
        bool active = TokenMetadataReader.getTokenMetadataBool(
            address(mockToken),
            TOKEN_ID,
            'attributes.#(trait_type=="Active").value'
        );
        assertTrue(active);
    }

    function testGetTokenAttribute() public {
        string memory color = TokenMetadataReader.getTokenAttribute(address(mockToken), TOKEN_ID, "Color");
        assertEq(color, "Blue");
    }

    function testGetTokenAttributeInt() public {
        int256 score = TokenMetadataReader.getTokenAttributeInt(address(mockToken), TOKEN_ID, "Score");
        assertEq(score, -5);
    }

    function testGetTokenAttributeUint() public {
        uint256 size = TokenMetadataReader.getTokenAttributeUint(address(mockToken), TOKEN_ID, "Size");
        assertEq(size, 10);
    }

    function testGetTokenAttributeBool() public {
        bool active = TokenMetadataReader.getTokenAttributeBool(address(mockToken), TOKEN_ID, "Active");
        assertTrue(active);
    }

    function testHasTokenAttribute() public {
        assertTrue(TokenMetadataReader.hasTokenAttribute(address(mockToken), TOKEN_ID, "Color"));
        assertFalse(TokenMetadataReader.hasTokenAttribute(address(mockToken), TOKEN_ID, "NonExistentTrait"));
    }

    function testFailGetNonExistentAttribute() public {
        TokenMetadataReader.getTokenAttribute(address(mockToken), TOKEN_ID, "NonExistentTrait");
    }

    function testFailInvalidTokenId() public {
        TokenMetadataReader.getTokenMetadata(address(mockToken), 999);
    }

    function testFailInvalidJson() public {
        mockToken.setTokenMetadata(TOKEN_ID, "invalid json");
        TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID, "name");
    }

    // Fuzz tests
    function testFuzz_TokenIdExists(uint256 tokenId) public {
        string memory metadata = '{"name":"Fuzz Token"}';
        mockToken.setTokenMetadata(tokenId, metadata);
        assertTrue(TokenMetadataReader.exists(address(mockToken), tokenId));
    }

    function testFuzz_GetTokenMetadata(string memory name, string memory description) public {
        vm.assume(bytes(name).length > 0 && bytes(name).length < 1000);
        vm.assume(bytes(description).length < 1000);

        string memory metadata = string(abi.encodePacked('{"name":"', name, '","description":"', description, '"}'));

        mockToken.setTokenMetadata(TOKEN_ID, metadata);

        string memory retrievedName = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID, "name");
        assertEq(retrievedName, name);
    }
}
