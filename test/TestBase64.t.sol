// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/utils/Base64.sol" ;

contract Base64Test is Test {
    using Base64 for bytes;

    function testEncode() public {
        // Test case for encode
        bytes memory data = bytes("hello world");
        string memory encoded = Base64.encode(data);
        string memory expected = "aGVsbG8gd29ybGQ="; // "hello world" in Base64
        assertEq(encoded, expected, "Base64 encode failed");
    }

    function testEncodeURL() public {
        // Test case for encodeURL
        bytes memory data = bytes("hello world");
        string memory encodedURL = Base64.encodeURL(data);
        string memory expected = "aGVsbG8gd29ybGQ"; // "hello world" in Base64URL without padding
        assertEq(encodedURL, expected, "Base64URL encode failed");
    }

    // function testDecode() public {
    //     // Test case for decode
    //     string memory encoded = "aGVsbG8gd29ybGQ="; // "hello world" in Base64
    //     bytes memory decoded = Base64.decode(encoded);
    //     bytes memory expected = bytes("hello world");
    //     assertEq(decoded, expected, "Base64 decode failed");
    // }

    // function testDecodeURL() public {
    //     // Test case for decodeURL
    //     string memory encodedURL = "aGVsbG8gd29ybGQ"; // "hello world" in Base64URL without padding
    //     bytes memory decodedURL = Base64.decodeURL(encodedURL);
    //     bytes memory expected = bytes("hello world");
    //     assertEq(decodedURL, expected, "Base64URL decode failed");
    // }

    // function testEncodeDecode() public {
    //     // Test round-trip encoding and decoding
    //     bytes memory data = bytes("Test encoding and decoding round-trip!");
    //     string memory encoded = Base64.encode(data);
    //     bytes memory decoded = Base64.decode(encoded);
    //     assertEq(decoded, data, "Round-trip Base64 encode/decode failed");
    // }

    // function testEncodeDecodeURL() public {
    //     // Test round-trip encoding and decoding for URL
    //     bytes memory data = bytes("Test encoding and decoding round-trip URL!");
    //     string memory encodedURL = Base64.encodeURL(data);
    //     bytes memory decodedURL = Base64.decodeURL(encodedURL);
    //     assertEq(decodedURL, data, "Round-trip Base64URL encode/decode failed");
    // }

    function testEmptyEncodeDecode() public {
        // Test edge case for empty input
        bytes memory data = bytes("");
        string memory encoded = Base64.encode(data);
        bytes memory decoded = Base64.decode(encoded);
        assertEq(decoded, data, "Empty Base64 encode/decode failed");
    }

    function testEmptyEncodeDecodeURL() public {
        // Test edge case for empty input in Base64URL
        bytes memory data = bytes("");
        string memory encodedURL = Base64.encodeURL(data);
        bytes memory decodedURL = Base64.decodeURL(encodedURL);
        assertEq(decodedURL, data, "Empty Base64URL encode/decode failed");
    }
}
