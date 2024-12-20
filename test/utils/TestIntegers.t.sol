// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../contracts/utils/Integers.sol";

contract IntegersTest is Test {
    using Integers for uint256;
    using Integers for int256;

    error InvalidHexString();
    error InvalidHexCharacter();

    function testToStringUint256() public {
        assertEq(uint256(0).toString(), "0");
        assertEq(uint256(12345).toString(), "12345");
        assertEq(uint256(9876543210).toString(), "9876543210");
    }

    function testToStringInt256() public {
        assertEq(int256(0).toString(), "0");
        assertEq(int256(-12345).toString(), "-12345");
        assertEq(int256(1234567890).toString(), "1234567890");
    }

    function testToHexStringUint256() public {
        assertEq(uint256(0).toHexString(), "0x0");
        assertEq(uint256(255).toHexString(), "0xff");
        assertEq(uint256(4096).toHexString(), "0x1000");
    }

    function testToHexStringWithLength() public {
        assertEq(uint256(255).toHexString(4), "0x00ff");
        assertEq(uint256(16).toHexString(2), "0x10");
    }

    function testFromHexString() public {
        assertEq(Integers.fromHexString("0x0"), 0);
        assertEq(Integers.fromHexString("0xff"), 255);
        assertEq(Integers.fromHexString("0x10"), 16);
        assertEq(Integers.fromHexString("0xabcdef"), 0xabcdef);
    }

    function testInvalidHexString() public {
        vm.expectRevert(InvalidHexString.selector);
        Integers.fromHexString("0x");
    }
}
