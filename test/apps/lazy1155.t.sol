// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Lazy1155 } from "../../contracts/apps/lazy1155.sol";
// https://book.getfoundry.sh/reference/config/inline-test-config
// https://github.com/patrickd-/solidity-fuzzing-boilerplate
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC1155MetadataURI } from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
// import { console } from "forge-std/console.sol";

contract Lazy1155Test is StdCheats, Test, ERC1155Holder {
    Lazy1155 private lnft;
    address public user1;
    address public user2;
    uint16 public constant tokenCap = 4;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        lnft = new Lazy1155(tokenCap, "ipfs://lazyhash/{id}.json");
    }

    function testInitializeState() public {
        assertEq(lnft.owner(), address(this));
        assertEq(lnft.totalSupply(), 0);
    }

    function testmint() public {
        // TODO: here owner track tokenId?
        uint256 user1TokenId = 0;
        uint256 user2TokenId = 0;
        lnft.mint(user1, user1TokenId, 1, "");
        assertEq(lnft.totalSupply(), 1);
        assertEq(lnft.balanceOf(user1, user1TokenId), 1);
        assertEq(lnft.balanceOf(user2, user2TokenId), 0);
        //assertEq(lnft.ownerOf(0), user1);

        lnft.mint(user2, user2TokenId, 1, "");
        assertEq(lnft.totalSupply(), 2);
        assertEq(lnft.balanceOf(user1, user1TokenId), 1);
        assertEq(lnft.balanceOf(user2, user2TokenId), 1);
        //assertEq(lnft.ownerOf(1), user2);
    }

    function test_TokenURI() public {
        assert(!lnft.tokenExists(0));
        assert(!lnft.isOwnerOfToken(user1, 0));
        lnft.mint(user1, 0, 1, "");
        assert(lnft.tokenExists(0));
        assert(lnft.isOwnerOfToken(user1, 0));
        assertEq(lnft.tokenURI(user1, 0), "ipfs://lazyhash/0.json");

        lnft.mint(user2, 0, 1, "");
        assert(lnft.isOwnerOfToken(user2, 0));
        assertEq(lnft.tokenURI(user2, 0), "ipfs://lazyhash/0.json");
    }

    function testRevertWhenNonOwnerMints() public {
        vm.prank(user1);
        vm.expectRevert();
        lnft.mint(user2, 1, 1, "");
    }

    function testRevertWhenTokenCapExceed() public {
        lnft.mint(user1, 1, 1, "");
        lnft.mint(user1, 1, 1, "");
        lnft.mint(user1, 1, 1, "");
        lnft.mint(user1, 1, 1, "");

        vm.expectRevert(Lazy1155.Lazy1155__TokenCapExceeded.selector);
        lnft.mint(user1, 1, 1, "");
    }

    function testRevertWhenQueryNonexistentToken() public {
        vm.expectRevert(Lazy1155.Lazy1155__TokenIdDoesntExist.selector);
        lnft.tokenURI(user2, 1);
    }

    function test_SupportsInterface() public view {
        // Test ERC721 interface support
        assertTrue(lnft.supportsInterface(type(IERC1155).interfaceId)); // ERC165 interface ID for ERC721.
        assertTrue(lnft.supportsInterface(type(IERC1155MetadataURI).interfaceId)); // ERC165 interface ID for ERC165.
        assertTrue(lnft.supportsInterface(type(IERC165).interfaceId)); // ERC165 interface ID for ERC721Metadata.
    }

    /// forge-config: default.fuzz.runs = 10
    function testFuzz_Mint(uint16 quantity) public {
        vm.assume(quantity > 0);
        Lazy1155 newNft = new Lazy1155(quantity, "ipfs/lazyhash/{id}.json");
        assertEq(newNft.totalSupply(), 0);
        for (uint256 i = 0; i < quantity; ++i) {
            // LazyNFTTest is the owner
            newNft.mint(address(this), i, 1, "");
        }
        assertEq(newNft.totalSupply(), quantity);
    }

    /// forge-config: default.fuzz.runs = 10
    function testFuzz_BatchMint(uint16 newTokenCap) public {
        uint8 maxIds = 10;
        // Ensure that at least 1 quantity token can be mint for that id
        vm.assume(newTokenCap > maxIds);
        vm.assume(newTokenCap < maxIds * 2);

        // Given a 1155 contract with zero initial minted tokens
        Lazy1155 newNft = new Lazy1155(newTokenCap, "ipfs/lazyhash/{id}.json");
        assertEq(newNft.totalSupply(), 0);

        uint256 quantity = newTokenCap / maxIds;

        // When MintBatch Tokens
        uint256[] memory ids = new uint256[](maxIds);
        uint256[] memory amounts = new uint256[](maxIds);

        for (uint256 n = 0; n < maxIds; n++) {
            ids[n] = n;
            amounts[n] = quantity;
        }
        newNft.mintBatch(address(this), ids, amounts, "");

        uint256 totalNewBalance = 0;
        for (uint256 n = 0; n < ids.length; n++) {
            uint256 balance = newNft.balanceOf(address(this), ids[n]);
            totalNewBalance += balance;
        }

        assertEq(totalNewBalance, newNft.totalSupply());
    }

    function testPauseAndUnpause() public {
        lnft.pause();
        assertTrue(lnft.paused());
        
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        lnft.mint(user1, 0, 1, "");
        
        lnft.unpause();
        assertFalse(lnft.paused());
        
        // Should work after unpause
        lnft.mint(user1, 0, 1, "");
        assertEq(lnft.balanceOf(user1, 0), 1);
    }

    function testSetURI() public {
        string memory newUri = "https://newdomain.com/token/{id}";
        lnft.setURI(newUri);
        
        lnft.mint(user1, 1, 1, "");
        assertEq(lnft.tokenURI(user1, 1), "https://newdomain.com/token/1");
    }

    function testBurnTokens() public {
        // Reduced amount to stay within cap
        lnft.mint(user1, 0, 2, "");
        assertEq(lnft.balanceOf(user1, 0), 2);
        
        vm.prank(user1);
        lnft.burn(user1, 0, 1);
        assertEq(lnft.balanceOf(user1, 0), 1);
        
        // Test batch burn
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 0;
        amounts[0] = 1;
        
        vm.prank(user1);
        lnft.burnBatch(user1, ids, amounts);
        assertEq(lnft.balanceOf(user1, 0), 0);
        assertFalse(lnft.tokenExists(0));
    }

    function testApprovalAndTransfer() public {
        lnft.mint(user1, 0, 2, "");
        
        vm.prank(user1);
        lnft.setApprovalForAll(user2, true);
        assertTrue(lnft.isApprovedForAll(user1, user2));
        
        // Transfer using approved operator
        vm.prank(user2);
        lnft.safeTransferFrom(user1, address(this), 0, 1, "");
        
        assertEq(lnft.balanceOf(user1, 0), 1);
        assertEq(lnft.balanceOf(address(this), 0), 1);
    }

    function testBatchTransferAndBalance() public {
        // Reduced amounts to stay within cap
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        
        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 1;
        
        lnft.mintBatch(user1, ids, amounts, "");
        
        vm.startPrank(user1);
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 1;
        transferAmounts[1] = 1;
        
        lnft.safeBatchTransferFrom(user1, user2, ids, transferAmounts, "");
        vm.stopPrank();
        
        assertEq(lnft.balanceOf(user1, 0), 0);
        assertEq(lnft.balanceOf(user1, 1), 0);
        assertEq(lnft.balanceOf(user2, 0), 1);
        assertEq(lnft.balanceOf(user2, 1), 1);
    }

    function testRevertInvalidBatchTransfer() public {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](1); // Mismatched arrays
        
        vm.expectRevert(abi.encodeWithSignature("ERC1155InvalidArrayLength(uint256,uint256)", 2, 1));
        lnft.mintBatch(user1, ids, amounts, "");
    }

    function testRevertUnauthorizedTransfer() public {
        lnft.mint(user1, 0, 1, "");
        
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSignature(
            "ERC1155MissingApprovalForAll(address,address)",
            user2,
            user1
        ));
        lnft.safeTransferFrom(user1, user2, 0, 1, "");
    }

    function testZeroAddressTransfer() public {
        lnft.mint(user1, 0, 1, "");
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature(
            "ERC1155InvalidReceiver(address)",
            address(0)
        ));
        lnft.safeTransferFrom(user1, address(0), 0, 1, "");
    }

    function testTransferExceedingBalance() public {
        lnft.mint(user1, 0, 1, "");
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature(
            "ERC1155InsufficientBalance(address,uint256,uint256,uint256)",
            user1,
            1,
            2,
            0
        ));
        lnft.safeTransferFrom(user1, user2, 0, 2, "");
    }
}
