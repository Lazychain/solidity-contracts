// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { Lazy721 } from "../../../contracts/apps/lazy721.sol";
import { Lazy721A } from "../../../contracts/apps/lazy721a.sol";
import { Lazy1155 } from "../../../contracts/apps/lazy1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { NFTStaking } from "../../../contracts/apps/staker/stake.sol";

contract NFTStakingTest is Test {
    NFTStaking public staking;
    Lazy721 public lazy721;
    Lazy721A public lazy721a;
    Lazy1155 public lazy1155;

    address public owner;
    address public alice;
    address public bob;

    uint256 public constant INITIAL_STAKING_PERIOD = 100; // blocks
    uint256 public constant STAKING_FEE = 0.1 ether;
    uint256 public constant UNSTAKING_FEE = 0.05 ether;
    uint256 public constant REWARD_RATE = 0.0001 ether;
    uint256 public constant MAX_STAKES = 5;

    // Token constants
    uint256 public constant TOKEN_CAP_721 = 10000;
    uint16 public constant TOKEN_CAP_721A = 10000;
    uint256 public constant TOTAL_EMISSION_1155 = 100000;
    string public constant BASE_URI = "https://api.example.com/metadata/";

    event Staked(address indexed staker, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);
    event UnStaked(address indexed staker, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy contracts
        staking = new NFTStaking(INITIAL_STAKING_PERIOD, STAKING_FEE, UNSTAKING_FEE, REWARD_RATE, MAX_STAKES);

        // Deploy NFT contracts with proper parameters
        lazy721 = new Lazy721("Test721", "TST721", TOKEN_CAP_721, BASE_URI);

        lazy721a = new Lazy721A("Test721A", "TST721A", TOKEN_CAP_721A, BASE_URI);

        lazy1155 = new Lazy1155(TOTAL_EMISSION_1155, BASE_URI);

        // Fund test accounts
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function test_Constructor() public view {
        assertEq(staking.stakingPeriodInBlocks(), INITIAL_STAKING_PERIOD);
        assertEq(staking.stakingFee(), STAKING_FEE);
        assertEq(staking.unstakingFee(), UNSTAKING_FEE);
        assertEq(staking.rewardRate(), REWARD_RATE);
        assertEq(staking.maxStakesPerUser(), MAX_STAKES);
    }

    function test_StakeERC721() public {
        // Mint NFT to Alice
        vm.prank(owner);
        lazy721.safeMint(alice);
        uint256 tokenId = 0; // First token ID

        // Approve staking contract
        vm.prank(alice);
        lazy721.approve(address(staking), tokenId);

        // Stake NFT
        vm.prank(alice);
        staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), tokenId);

        // Verify stake
        NFTStaking.StakeInfo[] memory aliceStakes = staking.getStakes(alice);
        assertEq(aliceStakes.length, 1);
        assertEq(aliceStakes[0].tokenAddress, address(lazy721));
        assertEq(aliceStakes[0].tokenId, tokenId);
        assertEq(aliceStakes[0].amount, 1);
        assertEq(aliceStakes[0].isERC1155, false);
        assertEq(uint256(aliceStakes[0].status), uint256(NFTStaking.StakingStatus.STAKED));
    }

    function test_StakeERC721A() public {
        // Mint NFT to Alice
        vm.prank(owner);
        lazy721a.safeMint(alice, 1); // Mint 1 token
        uint256 tokenId = 0; // First token ID

        // Approve staking contract
        vm.prank(alice);
        lazy721a.approve(address(staking), tokenId);

        // Stake NFT
        vm.prank(alice);
        staking.stakeERC721{ value: STAKING_FEE }(address(lazy721a), tokenId);

        // Verify stake
        NFTStaking.StakeInfo[] memory aliceStakes = staking.getStakes(alice);
        assertEq(aliceStakes.length, 1);
        assertEq(aliceStakes[0].tokenAddress, address(lazy721a));
        assertEq(aliceStakes[0].tokenId, tokenId);
        assertEq(aliceStakes[0].amount, 1);
        assertEq(aliceStakes[0].isERC1155, false);
    }

    function test_StakeERC1155() public {
        uint256 tokenId = 1;
        uint256 amount = 5;

        // Mint tokens to Alice
        vm.prank(owner);
        lazy1155.mint(alice, tokenId, amount, "");

        // Approve staking contract
        vm.prank(alice);
        lazy1155.setApprovalForAll(address(staking), true);

        // Stake tokens
        vm.prank(alice);
        staking.stakeERC1155{ value: STAKING_FEE }(address(lazy1155), tokenId, amount);

        // Verify stake
        NFTStaking.StakeInfo[] memory aliceStakes = staking.getStakes(alice);
        assertEq(aliceStakes.length, 1);
        assertEq(aliceStakes[0].tokenAddress, address(lazy1155));
        assertEq(aliceStakes[0].tokenId, tokenId);
        assertEq(aliceStakes[0].amount, amount);
        assertEq(aliceStakes[0].isERC1155, true);
    }

    function test_TokenCaps() public {
        // Test ERC721 cap
        vm.startPrank(owner);
        // First mint up to the cap
        for (uint256 i = 0; i < TOKEN_CAP_721; i++) {
            lazy721.safeMint(alice);
        }

        vm.expectRevert(Lazy721.Lazy721__TokenCapExceeded.selector);
        lazy721.safeMint(alice);
        vm.stopPrank();

        // Test ERC721A cap
        vm.prank(owner);
        vm.expectRevert(Lazy721A.Lazy721A__TokenCapExceeded.selector);
        lazy721a.safeMint(alice, TOKEN_CAP_721A + 1);

        // Test ERC1155 emission cap
        vm.prank(owner);
        vm.expectRevert(Lazy1155.Lazy1155__TokenCapExceeded.selector);
        lazy1155.mint(alice, 1, TOTAL_EMISSION_1155 + 1, "");
    }

    function test_TokenURIs() public {
        // Test ERC721 URI
        vm.prank(owner);
        lazy721.safeMint(alice);
        string memory uri721 = lazy721.tokenURI(0);
        assertEq(uri721, string(abi.encodePacked(BASE_URI, "0.json")));

        // Test ERC721A URI
        vm.prank(owner);
        lazy721a.safeMint(alice, 1);
        string memory uri721a = lazy721a.tokenURI(0);
        assertEq(uri721a, string(abi.encodePacked(BASE_URI, "0.json")));

        // Test ERC1155 URI
        vm.prank(owner);
        lazy1155.mint(alice, 1, 1, "");
        string memory uri1155 = lazy1155.uri(1);
        assertTrue(bytes(uri1155).length > 0);
    }

    function test_UnstakeERC721() public {
        // Setup: Stake an NFT first
        vm.prank(owner);
        lazy721.safeMint(alice);
        uint256 tokenId = 0;

        vm.startPrank(alice);
        lazy721.approve(address(staking), tokenId);
        staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), tokenId);
        vm.stopPrank();

        // Advance blocks to meet staking period
        vm.roll(block.number + INITIAL_STAKING_PERIOD + 1);

        // Unstake
        vm.prank(alice);
        staking.unStake{ value: UNSTAKING_FEE }(0);

        // Verify unstake
        assertEq(lazy721.ownerOf(tokenId), alice);
        NFTStaking.StakeInfo[] memory aliceStakes = staking.getStakes(alice);
        assertEq(uint256(aliceStakes[0].status), uint256(NFTStaking.StakingStatus.UNSTAKED));
    }

    function test_PauseAndUnpause() public {
        // Test ERC721
        vm.startPrank(owner);
        lazy721.pause();
        assertTrue(lazy721.paused());
        lazy721.unpause();
        assertFalse(lazy721.paused());

        // Test ERC1155
        lazy1155.pause();
        vm.expectRevert();
        lazy1155.mint(alice, 1, 1, "");
        lazy1155.unpause();
        lazy1155.mint(alice, 1, 1, "");
        vm.stopPrank();
    }

    function test_PauseAndUnpauseNFTs() public {
        // Setup initial NFTs
        vm.startPrank(owner);
        lazy721.safeMint(alice);
        lazy1155.mint(alice, 1, 5, "");

        // Test Lazy721 pause
        lazy721.pause();
        assertTrue(lazy721.paused());

        vm.expectRevert();
        lazy721.safeTransferFrom(alice, bob, 0);

        lazy721.unpause();
        assertFalse(lazy721.paused());

        // Test Lazy1155 pause
        lazy1155.pause();

        vm.expectRevert();
        lazy1155.safeTransferFrom(alice, bob, 1, 1, "");

        lazy1155.unpause();

        vm.stopPrank();

        // Verify transfers work after unpause
        vm.startPrank(alice);
        lazy721.approve(bob, 0);
        lazy721.safeTransferFrom(alice, bob, 0);

        lazy1155.setApprovalForAll(bob, true);
        lazy1155.safeTransferFrom(alice, bob, 1, 1, "");
        vm.stopPrank();
    }

    function test_MultipleSameUserStakes() public {
        vm.startPrank(owner);
        // Mint multiple NFTs to alice
        for (uint256 i = 0; i < 3; i++) {
            lazy721.safeMint(alice);
        }
        vm.stopPrank();

        vm.startPrank(alice);
        // Approve and stake multiple NFTs
        for (uint256 i = 0; i < 3; i++) {
            lazy721.approve(address(staking), i);
            staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), i);
        }
        vm.stopPrank();

        NFTStaking.StakeInfo[] memory aliceStakes = staking.getStakes(alice);
        assertEq(aliceStakes.length, 3);
        assertEq(staking.getStakingCount(alice), 3);

        // Verify each stake
        for (uint256 i = 0; i < 3; i++) {
            assertEq(aliceStakes[i].tokenId, i);
            assertEq(aliceStakes[i].tokenAddress, address(lazy721));
            assertEq(uint256(aliceStakes[i].status), uint256(NFTStaking.StakingStatus.STAKED));
        }
    }

    function test_GetPendingRewardsMultipleStakes() public {
        // Setup multiple stakes
        vm.startPrank(owner);
        lazy721.safeMint(alice);
        lazy721.safeMint(alice);
        vm.stopPrank();

        vm.startPrank(alice);
        lazy721.approve(address(staking), 0);
        lazy721.approve(address(staking), 1);

        // Stake at different times
        staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), 0);
        vm.roll(block.number + 10); // Advance 10 blocks
        staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), 1);
        vm.roll(block.number + 10); // Advance another 10 blocks

        uint256 rewards0 = staking.getPendingRewards(alice, 0);
        uint256 rewards1 = staking.getPendingRewards(alice, 1);

        assertTrue(rewards0 > rewards1, "First stake should have more rewards");
        vm.stopPrank();
    }

    function test_StakeAndUnstakeMultipleTokenTypes() public {
        // Setup
        vm.startPrank(owner);
        lazy721.safeMint(alice);
        lazy721a.safeMint(alice, 1);
        lazy1155.mint(alice, 1, 5, "");
        vm.stopPrank();

        vm.startPrank(alice);

        // Approve all
        lazy721.approve(address(staking), 0);
        lazy721a.approve(address(staking), 0);
        lazy1155.setApprovalForAll(address(staking), true);

        // Stake all types
        staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), 0);
        staking.stakeERC721{ value: STAKING_FEE }(address(lazy721a), 0);
        staking.stakeERC1155{ value: STAKING_FEE }(address(lazy1155), 1, 2);

        NFTStaking.StakeInfo[] memory stakes = staking.getStakes(alice);
        assertEq(stakes.length, 3);
        vm.stopPrank();
    }

    function test_RevertOnInvalidStakeIndex() public {
        vm.expectRevert(NFTStaking.NFTStaking__WrongDataFilled.selector);
        staking.unStake{ value: UNSTAKING_FEE }(0);

        vm.expectRevert(NFTStaking.NFTStaking__WrongDataFilled.selector);
        staking.getPendingRewards(alice, 99);

        vm.expectRevert(NFTStaking.NFTStaking__WrongDataFilled.selector);
        staking.getStakeStatus(alice, 99);
    }

    function test_MaxStakesLimitCompliance() public {
        vm.startPrank(owner);
        // Mint MAX_STAKES + 1 NFTs
        for (uint256 i = 0; i <= MAX_STAKES; i++) {
            lazy721.safeMint(alice);
        }
        vm.stopPrank();

        vm.startPrank(alice);
        // Try to stake more than MAX_STAKES
        for (uint256 i = 0; i <= MAX_STAKES; i++) {
            lazy721.approve(address(staking), i);
            if (i < MAX_STAKES) {
                staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), i);
            } else {
                vm.expectRevert(NFTStaking.NFTStaking__MaxStakingLimitReached.selector);
                staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), i);
            }
        }
        vm.stopPrank();
    }

    function test_ValidateOwnerOnlyFunctions() public {
        vm.prank(alice);
        vm.expectRevert(); // Ownable.OwnableUnauthorizedAccount(account);
        staking.setStakingFee(1 ether);

        vm.prank(alice);
        vm.expectRevert(); // Ownable.OwnableUnauthorizedAccount(account);
        staking.setUnstakingFee(1 ether);

        vm.prank(alice);
        vm.expectRevert(); // Ownable.OwnableUnauthorizedAccount(account);
        staking.withdrawFees();

        vm.prank(alice);
        vm.expectRevert(); // Ownable.OwnableUnauthorizedAccount(account);
        staking.setMaxStakesPerUser(100);
    }

    function test_StakingPeriodCompliance() public {
        // Setup
        vm.startPrank(owner);
        lazy721.safeMint(alice);
        vm.stopPrank();

        vm.startPrank(alice);
        lazy721.approve(address(staking), 0);
        staking.stakeERC721{ value: STAKING_FEE }(address(lazy721), 0);

        // Try to unstake immediately
        vm.expectRevert(NFTStaking.NFTStaking__StakingPeriodNotEnded.selector);
        staking.unStake{ value: UNSTAKING_FEE }(0);

        // Advance time but not enough
        vm.roll(block.number + INITIAL_STAKING_PERIOD - 1);
        vm.expectRevert(NFTStaking.NFTStaking__StakingPeriodNotEnded.selector);
        staking.unStake{ value: UNSTAKING_FEE }(0);

        // Advance enough time
        vm.roll(block.number + INITIAL_STAKING_PERIOD + 1);
        staking.unStake{ value: UNSTAKING_FEE }(0);
        vm.stopPrank();
    }

    function test_StakeWithInsufficientFee() public {
        vm.startPrank(owner);
        lazy721.safeMint(alice);
        vm.stopPrank();

        vm.startPrank(alice);
        lazy721.approve(address(staking), 0);

        vm.expectRevert(NFTStaking.NFTStaking__InsufficientStakingFee.selector);
        staking.stakeERC721{ value: STAKING_FEE - 1 }(address(lazy721), 0);

        vm.expectRevert(NFTStaking.NFTStaking__InsufficientStakingFee.selector);
        staking.stakeERC721{ value: 0 }(address(lazy721), 0);
        vm.stopPrank();
    }

    receive() external payable {}
}
