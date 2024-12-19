// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdUtils } from "forge-std/StdUtils.sol";
import { StdAssertions } from "forge-std/StdAssertions.sol";

// import { Lazy721A } from "../../contracts/apps/lazy721a.sol";
// import { Lazy721 } from "../../contracts/apps/lazy721.sol";
import { Lazy1155 } from "../../contracts/apps/lazy1155.sol";
import { NFTLottery } from "../../contracts/apps/lottery.sol";
import { IFairyringContract } from "../../contracts/apps/Ifairyring.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
// import { console } from "forge-std/console.sol";

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

// TODO: Make an abstract class, a factory and interface for lottery to accept differents `types` of ERC (721,721A,1155)
// https://betterprogramming.pub/learn-solidity-the-factory-pattern-75d11c3e7d29
contract LotteryTest is Test, ERC1155Holder {
    NFTLottery private _lottery;
    // // test for 721A
    // Lazy721A[] private _collections721A;
    // address[] private _nftList721A;

    // // test for 721
    // Lazy721[] private _collections721;
    // address[] private _nftList721;

    // test for 1155
    Lazy1155[] private _collections1155;
    address[] private _nftList1155;

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
        uint8 tokenCap = 1;

        // Setup
        _fundedUser = makeAddr("funded_user");
        deal(address(_fundedUser), 100 ether);
        _noFundedUser = makeAddr("no_funded_user");

        // // NFT Contructors and Minting 721A
        // for (uint256 i = 0; i < 4; ++i) {
        //     // Construct NFT contract
        //     Lazy721A nft = new Lazy721A("LazyNFT", "LNT", tokenCap, "ipfs://hash/");

        //     // Mint Tokens
        //     nft.mint(tokenCap);
        //     assertEq(tokenCap, nft.totalSupply());

        //     // Add to list
        //     _collections721A.push(nft);
        //     _nftList721A.push(address(nft));
        //     tokenCap *= 2;
        // }

        // // NFT Contructors and Minting 721
        // for (uint256 i = 0; i < 4; ++i) {
        //     // Construct NFT contract
        //     Lazy721 nft = new Lazy721("LazyNFT", "LNT", tokenCap);

        //     // Mint Tokens
        //     for (uint256 n = 0; n < tokenCap; ++n) {
        //         nft.safeMint(address(this), "ipfs://hash/");
        //         assertEq(tokenCap, nft.totalSupply());
        //     }

        //     // Add to list
        //     _collections721.push(nft);
        //     _nftList721.push(address(nft));
        //     tokenCap *= 2;
        // }

        // NFT Contructors and Minting 1155
        for (uint256 i = 0; i < 4; ++i) {
            // Construct NFT contract
            Lazy1155 nft = new Lazy1155(tokenCap, "ipfs://hash/{id}.json", 0); // we want to test mint, so =0

            // Mint Tokens
            uint256[] memory ids = new uint256[](tokenCap);
            uint256[] memory amounts = new uint256[](tokenCap);

            for (uint256 n = 0; n < tokenCap; ++n) {
                ids[n] = n;
                amounts[n] = 1;
            }
            nft.mintBatch(address(this), ids, amounts, "");
            assertEq(tokenCap, nft.totalSupply());

            // Add to list
            _collections1155.push(nft);
            _nftList1155.push(address(nft));
            tokenCap *= 2;
        }

        // Random mock
        _fairyringContract = IFairyringContract(address(0));

        // the owner is LotteryTest
        // Construct Lottery
        _lottery = new NFTLottery(_nftList1155, _fee, address(_fairyringContract), address(_fairyringContract));

        // Set approval for all NFTs to Loterry as `Operator`
        for (uint256 i = 0; i < 4; ++i) {
            _collections1155[i].setApprovalForAll(address(_lottery), true);
            bool isApproved = _collections1155[i].isApprovedForAll(address(this), address(_lottery));
            assertEq(true, isApproved);

            // transfer ownership of all NFT tokens to lottery contract
            uint256 totalSupply = _collections1155[i].totalSupply();
            uint256 totalBalance = 0;
            for (uint256 tokenId = 0; tokenId < totalSupply; ++tokenId) {
                _collections1155[i].safeTransferFrom(address(this), address(_lottery), tokenId, 1, "");
                uint256 balance = _collections1155[i].balanceOf(address(_lottery), tokenId);
                assertEq(1, balance);
                totalBalance += balance;
            }
            assertEq(totalSupply, totalBalance);
        }

        _handler = new Handler(address(_lottery), _fundedUser);
        targetContract(address(_handler));
        // emit log_string("setup OK.");
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
