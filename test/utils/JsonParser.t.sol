// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../lib/forge-std/src/Test.sol";
import "../../contracts/utils/JsonParser.sol";

contract JsonParserTest is Test {
    using JsonParser for JsonParser.Parser;
    using JsonParser for JsonParser.Token;

    // Initialize parser and tokens for each test
    JsonParser.Parser parser;
    JsonParser.Token[] tokens;

    // function setUp() public {
    //     helperSetToken(10);
    // }

    /////////////
    // Helpers //
    /////////////
    modifier helperSetToken(uint256 initSize) {
        JsonParser.Token[] memory tempTokens;
        (parser, tempTokens) = JsonParser.init(initSize);

        delete tokens;
        for (uint i = 0; i < tempTokens.length; i++) {
            tokens.push(tempTokens[i]);
        }
        _;
    }

    function testInit() public helperSetToken(10) {
        assertEq(parser.pos, 0);
        assertEq(parser.toknext, 0);
        assertEq(parser.toksuper, -1);
        assertEq(tokens.length, 10);
    }

    function testAllocateTokenSuccess() public helperSetToken(10) {
        (bool success, JsonParser.Parser memory p, JsonParser.Token memory token) = JsonParser.allocateToken(
            parser,
            tokens
        );
        assertTrue(success);
        // Values set to default
        assertEq(abi.encode(token.jsonType), abi.encode(JsonParser.JsonType.UNDEFINED));
        assertEq(token.start, 0);
        assertEq(token.startSet, false);
        assertEq(token.end, 0);
        assertEq(token.endSet, false);
        assertEq(token.size, 0);

        assertEq(p.toknext, 1);
    }

    function testAllocateTokenFail() public helperSetToken(1) {
        parser.toknext = 1; // Full capacity
        (bool success, , ) = JsonParser.allocateToken(parser, tokens);
        assertFalse(success);
    }

    function testFillToken() public helperSetToken(10) {
        JsonParser.Token memory token;
        token = JsonParser.fillToken(token, JsonParser.JsonType.STRING, 0, 5);
        assertEq(abi.encode(token.jsonType), abi.encode(JsonParser.JsonType.STRING));
        assertTrue(token.startSet);
        assertEq(token.start, 0);
        assertTrue(token.endSet);
        assertEq(token.end, 5);
    }

    function testParseStringSuccess() public helperSetToken(10) {
        bytes memory json = '"hello"';
        parser.pos = 0;
        (uint256 result, JsonParser.Parser memory parzer, JsonParser.Token memory token) = JsonParser.parseString(
            parser,
            tokens,
            json
        );
        assertEq(result, JsonParser.RETURN_SUCCESS);
        assertEq(parzer.pos, 6);
        assertEq(token.start, 1);
        assertEq(token.end, 6);
    }

    function testParseStringInvalidJson() public {
        bytes memory json = '"hello\\q"';
        parser.pos = 0;
        (uint256 result, , ) = JsonParser.parseString(parser, tokens, json);
        assertEq(result, JsonParser.RETURN_ERROR_INVALID_JSON);
    }

    function testParseStringPartError() public {
        bytes memory json = '"hello';
        parser.pos = 0;
        (uint256 result, , ) = JsonParser.parseString(parser, tokens, json);
        assertEq(result, JsonParser.RETURN_ERROR_PART);
    }

    // function testParsePrimitiveSuccess() public helperSetToken(10) {
    //     bytes memory json = "12345";
    //     parser.pos = 0;
    //     (uint256 result, , JsonParser.Token memory token) = JsonParser.parsePrimitive(parser, tokens, json);
    //     assertEq(result, JsonParser.RETURN_SUCCESS);
    //     assertEq(token.start, 0);
    //     assertEq(token.end, 5);
    // }
}
