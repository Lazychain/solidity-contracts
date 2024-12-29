// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { TokenMetadata } from "../../contracts/metadata/TokenMetadata.sol";
import { JsonUtil } from "../../contracts/utils/JsonUtil.sol";
import { JsonStore } from "../../contracts/utils/JsonStore.sol";
import { ITokenMetadata, Attribute, StdTokenMetadata } from "../../contracts/interfaces/metadata/ITokenMetadata.sol";

// Helper contract that exposes internal functions for testing
contract TokenMetadataHarness is TokenMetadata {
    using JsonStore for JsonStore.Store;

    function exposed_prepaySlots(address user, uint64 slots) external {
        JsonStore.prepay(_store, user, slots);
    }

    function exposed_getPrepaidSlots(address user) external view returns (uint64) {
        return JsonStore.prepaid(_store, user);
    }

    function exposed_getCurrentMsgSender() external view returns (address) {
        return msg.sender;
    }

    function exposed_uri(uint256 tokenId) external view returns (string memory) {
        return _uri(tokenId);
    }

    function exposed_exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function exposed_existsWithPath(uint256 tokenId, string calldata path) external view returns (bool) {
        return _exists(tokenId, path);
    }

    function exposed_getTokenMetadata(uint256 tokenId) external view returns (string memory) {
        return _getTokenMetadata(tokenId);
    }

    function exposed_getTokenMetadataWithPath(
        uint256 tokenId,
        string calldata path
    ) external view returns (string memory) {
        return _getTokenMetadata(tokenId, path);
    }

    function exposed_setTokenMetadata(uint256 tokenId, string memory metadata) external {
        _setTokenMetadata(tokenId, metadata);
    }

    function exposed_getTokenAttribute(
        uint256 tokenId,
        string calldata traitType
    ) external view returns (string memory) {
        return _getTokenAttribute(tokenId, traitType);
    }

    function exposed_getTokenAttributeInt(uint256 tokenId, string calldata traitType) external view returns (int256) {
        return _getTokenAttributeInt(tokenId, traitType);
    }

    function exposed_getTokenAttributeUint(uint256 tokenId, string calldata traitType) external view returns (uint256) {
        return _getTokenAttributeUint(tokenId, traitType);
    }

    function exposed_getTokenAttributeBool(uint256 tokenId, string calldata traitType) external view returns (bool) {
        return _getTokenAttributeBool(tokenId, traitType);
    }

    function exposed_setTokenMetadataForced(uint256 tokenId, string memory metadata) external {
        _setTokenMetadataForced(tokenId, metadata);
    }

    function exposed_setTokenMetadataWithStruct(uint256 tokenId, StdTokenMetadata calldata data) external {
        _setTokenMetadata(tokenId, data);
    }

    function exposed_getTokenMetadataKey(uint256 tokenId) external view returns (bytes32) {
        return _getTokenMetadataKey(tokenId);
    }
}

