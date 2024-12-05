// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "forge-std/Test.sol";
// import { TokenMetadata } from "../../contracts/metadata/TokenMetadata.sol";
// import { JsonUtil } from "../../contracts/utils/JsonUtil.sol";
// import { ITokenMetadata, Attribute, StdTokenMetadata } from "../../contracts/interfaces/ITokenMetadata.sol";

// // Helper contract that exposes internal functions for testing
// contract TokenMetadataHarness is TokenMetadata {
//     function exposed_uri(uint256 tokenId) external view returns (string memory) {
//         return _uri(tokenId);
//     }

//     function exposed_exists(uint256 tokenId) external view returns (bool) {
//         return _exists(tokenId);
//     }

//     function exposed_existsWithPath(uint256 tokenId, string calldata path) external view returns (bool) {
//         return _exists(tokenId, path);
//     }

//     function exposed_getTokenMetadata(uint256 tokenId) external view returns (string memory) {
//         return _getTokenMetadata(tokenId);
//     }

//     function exposed_getTokenMetadataWithPath(
//         uint256 tokenId,
//         string calldata path
//     ) external view returns (string memory) {
//         return _getTokenMetadata(tokenId, path);
//     }

//     function exposed_setTokenMetadata(uint256 tokenId, string memory metadata) external {
//         _setTokenMetadata(tokenId, metadata);
//     }

//     function exposed_getTokenAttribute(
//         uint256 tokenId,
//         string calldata traitType
//     ) external view returns (string memory) {
//         return _getTokenAttribute(tokenId, traitType);
//     }

//     function exposed_getTokenAttributeInt(uint256 tokenId, string calldata traitType) external view returns (int256) {
//         return _getTokenAttributeInt(tokenId, traitType);
//     }

//     function exposed_getTokenAttributeUint(uint256 tokenId, string calldata traitType) external view returns (uint256) {
//         return _getTokenAttributeUint(tokenId, traitType);
//     }

//     function exposed_getTokenAttributeBool(uint256 tokenId, string calldata traitType) external view returns (bool) {
//         return _getTokenAttributeBool(tokenId, traitType);
//     }

//     function exposed_setTokenMetadataForced(uint256 tokenId, string memory metadata) external {
//         _setTokenMetadataForced(tokenId, metadata);
//     }

//     function _tokenMetadataToJson(StdTokenMetadata memory _data) internal pure returns (string memory) {
//         string memory metadata = '{"attributes":[]}';

//         string[] memory paths = new string[](5);
//         paths[0] = "name";
//         paths[1] = "description";
//         paths[2] = "image";
//         paths[3] = "external_url";
//         paths[4] = "animation_url";
//         string[] memory values = new string[](5);
//         values[0] = _data.name;
//         values[1] = _data.description;
//         values[2] = _data.image;
//         values[3] = _data.externalURL;
//         values[4] = _data.animationURL;
//         metadata = JsonUtil.set(metadata, paths, values);
//         uint256 length = _data.attributes.length;
//         for (uint8 i = 0; i < length; ++i) {
//             metadata = JsonUtil.setRaw(metadata, "attributes.-1", _tokenAttributeToJson(_data.attributes[i]));
//         }

//         return metadata;
//     }

//     function exposed_setTokenMetadataWithStruct(uint256 tokenId, StdTokenMetadata memory data) external {
//         // Directly use the overload that takes a StdTokenMetadata
//         _setTokenMetadata(tokenId, _tokenMetadataToJson(data));
//     }

//     function exposed_getTokenMetadataKey(uint256 tokenId) external view returns (bytes32) {
//         return _getTokenMetadataKey(tokenId);
//     }
// }

// contract TokenMetadataTest is Test {
//     TokenMetadataHarness public tokenMetadata;
//     uint256 public constant TOKEN_ID = 1;

//     function setUp() public {
//         tokenMetadata = new TokenMetadataHarness();
//     }

//     function testBasicMetadataFlow() public {
//         // Create test metadata
//         Attribute[] memory attributes = new Attribute[](1);
//         attributes[0] = Attribute({ traitType: "Type1", value: "Value1", displayType: "string" });

//         StdTokenMetadata memory metadata = StdTokenMetadata({
//             name: "Test Token",
//             description: "Test Description",
//             image: "https://test.com/image.png",
//             externalURL: "https://test.com",
//             animationURL: "https://test.com/animation.mp4",
//             attributes: attributes
//         });

//         // Set metadata
//         tokenMetadata.exposed_setTokenMetadataWithStruct(TOKEN_ID, metadata);

//         // Test exists
//         assertTrue(tokenMetadata.exposed_exists(TOKEN_ID));
//         assertTrue(tokenMetadata.exposed_existsWithPath(TOKEN_ID, "attributes[0].value"));

//         // Test getters
//         assertEq(tokenMetadata.exposed_getTokenAttribute(TOKEN_ID, "Type1"), "Value1");

//         // Test immutability
//         vm.expectRevert(abi.encodeWithSelector(ITokenMetadata.TokenMetadataImmutable.selector, TOKEN_ID));
//         tokenMetadata.exposed_setTokenMetadataWithStruct(TOKEN_ID, metadata);
//     }

//     function testAttributeTypes() public {
//         string
//             memory jsonMetadata = '{"attributes":[{"trait_type":"number","value":"42"},{"trait_type":"bool","value":"true"}]}';
//         tokenMetadata.exposed_setTokenMetadata(TOKEN_ID, jsonMetadata);

//         // Test different attribute types
//         assertEq(tokenMetadata.exposed_getTokenAttributeUint(TOKEN_ID, "number"), 42);
//         assertTrue(tokenMetadata.exposed_getTokenAttributeBool(TOKEN_ID, "bool"));
//     }

//     function testMetadataKeyGeneration() public {
//         bytes32 key = tokenMetadata.exposed_getTokenMetadataKey(TOKEN_ID);
//         assertEq(key, bytes32(uint256(TOKEN_ID)));
//     }

//     function testNonExistentToken() public {
//         uint256 nonExistentToken = 999;
//         assertFalse(tokenMetadata.exposed_exists(nonExistentToken));

//         vm.expectRevert(); // The error type will depend on JsonStore implementation
//         tokenMetadata.exposed_getTokenMetadata(nonExistentToken);
//     }

//     function testMultipleAttributes() public {
//         // Create test metadata with multiple attributes
//         Attribute[] memory attributes = new Attribute[](3);
//         attributes[0] = Attribute({ traitType: "String", value: "Value1", displayType: "string" });
//         attributes[1] = Attribute({ traitType: "Number", value: "42", displayType: "number" });
//         attributes[2] = Attribute({ traitType: "Boolean", value: "true", displayType: "boolean" });

//         StdTokenMetadata memory metadata = StdTokenMetadata({
//             name: "Multi Attribute Token",
//             description: "Token with multiple attributes",
//             image: "https://test.com/image.png",
//             externalURL: "https://test.com",
//             animationURL: "",
//             attributes: attributes
//         });

//         tokenMetadata.exposed_setTokenMetadataWithStruct(TOKEN_ID, metadata);

//         // Test each attribute
//         assertEq(tokenMetadata.exposed_getTokenAttribute(TOKEN_ID, "String"), "Value1");
//         assertEq(tokenMetadata.exposed_getTokenAttributeUint(TOKEN_ID, "Number"), 42);
//         assertTrue(tokenMetadata.exposed_getTokenAttributeBool(TOKEN_ID, "Boolean"));
//     }
// }
