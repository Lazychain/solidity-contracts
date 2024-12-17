// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Lazy721 } from "../../contracts/apps/lazy721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// https://book.getfoundry.sh/reference/config/inline-test-config
// https://github.com/patrickd-/solidity-fuzzing-boilerplate

contract Lazy721Test is StdCheats, Test, ERC721Holder {
    Lazy721 private _nft;

    function setUp() public {
        _nft = new Lazy721("LazyNFT", "LNT", 4);
    }

    /// forge-config: default.fuzz.show-logs = true
    /// forge-config: default.invariant.fail-on-revert = true
    function testFuzz_Mint(string memory name) public {
        Lazy721 newNft = new Lazy721(name, "LNT", 4);
        assertEq(newNft.name(), name);
    }

    /// forge-config: default.fuzz.runs = 300
    function testFuzz_Mint(uint16 quantity, string memory uri) public {
        vm.assume(quantity > 0);
        Lazy721 newNft = new Lazy721("LazyNFT", "LNT", quantity);
        assertEq(newNft.totalSupply(), 0);
        for (uint256 i = 0; i < quantity; ++i) {
            // LazyNFTTest is the owner
            newNft.safeMint(address(this), uri);
        }
        assertEq(newNft.totalSupply(), quantity);
    }
}
