// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StdUtils } from "forge-std/StdUtils.sol";
import { StdAssertions } from "forge-std/StdAssertions.sol";

// import { Lazy721A } from "../../contracts/apps/lazy721a.sol";
// import { Lazy721 } from "../../contracts/apps/lazy721.sol";
import { Lazy1155 } from "../../contracts/apps/lazy1155.sol";
import { NFTLottery } from "../../contracts/apps/lottery.sol";
import { IFairyringContract } from "../../lib/FairyringContract/src/IFairyringContract.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { console } from "forge-std/console.sol";

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
    Lazy1155 private _nft1155;

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
    uint256 private _tokensIdCap = 4;

    function setUp() public {
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
        uint256[] memory ids = new uint256[](_tokensIdCap);
        uint256[] memory amounts = new uint256[](_tokensIdCap);
        uint256 totalEmittion = 0;

        uint256 quantity = 1;
        for (uint256 tokenId = 0; tokenId < _tokensIdCap; tokenId++) {
            ids[tokenId] = tokenId;
            amounts[tokenId] = quantity;
            totalEmittion += quantity;
            quantity *= 2;
        }

        //console.log(totalEmittion);
        // Construct NFT contract
        _nft1155 = new Lazy1155(totalEmittion, "ipfs://hash/{id}.json"); // we want to test mint, so =0
        // Mint Tokens
        _nft1155.mintBatch(address(this), ids, amounts, "");
        assertEq(15, _nft1155.totalSupply());

        // Random mock
        _fairyringContract = IFairyringContract(address(0));

        // the owner is LotteryTest
        // Construct Lottery
        _lottery = new NFTLottery(address(_nft1155), _fee, address(_fairyringContract));

        // Set approval for all NFTs to Loterry as `Operator`
        _nft1155.setApprovalForAll(address(_lottery), true);
        bool isApproved = _nft1155.isApprovedForAll(address(this), address(_lottery));
        assertEq(true, isApproved);

        // transfer ownership of all NFT tokens to lottery contract
        uint256 totalSupply = _nft1155.totalSupply();
        uint256 totalBalance = 0;

        _nft1155.safeBatchTransferFrom(address(this), address(_lottery), ids, amounts, "");
        for (uint256 tokenId = 0; tokenId < _tokensIdCap; tokenId++) {
            totalBalance += _nft1155.balanceOf(address(_lottery), tokenId);
        }
        assertEq(totalSupply, totalBalance);

        // handler for future use in invariant testing.
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

        // with enough fee ether to pay a draw()
        deal(address(_noFundedUser), _fee);

        // and a mocked randomness function
        // to return always guess
        vm.mockCall(
            address(_fairyringContract),
            abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
            abi.encode(bytes32(0), uint256(guess))
        );

        // and a user
        vm.startPrank(address(_noFundedUser));
        // and calling draw()
        _lottery.draw{ value: _fee }(guess);
        vm.stopPrank();

        // When an owner withdraw
        vm.startPrank(address(this));
        vm.expectEmit(true, true, false, true);
        emit RewardWithdrawn(address(this), _fee);

        _lottery.withdraw(address(this));
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

        _lottery.withdraw(address(this));
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

        _lottery.withdraw(address(this));
        vm.stopPrank();

        // and owner balance should increase by amount
        uint256 postBalance = address(this).balance;
        assertEq(preBalance + _fee, postBalance);
    }

    // Too complex to make a usefull invariant test case
    // function invariant_Version() external view {
    //     assertEq(_lottery.version(), "1.00");
    // }

    function testFail_DrawWhenCampaignNotOpen() public {
        // Given campaign is not started
        assertEq(_lottery.campaign(), false);
        
        // When user tries to draw
        vm.startPrank(_fundedUser);
        _lottery.draw{value: _fee}(50);
        vm.stopPrank();
    }

    function testFail_DrawWithInsufficientFee() public {
        // Given campaign is open
        vm.expectEmit(true, true, false, true);
        emit CampaignStatusChanged(true);
        _lottery.setCampaign(true);
        
        // When user tries to draw with insufficient fee
        vm.startPrank(_fundedUser);
        _lottery.draw{value: _fee / 2}(50);
        vm.stopPrank();
    }

    function testFail_WithdrawByNonOwner() public {
        // Given some balance in contract
        vm.deal(address(_lottery), 1 ether);
        
        // When non-owner tries to withdraw
        vm.startPrank(_fundedUser);
        _lottery.withdraw(_fundedUser);
        vm.stopPrank();
    }

    function testClaimNFTWithInsufficientPoints() public {
        // Given campaign is open
        _lottery.setCampaign(true);
        
        // When user tries to claim with insufficient points
        vm.startPrank(_fundedUser);
        vm.expectRevert(NFTLottery.NFTLottery__TooFewPooPoints.selector);
        _lottery.claimNFT{value: _fee}();
        vm.stopPrank();
    }

 function testFuzz_NFTDistributionOrder(uint8[] calldata guesses) public {
    vm.assume(guesses.length > 0);
    vm.assume(guesses.length <= 5); // Reasonable limit for gas
    
    // Given campaign is open
    _lottery.setCampaign(true);
    
    // Track initial NFT balances
    uint256[] memory initialBalances = new uint256[](_tokensIdCap);
    for(uint256 i = 0; i < _tokensIdCap; i++) {
        initialBalances[i] = _nft1155.balanceOf(address(_lottery), i);
    }
    
    // When winners claim NFTs
    vm.startPrank(_fundedUser);
    for(uint i = 0; i < guesses.length; i++) {
        uint8 normalizedGuess = guesses[i] % 100; // Use modulo instead of skipping
        
        // Mock winning condition
        vm.mockCall(
            address(_fairyringContract),
            abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
            abi.encode(bytes32(0), uint256(normalizedGuess))
        );
        
        try _lottery.draw{value: _fee}(normalizedGuess) returns (uint256 tokenId) {
            // Check NFT balances changed appropriately
            for(uint256 j = 0; j < _tokensIdCap; j++) {
                uint256 newBalance = _nft1155.balanceOf(address(_lottery), j);
                assertLe(newBalance, initialBalances[j]);
            }
        } catch Error(string memory reason) {
            // Check if it's our expected error message
            if (!_compareStrings(reason, "No more NFTs")) {
                revert(reason);
            }
        }
        
        vm.roll(block.number + 1);
    }
    vm.stopPrank();
}

