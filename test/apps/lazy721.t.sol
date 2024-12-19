// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Lazy721 } from "../../contracts/apps/lazy721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "hardhat/console.sol";
// https://book.getfoundry.sh/reference/config/inline-test-config
// https://github.com/patrickd-/solidity-fuzzing-boilerplate

contract Lazy721Test is StdCheats, Test, ERC721Holder {
    Lazy721 private lnft;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        lnft = new Lazy721("Lazy NFT", "LAZY", 4, "ipfs://lazyhash/");
    }

    function testInitializeState() public view {
        assertEq(lnft.name(), "Lazy NFT");
        assertEq(lnft.symbol(), "LAZY");
        assertEq(lnft.owner(), address(this));
        assertEq(lnft.totalSupply(), 0);
    }

    function testSafeMint() public {
        lnft.safeMint(user1);
        assertEq(lnft.totalSupply(), 1);
        assertEq(lnft.balanceOf(user1), 1);
        assertEq(lnft.balanceOf(user2), 0);
        assertEq(lnft.ownerOf(0), user1);

        lnft.safeMint(user2);
        assertEq(lnft.totalSupply(), 2);
        assertEq(lnft.balanceOf(user1), 1);
        assertEq(lnft.balanceOf(user2), 1);
        assertEq(lnft.ownerOf(1), user2);
    }

    function test_TokenURI() public {
        lnft.safeMint(user1);
        assertEq(lnft.tokenURI(0), "ipfs://lazyhash/0.json");

        lnft.safeMint(user2);
        assertEq(lnft.tokenURI(1), "ipfs://lazyhash/1.json");
    }

    function testRevertWhenNonOwnerMints() public {
        vm.prank(user1);
        vm.expectRevert();
        lnft.safeMint(user2);
    }

    function testRevertWhenTokenCapExceed() public {
        lnft.safeMint(user1);
        lnft.safeMint(user1);
        lnft.safeMint(user1);
        lnft.safeMint(user1);

        vm.expectRevert(Lazy721.Lazy721__TokenCapExceeded.selector);
        lnft.safeMint(user1);
    }

    function testRevertWhenQueryNonexistentToken() public {
        vm.expectRevert();
        lnft.tokenURI(999);
    }

    function test_SupportsInterface() public view {
        // Test ERC721 interface support
        assertTrue(lnft.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(lnft.supportsInterface(0x780e9d63)); // ERC721Enumerable
        assertTrue(lnft.supportsInterface(0x5b5e139f)); // ERC721Metadata
    }

    // forge-config: default.fuzz.show-logs = true
    // forge-config: default.invariant.fail-on-revert = true
    function testFuzz_Mint(string memory name) public {
        Lazy721 newNft = new Lazy721(name, "LNT", 4, "ipfs://lazyhash/");
        assertEq(newNft.name(), name);
    }

    // forge-config: default.fuzz.runs = 300
    function testFuzz_Mint(uint16 quantity) public {
        vm.assume(quantity > 0);
        Lazy721 newNft = new Lazy721("LazyNFT", "LNT", quantity, "ipfs://lazyhash/");
        assertEq(newNft.totalSupply(), 0);
        for (uint256 i = 0; i < quantity; ++i) {
            // LazyNFTTest is the owner
            newNft.safeMint(address(this));
        }
        assertEq(newNft.totalSupply(), quantity);
    }
}
