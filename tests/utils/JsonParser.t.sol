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

    function setUp() public {
        (parser, tokens) = JsonParser.init(10);
    }

    function testInit() public view {
        assertEq(parser.pos, 0);
        assertEq(parser.toknext, 0);
        assertEq(parser.toksuper, -1);
        assertEq(tokens.length, 10);
    }
}