// Helper function to compare strings
function _compareStrings(string memory a, string memory b) private pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
}
    
    function testFuzz_MultipleDrawsSameBlock(uint8 guess) public {
        vm.assume(guess < 100);
        
        // Given campaign is open
        _lottery.setCampaign(true);
        
        // Mock random number to ensure loss (avoid NFT transfer complications)
        vm.mockCall(
            address(_fairyringContract),
            abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
            abi.encode(bytes32(0), uint256((guess + 10) % 100))
        );
        
        // And user has enough funds for multiple draws
        vm.deal(_fundedUser, _fee * 3);
        
        // When user draws multiple times in same block
        vm.startPrank(_fundedUser);
        uint256 initialDraws = _lottery.totaldraws();
        
        _lottery.draw{value: _fee}(guess);
        _lottery.draw{value: _fee}(guess);
        _lottery.draw{value: _fee}(guess);
        
        // Then all draws should be counted
        assertEq(_lottery.totaldraws(), initialDraws + 3);
        vm.stopPrank();
    }

  function testFuzz_PooPointsAccumulation(uint8[] calldata guesses) public {
    vm.assume(guesses.length > 0);
    vm.assume(guesses.length <= 5); // Reduced from 10 to avoid gas issues
    
    // Given campaign is open
    _lottery.setCampaign(true);
    
    // Mock random number to ensure loss using tokensCap+1
    vm.mockCall(
        address(_fairyringContract),
        abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
        abi.encode(bytes32(0), uint256(99))
    );
    
    // Ensure user has enough funds for all draws
    vm.deal(_fundedUser, _fee * guesses.length);
    
    // And user starts with 0 points
    vm.prank(_fundedUser);
    uint256 initialPoints = _lottery.points();
    assertEq(initialPoints, 0);
    
    // When user makes multiple draws
    vm.startPrank(_fundedUser);
    uint256 successfulDraws = 0;
    
    for(uint i = 0; i < guesses.length; i++) {
        uint8 normalizedGuess = guesses[i] % 100;
        try _lottery.draw{value: _fee}(normalizedGuess) returns (uint256) {
            successfulDraws++;
        } catch Error(string memory reason) {
            // Check if it's our expected error message
            if (!_compareStrings(reason, "No more NFTs")) {
                revert(reason);
            }
        }
        // Increment block number to allow multiple draws
        vm.roll(block.number + 1);
    }
    
    // Then points should accumulate correctly (1 point per draw attempt, regardless of win/loss)
    assertEq(_lottery.points(), initialPoints + successfulDraws);
    vm.stopPrank();
}

    function testFuzz_AccumulateAndClaimNFT(uint8 drawCount) public {
        vm.assume(drawCount >= 100); // Need at least 100 draws for claiming
        vm.assume(drawCount <= 150); // Upper limit for gas
        
        // Given campaign is open
        _lottery.setCampaign(true);
        
        // Ensure user has enough funds for all draws
        vm.deal(_fundedUser, _fee * (drawCount + 1)); // +1 for the claim fee
        
        // Mock random number to ensure loss (avoid NFT depletion)
        vm.mockCall(
            address(_fairyringContract),
            abi.encodeWithSelector(IFairyringContract.latestRandomness.selector),
            abi.encode(bytes32(0), uint256(99)) // Always return 99 to ensure loss
        );
        
        // When user accumulates points through draws
        vm.startPrank(_fundedUser);
        for(uint i = 0; i < drawCount; i++) {
            _lottery.draw{value: _fee}(50);
            vm.roll(block.number + 1);
        }
        
        // Then user should be able to claim NFT with enough points
        uint256 points = _lottery.points();
        if(points >= 100) {
            uint256 tokenId = _lottery.claimNFT{value: _fee}();
            assertLt(tokenId, _tokensIdCap);
            assertEq(_nft1155.balanceOf(_fundedUser, tokenId), 1);
        }
        vm.stopPrank();
    }

}
