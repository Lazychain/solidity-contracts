// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/utils/Base64.sol";

contract Base64Test is Test {
    using Base64 for bytes;

    function testEncode() public pure {
        bytes memory data = bytes("hello world");
        string memory encoded = Base64.encode(data);
        string memory expected = "aGVsbG8gd29ybGQ="; // "hello world" in Base64
        assertEq(encoded, expected, "Base64 encode failed");
    }

    function testEncodeURL() public pure {
        bytes memory data = bytes("http://lazy.fun:8545");
        string memory encodedURL = Base64.encode(data);
        string memory expected = "aHR0cDovL2xhenkuZnVuOjg1NDU=";
        assertEq(encodedURL, expected, "Base64URL encode failed");
    }

    function testDecodePath() public pure {
        bytes memory filePath = bytes("file://pepe.json");
        string memory encodedfilePath = Base64.encode(filePath);
        string memory expectedfilePath = "ZmlsZTovL3BlcGUuanNvbg==";

        assertEq(encodedfilePath, expectedfilePath, "Base64URL encode for path failed");
    }

    function testDecode() public pure {
        bytes memory decoded = Base64.decode("SGVsbG8=");
        assertEq(string(decoded), "Hello");
    }

    function testEncodeDecode() public pure {
        bytes memory data = bytes("Test encoding and decoding round-trip!");
        string memory encoded = Base64.encode(data);
        bytes memory decoded = Base64.decode(encoded);
        assertEq(decoded, data, "Round-trip Base64 encode/decode failed");
    }

    function testEncodeDecodeURL() public pure {
        bytes memory data = bytes("http://lazy.fun:8545");
        string memory encodedURL = Base64.encode(data);
        bytes memory decodedURL = Base64.decode(encodedURL);
        assertEq(decodedURL, data, "Round-trip Base64URL encode/decode failed");
    }

    function testEmptyEncodeDecode() public pure {
        bytes memory data = bytes("");
        string memory encoded = Base64.encode(data);
        bytes memory decoded = Base64.decode(encoded);
        assertEq(decoded, data, "Empty Base64 encode/decode failed");
    }

    function testEmptyEncodeDecodeURL() public pure {
        bytes memory data = bytes("");
        string memory encodedURL = Base64.encode(data);
        bytes memory decodedURL = Base64.decode(encodedURL);
        assertEq(decodedURL, data, "Empty Base64URL encode/decode failed");
    }

    function testEncodeMaxLength() public {
        bytes memory tooLongInput = new bytes(1_000_001); // MAX_INPUT_LENGTH + 1

        // Fill with some data
        for (uint i = 0; i < tooLongInput.length; i++) {
            tooLongInput[i] = 0x41; // ASCII 'A'
        }

        vm.expectRevert(Base64.Base64InputTooLong.selector);
        Base64.encode(tooLongInput);

        vm.expectRevert(Base64.Base64InputTooLong.selector);
        Base64.encode(tooLongInput);

        // Test with exactly max length (should pass)
        bytes memory maxLengthInput = new bytes(1_000_000); // MAX_INPUT_LENGTH
        for (uint i = 0; i < maxLengthInput.length; i++) {
            maxLengthInput[i] = 0x41;
        }

        // These should not revert
        Base64.encode(maxLengthInput);
        Base64.encode(maxLengthInput);
    }

    function testInvalidDecodeLength() public {
        // Create input with length not multiple of 4
        string memory invalidLength = "SGVsbG8=W"; // 9 characters

        vm.expectRevert(Base64.Base64InvalidInputLength.selector);
        Base64.decode(invalidLength);

        vm.expectRevert(Base64.Base64InvalidInputLength.selector);
        Base64.decode(invalidLength);
    }
}
