// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "hardhat/console.sol";
import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Lazy721 } from "../../../contracts/apps/lazy721.sol";
import { Lazy1155 } from "../../../contracts/apps/lazy1155.sol";
import { NFTLottery } from "../../../contracts/apps/lottery.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { IFairyringContract } from "../../../lib/FairyringContract/src/IFairyringContract.sol";
import { NFTLotteryFactory, NFTLotteryProxy } from "../../../contracts/apps/factory/lotteryFactory.sol";

contract MockNonStandardNFT {
    function transferFrom(address, address, uint256) external pure {}
}

contract NFTLotteryFactoryTest is StdCheats, Test, ERC1155Holder {
    NFTLotteryFactory private _factory;
    Lazy721 private _nft721;
    Lazy1155 private _nft1155;
    MockNonStandardNFT private _nonStandardNFT;
    IFairyringContract private _fairyringContract;

    uint256 private constant _FEE = 1 ether;

    function setUp() public {
        _factory = new NFTLotteryFactory();
        _fairyringContract = IFairyringContract(address(0));

        // Deploy standard NFT contracts
        _nft721 = new Lazy721("Lazy721", "LAZY721", 1, "ipfs://lazyhash/");
        _nft1155 = new Lazy1155(1, "ipfs://hash/{id}.json");
        _nonStandardNFT = new MockNonStandardNFT();
    }

    // Test creating a lottery with ERC721
    function test_CreateLottery_ERC721() public {
        NFTLottery lottery = _factory.createLottery(address(_nft721), _FEE, address(_fairyringContract));

        assertEq(
            uint256(_factory.lotteryTypes(address(lottery))),
            uint256(NFTLotteryFactory.NFTStandards.ERC721),
            "Lottery type should be ERC721"
        );
    }

    // Test creating a lottery with ERC1155
    function test_CreateLottery_ERC1155() public {
        NFTLottery lottery = _factory.createLottery(address(_nft1155), _FEE, address(_fairyringContract));

        assertEq(
            uint256(_factory.lotteryTypes(address(lottery))),
            uint256(NFTLotteryFactory.NFTStandards.ERC1155),
            "Lottery type should be ERC1155"
        );
    }

    // Test creating a lottery with unsupported NFT standard
    function test_CreateLottery_UnsupportedNFTStandards() public {
        vm.expectRevert(NFTLotteryFactory.NFTLotteryFactory__UnsupportedNFTStandards.selector);
        _factory.createLottery(address(_nonStandardNFT), _FEE, address(_fairyringContract));
    }

    // Test LotteryCreated event is emitted
    function test_CreateLottery_EmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit NFTLotteryFactory.LotteryCreated(address(0), NFTLotteryFactory.NFTStandards.ERC721);

        _factory.createLottery(address(_nft721), _FEE, address(_fairyringContract));
    }

    // NFTLotteryProxy tests
    function test_NFTLotteryProxy_Deployment() public {
        // Direct deployment of proxy to test its constructor and functions
        NFTLotteryProxy proxy = new NFTLotteryProxy(address(_nft1155), _FEE, address(_fairyringContract));

        NFTLottery lottery = proxy.getLottery();
        assertTrue(address(lottery) != address(0), "Lottery should be deployed");
    }

    // Test fallback mechanism of NFTLotteryProxy
    function test_NFTLotteryProxy_Fallback() public {
        NFTLotteryProxy proxy = new NFTLotteryProxy(address(_nft1155), _FEE, address(_fairyringContract));

        // Simulate a call to the implementation contract via proxy
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("owner()"));
        assertTrue(success, "Fallback should delegate call successfully");
    }

    // Test receive function
    function test_NFTLotteryProxy_ReceiveEther() public {
        NFTLotteryProxy proxy = new NFTLotteryProxy(address(_nft1155), _FEE, address(_fairyringContract));

        // Send some ether to the proxy
        vm.deal(address(this), 10 ether);
        (bool success, ) = address(proxy).call{ value: 1 ether }("");
        assertTrue(success, "Should be able to receive ether");
    }

    // Edge case: Zero address handling
    function test_CreateLottery_ZeroAddressHandling() public {
        vm.expectRevert(); // Expect a revert, though the exact error depends on implementation
        _factory.createLottery(address(0), _FEE, address(_fairyringContract));
    }

    // Fuzz testing for fee variation
    function testFuzz_CreateLottery_DifferentFees(uint256 fee) public {
        vm.assume(fee > 0 && fee < type(uint256).max);

        NFTLottery lottery = _factory.createLottery(address(_nft721), fee, address(_fairyringContract));

        assertTrue(address(lottery) != address(0), "Lottery should be created with varying fees");
    }

    // Ensure unique lottery creation for different contracts
    function test_CreateLottery_UniqueAddresses() public {
        NFTLottery lottery1 = _factory.createLottery(address(_nft721), _FEE, address(_fairyringContract));

        NFTLottery lottery2 = _factory.createLottery(address(_nft1155), _FEE, address(_fairyringContract));

        assertTrue(address(lottery1) != address(lottery2), "Lotteries should have unique addresses");
    }
}
