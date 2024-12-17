// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Lazy721A } from "../../contracts/apps/lazy721a.sol";
import "hardhat/console.sol";
// https://book.getfoundry.sh/reference/config/inline-test-config
// https://github.com/patrickd-/solidity-fuzzing-boilerplate

contract Lazy721ATest is StdCheats, Test {
    Lazy721A private lnft;
    address public user1;
    address public user2;
    uint16 public constant tokenCap = 4;

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        lnft = new Lazy721A("Lazy NFT", "LAZY", tokenCap, "ipfs://lazyhash/");
    }

    function testInitializeState() public view {
        assertEq(lnft.name(), "Lazy NFT");
        assertEq(lnft.symbol(), "LAZY");
        assertEq(lnft.owner(), address(this));
        assertEq(lnft.totalSupply(), 0);
    }

    function testSafeMint() public {
        lnft.safeMint(user1, 1);
        assertEq(lnft.totalSupply(), 1);
        assertEq(lnft.balanceOf(user1), 1);
        assertEq(lnft.balanceOf(user2), 0);
        assertEq(lnft.ownerOf(0), user1);

        lnft.safeMint(user2, 1);
        assertEq(lnft.totalSupply(), 2);
        assertEq(lnft.balanceOf(user1), 1);
        assertEq(lnft.balanceOf(user2), 1);
        assertEq(lnft.ownerOf(1), user2);
    }

    function test_TokenURI() public {
        lnft.safeMint(user1, 1);
        assertEq(lnft.tokenURI(0), "ipfs://lazyhash/0.json");

        lnft.safeMint(user2, 1);
        assertEq(lnft.tokenURI(1), "ipfs://lazyhash/1.json");
    }

    function testRevertWhenNonOwnerMints() public {
        vm.prank(user1);
        vm.expectRevert();
        lnft.safeMint(user2, 1);
    }

    function testRevertWhenTokenCapExceed() public {
        lnft.safeMint(user1, 1);
        lnft.safeMint(user1, 1);
        lnft.safeMint(user1, 1);
        lnft.safeMint(user1, 1);

        vm.expectRevert(Lazy721A.Lazy721A__TokenCapExceeded.selector);
        lnft.safeMint(user1, 1);
    }

    function testRevertWhenQueryNonexistentToken() public {
        vm.expectRevert();
        lnft.tokenURI(999);
    }

    function test_SupportsInterface() public view {
        // Test ERC721 interface support
        assertTrue(lnft.supportsInterface(0x80ac58cd)); // ERC165 interface ID for ERC721.
        assertTrue(lnft.supportsInterface(0x01ffc9a7)); // ERC165 interface ID for ERC165.
        assertTrue(lnft.supportsInterface(0x5b5e139f)); // ERC165 interface ID for ERC721Metadata.
    }

    /// forge-config: default.fuzz.show-logs = true
    /// forge-config: default.invariant.fail-on-revert = true
    function testFuzz_Mint_Name(string memory name) public {
        Lazy721A newNft = new Lazy721A(name, "LAZY", 4, "ipfs://lazyhash");
        assertEq(newNft.name(), name);
    }

    /// forge-config: default.fuzz.runs = 300
    function testFuzz_Mint_Quantity(uint16 quantity, string memory uri) public {
        vm.assume(quantity > 0);
        Lazy721A newNft = new Lazy721A("Lazy NFT", "LAZY", quantity, uri);
        assertEq(newNft.totalSupply(), 0);
        // LazyNFTTest is the owner
        newNft.safeMint(address(this), quantity);
        assertEq(newNft.totalSupply(), quantity);
    }
}
