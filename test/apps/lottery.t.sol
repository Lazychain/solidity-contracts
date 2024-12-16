// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";
import { StdAssertions } from "forge-std/StdAssertions.sol";

import { LazyNFT } from "../../contracts/apps/nft.sol";
import { NFTLottery } from "../../contracts/apps/lottery.sol";
import { IFairyringContract } from "../../contracts/apps/Ifairyring.sol";

contract Handler is StdAssertions, StdUtils {
    NFTLottery private _lottery;
    address private _fundedUser;

    constructor(address lottery, address fundedUser) {
        _lottery = NFTLottery(lottery);
        _fundedUser = fundedUser;
    }

    function version() public virtual {
        _lottery.setCampaign(true);
    }
}

contract LotteryTest is Test {
    LazyNFT private _nft;
    NFTLottery private _lottery;
    LazyNFT[] private _collections;
    address[] private _nftList;
    IFairyringContract private _fairyringContract;
    Handler private _handler;
    address private _fundedUser;
    address private _noFundedUser;

    // Events
    event RewardWithdrawn(address by, uint256 amount);
    event CampaignStatusChanged(bool status);

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    uint256 private _fee = 1 ether;

    function setUp() public {
        uint8 quantity = 1;

        // Setup
        _fundedUser = makeAddr("funded_user");
        deal(address(_fundedUser), 100 ether);
        _noFundedUser = makeAddr("no_funded_user");

        // NFT Contructors and Minting
        for (uint256 i = 0; i < 4; ++i) {
            // Construct NFT contract
            LazyNFT nft = new LazyNFT("LazyNFT", "LNT", quantity, "ipfs://hash/");

            // Mint Tokens
            nft.mint(quantity);
            assertEq(quantity, nft.totalSupply());

            // Add to list
            _collections.push(nft);
            _nftList.push(address(nft));
            quantity *= 2;
        }

        // Random mock
        _fairyringContract = IFairyringContract(address(0));

        // the owner is LotteryTest
        // Construct Lottery
        _lottery = new NFTLottery(address(_fairyringContract), _fee, address(_fairyringContract), _nftList);

        // Set approval for all NFTs to Loterry as `Operator`
        for (uint256 i = 0; i < 4; ++i) {
            _collections[i].setApprovalForAll(address(_lottery), true);
            bool isApproved = _collections[i].isApprovedForAll(address(this), address(_lottery));
            assertEq(true, isApproved);

            // transfer ownership of all NFT tokens to lottery contract
            uint256 totalSupply = _collections[i].totalSupply();
            for (uint256 tokenId = 0; tokenId < totalSupply; ++tokenId) {
                _collections[i].transferFrom(address(this), address(_lottery), tokenId);
            }
            assertEq(totalSupply, _collections[i].balanceOf(address(_lottery)));
        }

        _handler = new Handler(address(_lottery), _fundedUser);
        targetContract(address(_handler));
        //emit log_string("setup OK.");
    }

    function testFail_Draw_Guess(uint8 guess) public {
        vm.assume(guess >= 100);
        // Given a started lottery campaign
        vm.expectEmit(true, true, false, true);
        emit CampaignStatusChanged(true);
        _lottery.setCampaign(true);

        // and a user
        vm.startPrank(address(_noFundedUser));

        // with enough fee ether to pay a draw()
        deal(address(_noFundedUser), _fee);

        // and calling draw() with a guess number greater then 100
        _lottery.draw{ value: _fee }(guess);
        vm.stopPrank();
    }

    /// forge-config: default.fuzz.show-logs = true
    /// forge-config: default.invariant.fail-on-revert = true
    /// forge-config: default.fuzz.runs = 300
    function testFuzz_Draw_Withdraw(uint8 guess) public {
        vm.assume(guess >= 0);
        vm.assume(guess < 100);
        uint256 preBalance = address(this).balance;

        // Given a started lottery campaign
        vm.expectEmit(true, true, false, true);
        emit CampaignStatusChanged(true);
        _lottery.setCampaign(true);

        // and a user
        vm.startPrank(address(_noFundedUser));

        // with enough fee ether to pay a draw()
        deal(address(_noFundedUser), _fee);

        // and a mocked randomness function
        // to return always guess
        vm.mockCall(
            address(_fairyringContract),
            abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
            abi.encode(bytes32(0), uint256(guess))
        );
        // and calling draw()
        _lottery.draw{ value: _fee }(guess);
        vm.stopPrank();

        // When an owner withdraw
        vm.startPrank(address(this));
        vm.expectEmit(true, true, false, true);
        emit RewardWithdrawn(address(this), _fee);

        _lottery.withdraw();
        vm.stopPrank();

        // and owner balance should increase by amount
        uint256 postBalance = address(this).balance;
        assertEq(preBalance + _fee, postBalance);
    }

    /// forge-config: default.fuzz.show-logs = true
    /// forge-config: default.invariant.fail-on-revert = true
    /// forge-config: default.fuzz.runs = 300
    function testFuzz_Draw_Always_Win(uint8 guess) public {
        vm.assume(guess >= 0);
        vm.assume(guess < 100);
        uint256 preBalance = address(this).balance;

        // Given a started lottery campaign
        vm.expectEmit(true, true, false, true);
        emit CampaignStatusChanged(true);
        _lottery.setCampaign(true);

        // and a well funded user
        vm.startPrank(address(_fundedUser));

        // and a mocked randomness function
        // to return always guess

        vm.mockCall(
            address(_fairyringContract),
            abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
            abi.encode(bytes32(0), uint256(guess))
        );

        // and calling draw()
        _lottery.draw{ value: _fee }(guess);
        vm.stopPrank();

        // When an owner withdraw
        vm.startPrank(address(this));
        vm.expectEmit(true, true, false, true);
        emit RewardWithdrawn(address(this), _fee);

        _lottery.withdraw();
        vm.stopPrank();

        // and owner balance should increase by amount
        uint256 postBalance = address(this).balance;
        assertEq(preBalance + _fee, postBalance);
    }

    /// forge-config: default.fuzz.show-logs = true
    /// forge-config: default.invariant.fail-on-revert = true
    /// forge-config: default.fuzz.runs = 300
    function testFuzz_Draw_Always_Loose(uint8 guess) public {
        vm.assume(guess >= 0);
        vm.assume(guess < 100);
        uint256 preBalance = address(this).balance;

        // Given a started lottery campaign
        vm.expectEmit(true, true, false, true);
        emit CampaignStatusChanged(true);
        _lottery.setCampaign(true);

        // and a well funded user
        vm.startPrank(address(_fundedUser));

        // and a mocked randomness function
        // to return always guess

        uint256 random = (guess + 1) % 100;

        vm.mockCall(
            address(_fairyringContract),
            abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
            abi.encode(bytes32(0), uint256(random))
        );

        // and calling draw()
        _lottery.draw{ value: _fee }(guess);
        vm.stopPrank();

        // When an owner withdraw
        vm.startPrank(address(this));
        vm.expectEmit(true, true, false, true);
        emit RewardWithdrawn(address(this), _fee);

        _lottery.withdraw();
        vm.stopPrank();

        // and owner balance should increase by amount
        uint256 postBalance = address(this).balance;
        assertEq(preBalance + _fee, postBalance);
    }

    // Too complex to make a usefull invariant test case
    // function invariant_Version() external view {
    //     assertEq(_lottery.version(), "1.00");
    // }
}
