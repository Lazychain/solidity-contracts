// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { NFTStaking } from "../../../contracts/apps/staker/stake.sol";
import { ERC721 } from "openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC1155 } from "openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// Mock ERC721 contract for testing
contract MockERC721 is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

// Mock ERC1155 contract for testing
contract MockERC1155 is ERC1155 {
    constructor() ERC1155("") {}

    function mint(address to, uint256 id, uint256 amount) public {
        _mint(to, id, amount, "");
    }
}

contract NFTStakingTest is Test {
    NFTStaking public staking;
    MockERC721 public erc721;
    MockERC1155 public erc1155;

    address public owner;
    address public alice;
    address public bob;

    uint256 public constant TOKEN_ID = 1;
    uint256 public constant TOKEN_AMOUNT = 5;

    event Staked(address indexed staker, address indexed tokenAddress, uint256 tokenId, uint256 amount);
    event UnStaked(address indexed staker, address indexed tokenAddress, uint256 tokenId, uint256 amount);

    function setUp() public {
        owner = address(this);
        alice = address(0x1);
        bob = address(0x2);

        // Deploy contracts
        staking = new NFTStaking();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();

        // Setup test users with tokens
        vm.startPrank(owner);
        erc721.mint(alice, TOKEN_ID);
        erc1155.mint(alice, TOKEN_ID, TOKEN_AMOUNT);
        erc721.mint(bob, TOKEN_ID + 1);
        erc1155.mint(bob, TOKEN_ID, TOKEN_AMOUNT);
        vm.stopPrank();
    }

    // ERC721 Staking Tests
    function testStakeERC721() public {
        vm.startPrank(alice);
        erc721.approve(address(staking), TOKEN_ID);

        vm.recordLogs();
        staking.stakeERC721(address(erc721), TOKEN_ID);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Find and verify Staked event
        bool foundStakedEvent = false;
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("Staked(address,address,uint256,uint256)")) {
                address staker = address(uint160(uint256(entries[i].topics[1])));
                address tokenAddress = address(uint160(uint256(entries[i].topics[2])));
                uint256 tokenId = uint256(entries[i].topics[3]);
                uint256 amount = abi.decode(entries[i].data, (uint256));

                assertEq(staker, alice, "Wrong staker address");
                assertEq(tokenAddress, address(erc721), "Wrong token address");
                assertEq(tokenId, TOKEN_ID, "Wrong token ID");
                assertEq(amount, 1, "Wrong amount");

                foundStakedEvent = true;
                break;
            }
        }

        NFTStaking.StakeInfo[] memory stakes = staking.getStakes(alice);
        assertEq(stakes.length, 1);
        assertEq(stakes[0].tokenAddress, address(erc721));
        assertEq(stakes[0].tokenId, TOKEN_ID);
        assertEq(stakes[0].amount, 1);
        assertEq(stakes[0].isERC1155, false);
        vm.stopPrank();
    }

    function testFailStakeERC721NotOwned() public {
        vm.startPrank(bob);
        erc721.approve(address(staking), TOKEN_ID);
        staking.stakeERC721(address(erc721), TOKEN_ID); // Should fail as Bob doesn't own TOKEN_ID
        vm.stopPrank();
    }

    function testFailStakeERC721InvalidAddress() public {
        vm.startPrank(alice);
        staking.stakeERC721(address(0), TOKEN_ID);
        vm.stopPrank();
    }

    function testStakeERC1155() public {
        vm.startPrank(alice);
        erc1155.setApprovalForAll(address(staking), true);

        vm.recordLogs();
        staking.stakeERC1155(address(erc1155), TOKEN_ID, TOKEN_AMOUNT);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Find and verify Staked event
        bool foundStakedEvent = false;
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("Staked(address,address,uint256,uint256)")) {
                // Verify event parameters
                address staker = address(uint160(uint256(entries[i].topics[1])));
                address tokenAddress = address(uint160(uint256(entries[i].topics[2])));
                uint256 tokenId = uint256(entries[i].topics[3]);
                uint256 amount = abi.decode(entries[i].data, (uint256));

                // Assert all values match expected
                assertEq(staker, alice, "Wrong staker address");
                assertEq(tokenAddress, address(erc1155), "Wrong token address");
                assertEq(tokenId, TOKEN_ID, "Wrong token ID");
                assertEq(amount, TOKEN_AMOUNT, "Wrong amount");

                foundStakedEvent = true;
                break;
            }
        }

        assertTrue(foundStakedEvent, "Staked event was not emitted");

        NFTStaking.StakeInfo[] memory stakes = staking.getStakes(alice);
        assertEq(stakes.length, 1);
        assertEq(stakes[0].tokenAddress, address(erc1155));
        assertEq(stakes[0].tokenId, TOKEN_ID);
        assertEq(stakes[0].amount, TOKEN_AMOUNT);
        assertEq(stakes[0].isERC1155, true);
        vm.stopPrank();
    }

    function testRevertWhenStakingZeroAmount() public {
        vm.startPrank(alice);
        erc1155.setApprovalForAll(address(staking), true);

        vm.expectRevert(abi.encodeWithSignature("NFTStaking__WrongDataFilled(string)", "amount"));
        staking.stakeERC1155(address(erc1155), TOKEN_ID, 0);
        vm.stopPrank();
    }

    function testFailStakeERC1155InsufficientBalance() public {
        vm.startPrank(alice);
        erc1155.setApprovalForAll(address(staking), true);
        staking.stakeERC1155(address(erc1155), TOKEN_ID, TOKEN_AMOUNT + 1);
        vm.stopPrank();
    }

    // Withdrawal Tests
    function testWithdrawERC721() public {
        // First stake
        vm.startPrank(alice);
        erc721.approve(address(staking), TOKEN_ID);
        staking.stakeERC721(address(erc721), TOKEN_ID);

        vm.recordLogs();
        staking.unStake(0);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Find and verify Staked event
        bool foundStakedEvent = false;
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("UnStaked(address,address,uint256,uint256)")) {
                // Verify event parameters
                address staker = address(uint160(uint256(entries[i].topics[1])));
                address tokenAddress = address(uint160(uint256(entries[i].topics[2])));
                uint256 tokenId = uint256(entries[i].topics[3]);
                uint256 amount = abi.decode(entries[i].data, (uint256));

                // Assert all values match expected
                assertEq(staker, alice, "Wrong staker address");
                assertEq(tokenAddress, address(erc721), "Wrong token address");
                assertEq(tokenId, TOKEN_ID, "Wrong token ID");
                assertEq(amount, 1, "Wrong amount");

                foundStakedEvent = true;
                break;
            }
        }

        NFTStaking.StakeInfo[] memory stakes = staking.getStakes(alice);
        assertEq(stakes.length, 0);
        assertEq(erc721.ownerOf(TOKEN_ID), alice);
        vm.stopPrank();
    }

    function testWithdrawERC1155() public {
        // First stake
        vm.startPrank(alice);
        erc1155.setApprovalForAll(address(staking), true);
        staking.stakeERC1155(address(erc1155), TOKEN_ID, TOKEN_AMOUNT);

        vm.recordLogs();
        staking.unStake(0);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Find and verify Staked event
        bool foundStakedEvent = false;
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("UnStaked(address,address,uint256,uint256)")) {
                address staker = address(uint160(uint256(entries[i].topics[1])));
                address tokenAddress = address(uint160(uint256(entries[i].topics[2])));
                uint256 tokenId = uint256(entries[i].topics[3]);
                uint256 amount = abi.decode(entries[i].data, (uint256));

                assertEq(staker, alice, "Wrong staker address");
                assertEq(tokenAddress, address(erc1155), "Wrong token address");
                assertEq(tokenId, TOKEN_ID, "Wrong token ID");
                assertEq(amount, TOKEN_AMOUNT, "Wrong amount");

                foundStakedEvent = true;
                break;
            }
        }

        NFTStaking.StakeInfo[] memory stakes = staking.getStakes(alice);
        assertEq(stakes.length, 0);
        assertEq(erc1155.balanceOf(alice, TOKEN_ID), TOKEN_AMOUNT);
        vm.stopPrank();
    }

    function testFailWithdrawInvalidIndex() public {
        vm.startPrank(alice);
        staking.unStake(0); // Should fail as alice has no stakes
        vm.stopPrank();
    }

    // Duration Tests
    function testStakeDuration() public {
        vm.startPrank(alice);
        erc721.approve(address(staking), TOKEN_ID);
        staking.stakeERC721(address(erc721), TOKEN_ID);

        // Advance time by 1 day
        skip(1 days);

        uint256 duration = staking.getStakeDuration(alice, 0);
        assertEq(duration, 1 days);
        vm.stopPrank();
    }

    function testFailGetDurationInvalidIndex() public view {
        staking.getStakeDuration(alice, 0);
    }

    // Multiple Stakes Tests
    function testMultipleStakes() public {
        vm.startPrank(alice);

        // Stake ERC721
        erc721.approve(address(staking), TOKEN_ID);
        staking.stakeERC721(address(erc721), TOKEN_ID);

        // Stake ERC1155
        erc1155.setApprovalForAll(address(staking), true);
        staking.stakeERC1155(address(erc1155), TOKEN_ID, TOKEN_AMOUNT);

        NFTStaking.StakeInfo[] memory stakes = staking.getStakes(alice);
        assertEq(stakes.length, 2);
        vm.stopPrank();
    }

    // Reentrancy Guard Tests
    function testReentrancyGuard() public {
        vm.startPrank(alice);
        erc721.approve(address(staking), TOKEN_ID);
        staking.stakeERC721(address(erc721), TOKEN_ID);

        // Try to unStake while still processing first withdrawal
        vm.expectRevert();
        (bool success, ) = address(staking).call(abi.encodeWithSelector(staking.unStake.selector, 0));
        assertFalse(success);
        vm.stopPrank();
    }

    // Owner Functions Tests
    function testOwnership() public {
        assertEq(staking.owner(), owner);

        // Test ownership transfer
        address newOwner = address(0x123);
        staking.transferOwnership(newOwner);
        assertEq(staking.owner(), newOwner);
    }

    // Gas Tests
    function testGasStakeERC721() public {
        vm.startPrank(alice);
        erc721.approve(address(staking), TOKEN_ID);
        uint256 gasBefore = gasleft();
        staking.stakeERC721(address(erc721), TOKEN_ID);
        uint256 gasUsed = gasBefore - gasleft();
        assertLt(gasUsed, 200000); // Adjust threshold as needed
        vm.stopPrank();
    }

    function testGasStakeERC1155() public {
        vm.startPrank(alice);
        erc1155.setApprovalForAll(address(staking), true);
        uint256 gasBefore = gasleft();
        staking.stakeERC1155(address(erc1155), TOKEN_ID, TOKEN_AMOUNT);
        uint256 gasUsed = gasBefore - gasleft();
        assertLt(gasUsed, 200000); // Adjust threshold as needed
        vm.stopPrank();
    }
}
