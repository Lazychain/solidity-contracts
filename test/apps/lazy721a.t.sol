// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Lazy721A } from "../../contracts/apps/lazy721a.sol";
// https://book.getfoundry.sh/reference/config/inline-test-config
// https://github.com/patrickd-/solidity-fuzzing-boilerplate

contract Lazy721ATest is StdCheats, Test {
    Lazy721A private _nft;

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    function setUp() public {
        _nft = new Lazy721A("LazyNFT", "LNT", 4, "ipfs://lazyhash");
    }

    /// forge-config: default.fuzz.show-logs = true
    /// forge-config: default.invariant.fail-on-revert = true
    function testFuzz_Mint(string memory name) public {
        Lazy721A newNft = new Lazy721A(name, "LNT", 4, "ipfs://lazyhash");
        assertEq(newNft.name(), name);
    }

    /// forge-config: default.fuzz.runs = 300
    function testFuzz_Mint(uint16 quantity, string memory uri) public {
        vm.assume(quantity > 0);
        Lazy721A newNft = new Lazy721A("LazyNFT", "LNT", quantity, uri);
        assertEq(newNft.totalSupply(), 0);
        // LazyNFTTest is the owner
        newNft.mint(quantity);
        assertEq(newNft.totalSupply(), quantity);
    }
}
