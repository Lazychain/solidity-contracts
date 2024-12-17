// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { LazyNFT } from "@Lazychain/solidity-contracts/contracts/apps/nft.sol";

contract LazyNftTest is Test {
    LazyNFT public lnft;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.prank(owner);
        lnft = new LazyNFT(owner, "Lazy NFT", "LAZY");
    }

    function testInitializeState() public {
        assertEq(lnft.name(), "Lazy NFT");
        assertEq(lnft.symbol(), "LAZY");
        assertEq(lnft.owner(), owner);
        assertEq(lnft.totalSupply(), 0);
    }

    function testSafeMint() public {
        vm.startPrank(owner);

        lnft.safeMint(user1);
        assertEq(lnft.totalSupply(), 1);
        assertEq(lnft.balanceOf(user1), 1);
        assertEq(lnft.balanceOf(user2), 0);
        assertEq(lnft.ownerOf(0), user1);

        lnft.safeMint(user2);
        assertEq(lnft.totalSupply(), 2);
        assertEq(lnft.balanceOf(user1), 1);
        assertEq(lnft.balanceOf(user1), 1);
        assertEq(lnft.ownerOf(1), user2);

        vm.stopPrank();
    }

    function test_TokenURI() public {
        vm.startPrank(owner);
        lnft.safeMint(user1);
        assertEq(lnft.tokenURI(0), "ipfs://lazyhash/0.json");

        lnft.safeMint(user2);
        assertEq(lnft.tokenURI(1), "ipfs://lazyhash/1.json");

        vm.stopPrank();
    }

    function testRevertWhenNonOwnerMints() public {
        vm.prank(user1);
        vm.expectRevert();
        lnft.safeMint(user2);
    }

    function testRevertWhenTokenCapExceed() public {
        vm.startPrank(owner);

        lnft.safeMint(user1);
        lnft.safeMint(user1);
        lnft.safeMint(user1);
        lnft.safeMint(user1);

        vm.expectRevert(LazyNFT.LazyNFT__TokenCapExceeded.selector);
        lnft.safeMint(user1);

        vm.stopPrank();
    }

    function testRevertWhenQueryNonexistentToken() public {
        vm.expectRevert();
        lnft.tokenURI(999);
    }

    function test_SupportsInterface() public {
        // Test ERC721 interface support
        assertTrue(lnft.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(lnft.supportsInterface(0x780e9d63)); // ERC721Enumerable
        assertTrue(lnft.supportsInterface(0x5b5e139f)); // ERC721Metadata
    }
}
