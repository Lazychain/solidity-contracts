// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../lib/forge-std/src/Test.sol";
import "../../contracts/utils/JsonParser.sol";

contract JsonParserTest is Test {
    function testValidJsonObject() public pure {
        string memory json = '{"name":"John","age":30}';
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(json, 32);

        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
        assertGt(count, 0);
        // First token should be an object
        assertEq(uint(tokens[0].jsonType), uint(JsonParser.JsonType.OBJECT));
    }

    function testValidJsonArray() public pure {
        string memory json = '[1,2,3,"four"]';
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(json, 32);

        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
        assertGt(count, 0);
        // First token should be an array
        assertEq(uint(tokens[0].jsonType), uint(JsonParser.JsonType.ARRAY));
    }

    function testNestedJson() public pure {
        string memory json = '{"data":{"numbers":[1,2,3],"active":true}}';
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(json, 32);

        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
        assertGt(count, 0);
        assertEq(uint(tokens[0].jsonType), uint(JsonParser.JsonType.OBJECT));
    }

    function testInvalidJson() public pure {
        string memory json = '{"name":John}'; // Missing quotes around John
        (uint8 returnCode, , ) = JsonParser.parse(json, 32);
        assertEq(returnCode, JsonParser.RETURN_ERROR_INVALID_JSON);
    }

    function testEmptyObject() public pure {
        string memory json = "{}";
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(json, 32);

        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
        assertGt(count, 0);
        assertEq(uint(tokens[0].jsonType), uint(JsonParser.JsonType.OBJECT));
    }

    function testEmptyArray() public pure {
        string memory json = "[]";
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(json, 32);

        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
        assertGt(count, 0);
        assertEq(uint(tokens[0].jsonType), uint(JsonParser.JsonType.ARRAY));
    }

    function testComplexJson() public pure {
        string
            memory json = '{"menu":{"id":"file","value":"File","popup":{"menuitem":[{"value":"New","onclick":"CreateNewDoc()"},{"value":"Open","onclick":"OpenDoc()"}]}}}';
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(json, 64);

        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
        assertGt(count, 0);
        assertEq(uint(tokens[0].jsonType), uint(JsonParser.JsonType.OBJECT));
    }

    function testStringUtilities() public pure {
        // Test parseInt
        assertEq(JsonParser.parseInt("123"), 123);
        assertEq(JsonParser.parseInt("-123"), -123);
        assertEq(JsonParser.parseInt("12.34", 2), 12);

        // Test uint2str
        assertEq(JsonParser.uint2str(123), "123");
        assertEq(JsonParser.uint2str(0), "0");

        // Test parseBool
        assertTrue(JsonParser.parseBool("true"));
        assertFalse(JsonParser.parseBool("false"));

        // Test strCompare
        assertEq(JsonParser.strCompare("abc", "abc"), 0);
        assertEq(JsonParser.strCompare("abc", "def"), -1);
        assertEq(JsonParser.strCompare("def", "abc"), 1);
    }

    function testWhitespaceHandling() public pure {
        string memory json = ' { \n\t"key"\r:\n"value"\t } ';
        (uint8 returnCode, , ) = JsonParser.parse(json, 32);
        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
    }

    // function testInvalidEscapeSequence() public {
    //     string memory json = '{"key":"\z"}'; // \z is not a valid escape sequence
    //     (uint8 returnCode, , ) = JsonParser.parse(json, 32);
    //     assertEq(returnCode, JsonParser.RETURN_ERROR_INVALID_JSON);
    // }

    function testValidEscapeSequences() public pure {
        string memory json = '{"key":"\\n\\t\\r\\b\\f\\/\\\\\\""}';
        (uint8 returnCode, , ) = JsonParser.parse(json, 32);
        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
    }

    function testPrimitiveTypes() public pure {
        string memory json = '{"nullValue":null,"boolValue":true,"numberValue":42}';
        (uint8 returnCode /*JsonParser.Token[] memory tokens*/, , uint256 count) = JsonParser.parse(json, 32);

        assertEq(returnCode, JsonParser.RETURN_SUCCESS);
        assertGt(count, 0);
    }

    function testGetBytes() public pure {
        string memory json = "Hello, World!";
        string memory substr = JsonParser.getBytes(json, 0, 5);
        assertEq(substr, "Hello");
    }

    function testMemoryLimit() public pure {
        // This JSON requires at least 3 tokens:
        // 1. The object itself
        // 2. The "key" string
        // 3. The "value" string
        string memory json = '{"key":"value"}';

        // Only allocate 1 token - should fail with NO_MEM
        (uint8 returnCode, , ) = JsonParser.parse(json, 1);

        console.log("Return code:", returnCode); // Add this for debugging
        assertEq(returnCode, JsonParser.RETURN_ERROR_NO_MEM);
    }
}
