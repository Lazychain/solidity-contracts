// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/utils/Base64.sol" ;

contract Base64Test is Test {
    using Base64 for bytes;

    function testEncode() public {
        bytes memory data = bytes("hello world");
        string memory encoded = Base64.encode(data);
        string memory expected = "aGVsbG8gd29ybGQ="; // "hello world" in Base64
        assertEq(encoded, expected, "Base64 encode failed");
    }

    function testEncodeURL() public {
        bytes memory data = bytes("hello world");
        string memory encodedURL = Base64.encodeURL(data);
        string memory expected = "aGVsbG8gd29ybGQ";
        assertEq(encodedURL, expected, "Base64URL encode failed");
    }

    function testDecode() public {
        bytes memory decoded = Base64.decode("SGVsbG8=");
        assertEq(string(decoded), "Hello");
    }

    function testEncodeDecode() public {
        bytes memory data = bytes("Test encoding and decoding round-trip!");
        string memory encoded = Base64.encode(data);
        bytes memory decoded = Base64.decode(encoded);
        assertEq(decoded, data, "Round-trip Base64 encode/decode failed");
    }

    function testEncodeDecodeURL() public {
        bytes memory data = bytes("Test encoding and decoding round-trip URL!");
        string memory encodedURL = Base64.encodeURL(data);
        bytes memory decodedURL = Base64.decodeURL(encodedURL);
        assertEq(decodedURL, data, "Round-trip Base64URL encode/decode failed");
    }

    function testEmptyEncodeDecode() public {
        bytes memory data = bytes("");
        string memory encoded = Base64.encode(data);
        bytes memory decoded = Base64.decode(encoded);
        assertEq(decoded, data, "Empty Base64 encode/decode failed");
    }

    function testEmptyEncodeDecodeURL() public {
        bytes memory data = bytes("");
        string memory encodedURL = Base64.encodeURL(data);
        bytes memory decodedURL = Base64.decodeURL(encodedURL);
        assertEq(decodedURL, data, "Empty Base64URL encode/decode failed");
    }
}
