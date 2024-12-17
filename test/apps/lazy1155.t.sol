// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Lazy1155 } from "../../contracts/apps/lazy1155.sol";
// https://book.getfoundry.sh/reference/config/inline-test-config
// https://github.com/patrickd-/solidity-fuzzing-boilerplate
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
// import { console } from "forge-std/console.sol";

contract Lazy1155Test is StdCheats, Test, ERC1155Holder {
    /// forge-config: default.fuzz.runs = 10
    function testFuzz_Mint(uint16 quantity) public {
        vm.assume(quantity > 0);
        Lazy1155 newNft = new Lazy1155(quantity, "ipfs/lazyhash/{id}.json", 0);
        assertEq(newNft.totalSupply(), 0);
        for (uint256 i = 0; i < quantity; ++i) {
            // LazyNFTTest is the owner
            newNft.mint(address(this), i, 1, "");
        }
        assertEq(newNft.totalSupply(), quantity);
    }

    /// forge-config: default.fuzz.runs = 10
    function testFuzz_BatchMint(uint16 tokenCap) public {
        uint8 maxIds = 10;
        // Ensure that at least 1 quantity token can be mint for that id
        vm.assume(tokenCap > maxIds);
        vm.assume(tokenCap < maxIds * 2);

        // Given a 1155 contract with zero initial minted tokens
        Lazy1155 newNft = new Lazy1155(tokenCap, "ipfs/lazyhash/{id}.json", 0);
        assertEq(newNft.totalSupply(), 0);

        uint256 quantity = tokenCap / maxIds;

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
}
