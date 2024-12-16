// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Lazy1155 } from "../../contracts/apps/lazy1155.sol";
// https://book.getfoundry.sh/reference/config/inline-test-config
// https://github.com/patrickd-/solidity-fuzzing-boilerplate

contract Lazy721Test is StdCheats, Test {
    Lazy1155 private _nft;

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    function setUp() public {
        _nft = new Lazy1155(4, "ipfs/lazyhash/{id}.json", 4);
    }

    /// forge-config: default.fuzz.runs = 300
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
}
