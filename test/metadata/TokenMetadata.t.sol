// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { TokenMetadata } from "../../contracts/metadata/TokenMetadata.sol";
import { ITokenMetadata, Attribute, StdTokenMetadata } from "../../contracts/interfaces/ITokenMetadata.sol";

contract TokenMetadataTest is Test {
    TokenMetadata public tokenMetadata;
    address public constant OWNER = address(0x1);
    uint256 public constant TOKEN_ID = 1;

    event TokenMetadataSet(uint256 indexed tokenId, string metadata);

    function setUp() public {
        vm.startPrank(OWNER);
        tokenMetadata = new TokenMetadata();
        vm.stopPrank();
    }

    function test_SetAndGetMetadata() public {
        vm.startPrank(OWNER);

        // Create sample metadata
        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "Test Token",
            description: "Test Description",
            image: "https://test.com/image.png",
            externalURL: "https://test.com",
            animationURL: "https://test.com/animation.mp4",
            attributes: new Attribute[](2)
        });

        metadata.attributes[0] = Attribute({ traitType: "Type1", value: "Value1", displayType: "string" });

        metadata.attributes[1] = Attribute({ traitType: "Type2", value: "2", displayType: "number" });

        // Set metadata
        tokenMetadata._setTokenMetadata(TOKEN_ID, metadata);

        // Verify existence
        assertTrue(tokenMetadata.exists(TOKEN_ID));

        // Get and verify metadata
        string memory storedMetadata = tokenMetadata.getTokenMetadata(TOKEN_ID);
        assertTrue(bytes(storedMetadata).length > 0);

        // Verify individual fields through JsonUtil
        assertEq(tokenMetadata._getTokenAttribute(TOKEN_ID, "Type1"), "Value1");
        assertEq(tokenMetadata._getTokenAttribute(TOKEN_ID, "Type2"), "2");

        // Verify has attribute
        assertTrue(tokenMetadata._hasTokenAttribute(TOKEN_ID, "Type1"));
        assertFalse(tokenMetadata._hasTokenAttribute(TOKEN_ID, "NonExistentType"));

        vm.stopPrank();
    }

    function test_SetMetadataImmutable() public {
        vm.startPrank(OWNER);

        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "Test Token",
            description: "Test Description",
            image: "https://test.com/image.png",
            externalURL: "https://test.com",
            animationURL: "https://test.com/animation.mp4",
            attributes: new Attribute[](0)
        });

        // First set
        tokenMetadata._setTokenMetadata(TOKEN_ID, metadata);

        // Try to set again - should revert
        vm.expectRevert(abi.encodeWithSelector(ITokenMetadata.TokenMetadataImmutable.selector, TOKEN_ID));
        tokenMetadata._setTokenMetadata(TOKEN_ID, metadata);

        vm.stopPrank();
    }

    function test_GetNonExistentToken() public {
        vm.startPrank(OWNER);

        uint256 nonExistentTokenId = 999;

        // Verify non-existence
        assertFalse(tokenMetadata.exists(nonExistentTokenId));

        // Test get operations on non-existent token
        vm.expectRevert(abi.encodeWithSelector(ITokenMetadata.TokenNotFound.selector, nonExistentTokenId));
        tokenMetadata.getTokenMetadata(nonExistentTokenId);

        vm.expectRevert(abi.encodeWithSelector(ITokenMetadata.TokenNotFound.selector, nonExistentTokenId));
        tokenMetadata.uri(nonExistentTokenId);

        vm.stopPrank();
    }

    function test_TokenAttributeTypes() public {
        vm.startPrank(OWNER);

        // Create metadata with different attribute types
        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "Test Token",
            description: "Test Description",
            image: "https://test.com/image.png",
            externalURL: "https://test.com",
            animationURL: "https://test.com/animation.mp4",
            attributes: new Attribute[](4)
        });

        metadata.attributes[0] = Attribute({ traitType: "StringAttr", value: "StringValue", displayType: "string" });

        metadata.attributes[1] = Attribute({ traitType: "IntAttr", value: "-42", displayType: "number" });

        metadata.attributes[2] = Attribute({ traitType: "UintAttr", value: "42", displayType: "number" });

        metadata.attributes[3] = Attribute({ traitType: "BoolAttr", value: "true", displayType: "boolean" });

        // Set metadata
        tokenMetadata._setTokenMetadata(TOKEN_ID, metadata);

        // Test different attribute getters
        assertEq(tokenMetadata._getTokenAttribute(TOKEN_ID, "StringAttr"), "StringValue");
        assertEq(tokenMetadata._getTokenAttributeInt(TOKEN_ID, "IntAttr"), -42);
        assertEq(tokenMetadata._getTokenAttributeUint(TOKEN_ID, "UintAttr"), 42);
        assertTrue(tokenMetadata._getTokenAttributeBool(TOKEN_ID, "BoolAttr"));

        vm.stopPrank();
    }

    function test_TokenURIFormat() public {
        vm.startPrank(OWNER);

        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "Test Token",
            description: "Test Description",
            image: "https://test.com/image.png",
            externalURL: "https://test.com",
            animationURL: "https://test.com/animation.mp4",
            attributes: new Attribute[](0)
        });

        tokenMetadata._setTokenMetadata(TOKEN_ID, metadata);

        // Get URI and verify format
        string memory tokenUri = tokenMetadata.uri(TOKEN_ID);
        assertTrue(bytes(tokenUri).length > 0);

        // URI should be equal for both uri() and tokenURI()
        assertEq(tokenMetadata.uri(TOKEN_ID), tokenMetadata.tokenURI(TOKEN_ID));

        vm.stopPrank();
    }

    function test_ForceSetMetadata() public {
        vm.startPrank(OWNER);

        string memory initialMetadata = '{"name":"Initial"}';
        string memory updatedMetadata = '{"name":"Updated"}';

        // Initial set
        tokenMetadata._setTokenMetadataForced(TOKEN_ID, initialMetadata);

        // Force update
        tokenMetadata._setTokenMetadataForced(TOKEN_ID, updatedMetadata);

        // Verify update
        string memory storedMetadata = tokenMetadata.getTokenMetadata(TOKEN_ID);
        assertEq(storedMetadata, updatedMetadata);

        vm.stopPrank();
    }

    function testFuzz_SetAndGetMetadata(uint256 tokenId) public {
        vm.assume(tokenId != 0); // Assuming 0 is an invalid token ID
        vm.startPrank(OWNER);

        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "Fuzz Test Token",
            description: "Fuzz Description",
            image: "https://test.com/image.png",
            externalURL: "https://test.com",
            animationURL: "https://test.com/animation.mp4",
            attributes: new Attribute[](1)
        });

        metadata.attributes[0] = Attribute({ traitType: "FuzzType", value: "FuzzValue", displayType: "string" });

        tokenMetadata._setTokenMetadata(tokenId, metadata);
        assertTrue(tokenMetadata.exists(tokenId));
        assertTrue(tokenMetadata._hasTokenAttribute(tokenId, "FuzzType"));

        vm.stopPrank();
    }
}
