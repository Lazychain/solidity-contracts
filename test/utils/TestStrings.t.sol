// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@Lazychain/solidity-contracts/contracts/utils/Strings.sol";

contract StringsTest is Test {
    using Strings for string;

    // Test variables
    string private constant STR1 = "hello";
    string private constant STR2 = "hello";
    string private constant STR3 = "HELLO";
    string private constant STR4 = "Hello, world!";
    string private constant EMPTY = "";

    function testEqual() public {
        assertTrue(STR1.equal(STR2), "Equal strings should return true");
        assertFalse(STR1.equal(STR3), "Different strings should return false");
    }

    function testEqualCaseFold() public {
        assertTrue(STR1.equalCaseFold(STR3), "Case-insensitive equal should return true");
        assertFalse(STR1.equalCaseFold(STR4), "Different strings should return false");
    }

    function testContains() public {
        assertTrue(STR4.contains("Hello"), "Substring should be found");
        assertFalse(STR4.contains("hi"), "Non-existing substring should return false");
        assertTrue(EMPTY.contains(""), "Empty substring should return true on empty string");
    }

    function testStartsWith() public {
        assertTrue(STR4.startsWith("Hello"), "String should start with 'Hello'");
        assertFalse(STR4.startsWith("world"), "String should not start with 'world'");
    }

    function testEndsWith() public {
        assertTrue(STR4.endsWith("world!"), "String should end with 'world!'");
        assertFalse(STR4.endsWith("Hello"), "String should not end with 'Hello'");
    }

    function testIndexOf() public {
        assertEq(STR4.indexOf("world"), 7, "Index of 'world' should be 7");
        assertEq(STR4.indexOf("nonexistent"), type(uint256).max, "Nonexistent substring should return max uint256");
    }

    function testToLowerCase() public {
        string memory result = STR3.toLowerCase();
        assertEq(result, "hello", "Converted string should be in lowercase");
    }

    function testToUpperCase() public {
        string memory result = STR1.toUpperCase();
        assertEq(result, "HELLO", "Converted string should be in uppercase");
    }

    function testPadStart() public {
        string memory result = STR1.padStart(10, " ");
        assertEq(result, "     hello", "String should be padded at the start");
    }

    function testPadEnd() public {
        string memory result = STR1.padEnd(10, " ");
        assertEq(result, "hello     ", "String should be padded at the end");
    }

    function testRepeat() public {
        string memory result = STR1.repeat(3);
        assertEq(result, "hellohellohello", "String should be repeated 3 times");
    }

    function testReplace() public {
        string memory result = STR4.replace("world", "universe", 1);
        assertEq(result, "Hello, universe!", "First occurrence should be replaced");
    }

    function testReplaceAll() public {
        string memory str = "test string test string";
        string memory result = str.replaceAll("test", "new");
        assertEq(result, "new string new string", "All occurrences should be replaced");
    }

    function testSplit() public {
        string memory str = "one,two,three";
        string[] memory result = str.split(",");
        assertEq(result.length, 3, "Split should return 3 parts");
        assertEq(result[0], "one", "First part should be 'one'");
        assertEq(result[1], "two", "Second part should be 'two'");
        assertEq(result[2], "three", "Third part should be 'three'");
    }

    function testTrim() public {
        string memory str = "   trimmed string   ";
        string memory result = str.trim();
        assertEq(result, "trimmed string", "Whitespace should be removed from both ends");
    }
}
