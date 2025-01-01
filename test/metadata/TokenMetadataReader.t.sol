// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { TokenMetadataReader } from "../../contracts/metadata/TokenMetadataReader.sol";
import { ITokenMetadata } from "../../contracts/interfaces/metadata/ITokenMetadata.sol";
import { JsonUtil } from "../../contracts/utils/JsonUtil.sol";
import { JsonParser } from "../../contracts/utils/JsonParser.sol";

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
        '{"name":"Test Token","description":"A test token","attributes":[{"trait_type":"Color","value":"Blue"},{"trait_type":"Size","value":10},{"trait_type":"Active","value":true},{"trait_type":"Score","value":-5}]}';

    function setUp() public {
        mockToken = new MockTokenMetadata();
        mockTokenComplex = new MockTokenMetadata();
        mockToken.setTokenMetadata(TOKEN_ID, BASIC_METADATA);
        mockTokenComplex.setTokenMetadata(TOKEN_ID, COMPLEX_METADATA);
    }

    function testExists() public view {
        assertTrue(TokenMetadataReader.exists(address(mockToken), TOKEN_ID));
        assertFalse(TokenMetadataReader.exists(address(mockToken), 999));

        assertTrue(TokenMetadataReader.exists(address(mockTokenComplex), TOKEN_ID));
        assertFalse(TokenMetadataReader.exists(address(mockTokenComplex), 999));
    }

    function testGetTokenMetadata() public view {
        string memory metadata = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID);
        assertEq(metadata, BASIC_METADATA);
        string memory metadatac = TokenMetadataReader.getTokenMetadata(address(mockTokenComplex), TOKEN_ID);
        assertEq(metadatac, COMPLEX_METADATA);
    }

    function testFailGetNonExistentToken() public view {
        TokenMetadataReader.getTokenMetadata(address(mockToken), 999);
        TokenMetadataReader.getTokenMetadata(address(mockTokenComplex), 999);
    }

    function testFailInvalidTokenMetadata() public {
        mockToken.setTokenMetadata(TOKEN_ID, "invalid json");
        vm.expectRevert(JsonUtil.JsonUtil__InvalidJson.selector);
        TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID);

        mockTokenComplex.setTokenMetadata(TOKEN_ID, "invalid json");
        vm.expectRevert(JsonUtil.JsonUtil__InvalidJson.selector);
        TokenMetadataReader.getTokenMetadata(address(mockTokenComplex), TOKEN_ID);
    }

    function testFuzzTokenIdExists(uint256 tokenId) public {
        vm.assume(tokenId != 0);
        string memory metadata = '{"name":"Test"}';
        mockToken.setTokenMetadata(tokenId, metadata);
        assertTrue(TokenMetadataReader.exists(address(mockToken), tokenId));
    }

    function testGetTokenAttribute() public view {
        // String
        string memory colorValue = TokenMetadataReader.getTokenAttribute(address(mockTokenComplex), TOKEN_ID, "Color");
        assertEq(colorValue, "Blue");
        // Uint
        uint256 sizeValue = TokenMetadataReader.getTokenAttributeUint(address(mockTokenComplex), TOKEN_ID, "Size");
        assertEq(sizeValue, 10);
        // Int
        int256 scoreValue = TokenMetadataReader.getTokenAttributeInt(address(mockTokenComplex), TOKEN_ID, "Score");
        assertEq(scoreValue, -5);
        // Bool
        bool activeValue = TokenMetadataReader.getTokenAttributeBool(address(mockTokenComplex), TOKEN_ID, "Active");
        assertTrue(activeValue);
    }

    function testFailGetNonExistentAttribute() public {
        vm.expectRevert();
        TokenMetadataReader.getTokenAttribute(address(mockToken), TOKEN_ID, "NonExistent");
    }

    function testGetTokenMetadataWithPath() public view {
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
        assertTrue(TokenMetadataReader.exists(address(mockTokenComplex), TOKEN_ID, "name"));
        assertTrue(TokenMetadataReader.exists(address(mockTokenComplex), TOKEN_ID, "attributes"));
        assertFalse(TokenMetadataReader.exists(address(mockTokenComplex), TOKEN_ID, "non_existent"));
    }

    function testHasTokenAttribute() public view {
        assertTrue(TokenMetadataReader.hasTokenAttribute(address(mockTokenComplex), TOKEN_ID, "Color"));
        assertTrue(TokenMetadataReader.hasTokenAttribute(address(mockTokenComplex), TOKEN_ID, "Score"));
        assertTrue(TokenMetadataReader.hasTokenAttribute(address(mockTokenComplex), TOKEN_ID, "Active"));
        assertTrue(TokenMetadataReader.hasTokenAttribute(address(mockTokenComplex), TOKEN_ID, "Size"));
        assertFalse(TokenMetadataReader.hasTokenAttribute(address(mockTokenComplex), TOKEN_ID, "NonExistent"));
    }

    function testFuzzGetTokenMetadata(string calldata name, string calldata description) public {
        vm.assume(bytes(name).length > 0 && bytes(name).length < 100);
        vm.assume(bytes(description).length > 0 && bytes(description).length < 100);

        // Sanitize the input strings
        string memory sanitizedName = sanitizeString(name);
        string memory sanitizedDesc = sanitizeString(description);

        // Create valid JSON string
        string memory validJson = string(
            abi.encodePacked('{"name":"', sanitizedName, '","description":"', sanitizedDesc, '"}')
        );

        mockToken.setTokenMetadata(TOKEN_ID, validJson);
        string memory retrievedName = TokenMetadataReader.getTokenMetadata(address(mockToken), TOKEN_ID, "name");
        assertEq(retrievedName, sanitizedName);
    }

    function sanitizeString(string memory input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory output = new bytes(inputBytes.length * 2); // Worst case scenario each char needs escaping
        uint256 outputLength = 0;

        for (uint256 i = 0; i < inputBytes.length; i++) {
            uint8 char = uint8(inputBytes[i]);

            // Allow all printable ASCII and Unicode characters
            if ((char >= 32 && char <= 126) || (char >= 192 && char <= 255)) {
                // Escape special JSON characters
                if (char == 0x22 || char == 0x5C) {
                    // 0x22 is ", 0x5C is \
                    output[outputLength++] = bytes1(0x5C); // add backslash
                    output[outputLength++] = bytes1(char);
                } else {
                    output[outputLength++] = bytes1(char);
                }
            } else {
                // Handle other Unicode characters correctly
                output[outputLength++] = bytes1(char);
            }
        }

        // Create final string with correct length
        bytes memory finalOutput = new bytes(outputLength);
        for (uint256 i = 0; i < outputLength; i++) {
            finalOutput[i] = output[i];
        }

        return string(finalOutput);
    }
}
