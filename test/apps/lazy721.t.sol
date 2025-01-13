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

    function testPauseState() public {
        lnft.pause();
        assertTrue(lnft.paused());
        
        lnft.unpause();
        assertFalse(lnft.paused());
    }

    // Test minting while paused
    function testPausedMint() public {
        lnft.pause();
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        lnft.safeMint(user1);
    }

    // Test transfers while paused
    function testPausedTransfer() public {
        lnft.safeMint(user1);
        lnft.pause();
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        lnft.transferFrom(user1, user2, 0);
    }

    function testBurnToken() public {
        lnft.safeMint(user1);
        
        vm.prank(user1);
        lnft.burn(0);
        
        assertEq(lnft.totalSupply(), 0);
        assertEq(lnft.balanceOf(user1), 0);
        
        // Update the error expectation to match OpenZeppelin's custom error
        vm.expectRevert(abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 0));
        lnft.ownerOf(0);
    }

    function testApproveAndTransfer() public {
        lnft.safeMint(user1);
        
        vm.prank(user1);
        lnft.approve(user2, 0);
        assertEq(lnft.getApproved(0), user2);
        
        vm.prank(user2);
        lnft.transferFrom(user1, address(this), 0);
        assertEq(lnft.ownerOf(0), address(this));
    }

    function testApprovalClearsAfterTransfer() public {
        lnft.safeMint(user1);
        
        vm.prank(user1);
        lnft.approve(user2, 0);
        
        vm.prank(user2);
        lnft.transferFrom(user1, address(this), 0);
        
        assertEq(lnft.getApproved(0), address(0));
    }

    function testSetApprovalForAll() public {
        lnft.safeMint(user1);
        
        vm.prank(user1);
        lnft.setApprovalForAll(user2, true);
        assertTrue(lnft.isApprovedForAll(user1, user2));
    }

    function testOperatorTransfer() public {
        lnft.safeMint(user1);
        
        vm.prank(user1);
        lnft.setApprovalForAll(user2, true);
        
        vm.prank(user2);
        lnft.transferFrom(user1, address(this), 0);
        assertEq(lnft.ownerOf(0), address(this));
    }

    function testEnumerableOwnerByIndex() public {
        lnft.safeMint(user1);  // ID 0
        lnft.safeMint(user1);  // ID 1
        
        assertEq(lnft.tokenOfOwnerByIndex(user1, 0), 0);
        assertEq(lnft.tokenOfOwnerByIndex(user1, 1), 1);
        
        vm.expectRevert(abi.encodeWithSignature(
            "ERC721OutOfBoundsIndex(address,uint256)",
            user1,
            2
        ));
        lnft.tokenOfOwnerByIndex(user1, 2);
    }

    function testEnumerableTokenByIndex() public {
        lnft.safeMint(user1);
        lnft.safeMint(user2);
        
        assertEq(lnft.tokenByIndex(0), 0);
        assertEq(lnft.tokenByIndex(1), 1);
        
        vm.expectRevert(abi.encodeWithSignature(
            "ERC721OutOfBoundsIndex(address,uint256)",
            address(0),
            2
        ));
        lnft.tokenByIndex(2);
    }

    function testRevertTransferUnauthorized() public {
        lnft.safeMint(user1);
        
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSignature(
            "ERC721InsufficientApproval(address,uint256)",
            user2,
            0
        ));
        lnft.transferFrom(user1, user2, 0);
    }
}