contract TokenMetadataTest is Test {
    TokenMetadataHarness public tokenMetadata;
    uint256 public constant TOKEN_ID = 1;

    function setUp() public {
        tokenMetadata = new TokenMetadataHarness();

        emit log_named_address("Contract Address", address(tokenMetadata));
        emit log_named_address("Test Contract Address", address(this));
        emit log_named_uint(
            "Initial slots for contract",
            tokenMetadata.exposed_getPrepaidSlots(address(tokenMetadata))
        );

        // Prepay slots before tests
        tokenMetadata.exposed_prepaySlots(address(tokenMetadata), 10);
        tokenMetadata.exposed_prepaySlots(address(this), 10);

        // Verify slots were allocated
        emit log_named_uint(
            "Slots after prepay for contract",
            tokenMetadata.exposed_getPrepaidSlots(address(tokenMetadata))
        );
        emit log_named_uint("Slots after prepay for test", tokenMetadata.exposed_getPrepaidSlots(address(this)));

        require(tokenMetadata.exposed_getPrepaidSlots(address(tokenMetadata)) > 0, "Contract has no slots");
        require(tokenMetadata.exposed_getPrepaidSlots(address(this)) > 0, "Test has no slots");
    }

    function testMetadataKeyGeneration() public view {
        bytes32 key = tokenMetadata.exposed_getTokenMetadataKey(TOKEN_ID);
        assertEq(key, bytes32(uint256(TOKEN_ID)));
    }

    function testNonExistentToken() public {
        uint256 nonExistentToken = 999;
        assertFalse(tokenMetadata.exposed_exists(nonExistentToken));

        // Test getting metadata for non-existent token
        vm.expectRevert();
        tokenMetadata.exposed_getTokenMetadata(nonExistentToken);
    }

    function testAttributeTypes() public {
        // Log current state
        emit log_named_address("Current msg.sender", tokenMetadata.exposed_getCurrentMsgSender());
        emit log_named_uint("Current slots", tokenMetadata.exposed_getPrepaidSlots(address(tokenMetadata)));

        string
            memory jsonMetadata = '{"attributes":[{"trait_type":"number","value":"42"},{"trait_type":"bool","value":"true"}]}';

        vm.prank(address(tokenMetadata));
        tokenMetadata.exposed_setTokenMetadata(TOKEN_ID, jsonMetadata);

        assertEq(tokenMetadata.exposed_getTokenAttributeUint(TOKEN_ID, "number"), 42);
        assertTrue(tokenMetadata.exposed_getTokenAttributeBool(TOKEN_ID, "bool"));
    }

    function testBasicMetadataFlow() public {
        // Create test metadata
        Attribute[] memory attributes = new Attribute[](1);
        attributes[0] = Attribute({ traitType: "Type1", value: "Value1", displayType: "string" });

        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "Test Token",
            description: "Test Description",
            image: "https://test.com/image.png",
            externalURL: "https://test.com",
            animationURL: "",
            attributes: attributes
        });

        // Set metadata
        tokenMetadata.exposed_setTokenMetadataWithStruct(TOKEN_ID, metadata);

        // Test exists
        assertTrue(tokenMetadata.exposed_exists(TOKEN_ID));

        // Test attribute existence using correct path
        assertTrue(tokenMetadata.exposed_existsWithPath(TOKEN_ID, "attributes"));

        // Test attribute value
        string memory value = tokenMetadata.exposed_getTokenAttribute(TOKEN_ID, "Type1");
        assertEq(value, "Value1");

        assertTrue(tokenMetadata.exposed_existsWithPath(TOKEN_ID, "attributes[0].value")); // Changed path format

        // Test getters
        assertEq(tokenMetadata.exposed_getTokenAttribute(TOKEN_ID, "Type1"), "Value1");

        // Test immutability
        vm.expectRevert(abi.encodeWithSelector(ITokenMetadata.TokenMetadataImmutable.selector, TOKEN_ID));
        tokenMetadata.exposed_setTokenMetadataWithStruct(TOKEN_ID, metadata);
    }

    function testMultipleAttributes() public {
        // Create test metadata with multiple attributes
        Attribute[] memory attributes = new Attribute[](3);
        attributes[0] = Attribute({ traitType: "String", value: "Value1", displayType: "string" });
        attributes[1] = Attribute({ traitType: "Number", value: "42", displayType: "number" });
        attributes[2] = Attribute({ traitType: "Boolean", value: "true", displayType: "boolean" });

        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "Multi Attribute Token",
            description: "Token with multiple attributes",
            image: "https://test.com/image.png",
            externalURL: "https://test.com",
            animationURL: "",
            attributes: attributes
        });

        tokenMetadata.exposed_setTokenMetadataWithStruct(TOKEN_ID, metadata);

        // Test each attribute
        assertEq(tokenMetadata.exposed_getTokenAttribute(TOKEN_ID, "String"), "Value1");
        assertEq(tokenMetadata.exposed_getTokenAttributeUint(TOKEN_ID, "Number"), 42);
        assertTrue(tokenMetadata.exposed_getTokenAttributeBool(TOKEN_ID, "Boolean"));
    }

    function testURIGeneration() public {
        // Create basic metadata
        Attribute[] memory attributes = new Attribute[](1);
        attributes[0] = Attribute({ traitType: "Test", value: "Value", displayType: "string" });

        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "a",
            description: "b",
            image: "c.png",
            externalURL: "x.com",
            animationURL: "",
            attributes: attributes
        });

        tokenMetadata.exposed_setTokenMetadataWithStruct(TOKEN_ID, metadata);
        string memory uri = tokenMetadata.exposed_uri(TOKEN_ID);
        assertTrue(bytes(uri).length > 0);
    }

    function testBasicMetadataFlow2() public {
        // Create test metadata
        Attribute[] memory attributes = new Attribute[](1);
        attributes[0] = Attribute({ traitType: "Type1", value: "Value1", displayType: "string" });

        StdTokenMetadata memory metadata = StdTokenMetadata({
            name: "Test Token",
            description: "Test Description",
            image: "https://test.com/image.png",
            externalURL: "https://test.com",
            animationURL: "https://test.com/animation.mp4",
            attributes: attributes
        });

        // Set metadata
        tokenMetadata.exposed_setTokenMetadataWithStruct(TOKEN_ID, metadata);

        // Test exists
        assertTrue(tokenMetadata.exposed_exists(TOKEN_ID));

        // Test simple path first
        assertTrue(tokenMetadata.exposed_existsWithPath(TOKEN_ID, "attributes"));

        // Test attribute access
        assertEq(tokenMetadata.exposed_getTokenAttribute(TOKEN_ID, "Type1"), "Value1");
    }
}
