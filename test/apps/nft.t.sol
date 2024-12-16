// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { LazyNFT } from "../../contracts/apps/nft.sol";
// https://book.getfoundry.sh/reference/config/inline-test-config
// https://github.com/patrickd-/solidity-fuzzing-boilerplate

contract LazyNFTTest is StdCheats, Test {
    LazyNFT private _nft;

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    function setUp() public {
        _nft = new LazyNFT("LazyNFT", "LNT", 1, "ipfs://hash/");
    }

    /// forge-config: default.fuzz.show-logs = true
    /// forge-config: default.invariant.fail-on-revert = true
    function testFuzz_Mint(string memory name) public {
        LazyNFT newNft = new LazyNFT(name, "LNT", 1, "ipfs://hash/");
        assertEq(newNft.name(), name);
    }

    /// forge-config: default.fuzz.runs = 300
    function testFuzz_Mint(uint16 quantity) public {
        vm.assume(quantity > 0);
        LazyNFT newNft = new LazyNFT("LazyNFT", "LNT", quantity, "ipfs://hash/");
        assertEq(newNft.totalSupply(), 0);

        newNft.mint(quantity);
        assertEq(newNft.totalSupply(), quantity);
    }
}
