// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { NFTLottery } from "../../../contracts/apps/lottery.sol";
import { NFTLotteryFactory } from "../../../contracts/apps/factory/lotteryFactory.sol";
import { Lazy721 } from "../../../contracts/apps/lazy721.sol";
import { Lazy1155 } from "../../../contracts/apps/lazy1155.sol";
import { IFairyringContract } from "../../../contracts/apps/Ifairyring.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "hardhat/console.sol";

contract LotteryFactoryTest is StdCheats, Test, ERC1155Holder {
    NFTLotteryFactory private _factory;
    NFTLottery private _lottery1155;
    NFTLottery private _lottery721;

    Lazy721 private _nft721;
    Lazy1155 private _nft1155;

    IFairyringContract private _fairyringContract;
    uint256 private _fee = 1 ether;
    address private _fundedUser;
    address private _noFundedUser;

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    // Events
    event RewardWithdrawn(address by, uint256 amount);
    event CampaignStatusChanged(bool status);

    function setUp() public {
        uint256 tokenId = 0;
        uint256 amount = 1;
        // Setup
        _fundedUser = makeAddr("funded_user");
        deal(address(_fundedUser), 100 ether);
        _noFundedUser = makeAddr("no_funded_user");

        // tokenCap = 1
        _nft1155 = new Lazy1155(amount, "ipfs://hash/{id}.json"); // we want to test mint, so =0
        _nft721 = new Lazy721("Lazy NFT", "LAZY", amount, "ipfs://lazyhash/");

        // Random mock
        _fairyringContract = IFairyringContract(address(0));

        emit log_string("Start.");
        // NFTLotteryFactory owned all NFTLotteries deployed by it.
        _factory = new NFTLotteryFactory();

        console.log("Setup Lottery NFT 1155");
        // Setup Lottery NFT 1155
        _lottery1155 = _factory.createLottery(
            address(_nft1155),
            _fee,
            address(_fairyringContract),
            address(_fairyringContract)
        );

        console.log("minting");
        // LotteryFactoryTest owns _nft1155
        _nft1155.mint(address(this), tokenId, amount, "0x");
        // Set approval for nft lottery instance
        _nft1155.setApprovalForAll(address(_lottery1155), true);
        assertEq(true, _nft1155.isApprovedForAll(address(this), address(_lottery1155)));
        // Transfer all NFTs ownership to lottery instance
        _nft1155.safeTransferFrom(address(this), address(_lottery1155), tokenId, amount, "");
        assertEq(_nft1155.balanceOf(address(_lottery1155), tokenId), _nft1155.totalSupply());

        emit log_string("1155 OK.");
        // TODO: For now, Lottery only support ERC1155 since requeriments changed last week.
        // _lottery721 = _factory.createLottery(
        //     address(_nft721),
        //     _fee,
        //     address(_fairyringContract),
        //     address(_fairyringContract)
        // );

        // // LotteryFactoryTest owns _nft721
        // _nft721.safeMint(address(_lottery721));
        // assertEq(_nft721.balanceOf(address(_lottery721)), _nft721.totalSupply());
        // emit log_string("721 OK.");
    }

    /// forge-config: default.fuzz.show-logs = true
    /// forge-config: default.invariant.fail-on-revert = true
    /// forge-config: default.fuzz.runs = 300
    function testFuzz_Draw_Always_Win_lottery_1155(uint8 guess) public {
        vm.assume(guess >= 0);
        vm.assume(guess < 100);
        uint256 preBalance = address(this).balance;

        // // Given a started lottery campaign
        // vm.expectEmit(true, true, false, true);
        // emit CampaignStatusChanged(true);
        // _lottery1155.setCampaign(true);

        // // and a well funded user
        // vm.startPrank(address(_fundedUser));

        // // and a mocked randomness function
        // // to return always guess

        // vm.mockCall(
        //     address(_fairyringContract),
        //     abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
        //     abi.encode(bytes32(0), uint256(guess))
        // );

        // // and calling draw()
        // _lottery1155.draw{ value: _fee }(guess);
        // vm.stopPrank();

        // // When an owner withdraw
        // vm.startPrank(address(this));
        // vm.expectEmit(true, true, false, true);
        // emit RewardWithdrawn(address(this), _fee);

        // _lottery1155.withdraw();
        // vm.stopPrank();

        // // and owner balance should increase by amount
        // uint256 postBalance = address(this).balance;
        // assertEq(preBalance + _fee, postBalance);
    }
}
