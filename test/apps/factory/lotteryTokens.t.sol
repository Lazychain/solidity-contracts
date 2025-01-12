// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC1155.sol";
import "../../../contracts/apps/factory/lotteryFactory.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract NFTHandlerTest is Test {
    ERC721Handler public erc721Handler;
    ERC1155Handler public erc1155Handler;
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;

    address public alice = address(0x1);
    address public bob = address(0x2);
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant AMOUNT = 5;

    function setUp() public {
        // Deploy mock contracts
        mockERC721 = new MockERC721();
        mockERC1155 = new MockERC1155();

        // Deploy handlers
        erc721Handler = new ERC721Handler(address(mockERC721));

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = TOKEN_ID;
        uint256[] memory maxSupplies = new uint256[](1);
        maxSupplies[0] = 10;
        erc1155Handler = new ERC1155Handler(address(mockERC1155), tokenIds, maxSupplies);

        // Setup initial state
        vm.startPrank(alice);
        mockERC721.mint(alice, TOKEN_ID);
        mockERC1155.mint(alice, TOKEN_ID, AMOUNT);
        vm.stopPrank();
    }

    // ERC721Handler Tests
    function testERC721Transfer() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = TOKEN_ID;
        uint256[] memory amounts = new uint256[](1);

        vm.startPrank(alice);
        mockERC721.setApprovalForAll(address(erc721Handler), true);
        erc721Handler.transferNFT(alice, bob, tokenIds, amounts);
        vm.stopPrank();

        assertEq(mockERC721.ownerOf(TOKEN_ID), bob);
    }

    function testERC721OwnerOf() public {
        assertEq(erc721Handler.ownerOf(TOKEN_ID), alice);
    }

    function testERC721BalanceOf() public {
        assertEq(erc721Handler.balanceOf(alice, 0), 1);
    }

    function testERC721MaxSupply() public {
        assertEq(erc721Handler.getMaxSupply(), 1);
    }

    function testERC721IsApprovedForAll() public {
        vm.startPrank(alice);
        mockERC721.setApprovalForAll(bob, true);
        vm.stopPrank();

        assertTrue(erc721Handler.isApprovedForAll(alice, bob));
    }

    function testERC721TokenExists() public {
        assertTrue(erc721Handler.tokenExists(TOKEN_ID));
    }

    // ERC1155Handler Tests
    function testERC1155Transfer() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = TOKEN_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2;

        vm.startPrank(alice);
        mockERC1155.setApprovalForAll(address(erc1155Handler), true);
        erc1155Handler.transferNFT(alice, bob, tokenIds, amounts);
        vm.stopPrank();

        assertEq(mockERC1155.balanceOf(bob, TOKEN_ID), 2);
        assertEq(mockERC1155.balanceOf(alice, TOKEN_ID), 3);
    }

    function testERC1155BalanceOf() public {
        assertEq(erc1155Handler.balanceOf(alice, TOKEN_ID), AMOUNT);
    }

    function testERC1155MaxSupply() public {
        assertEq(erc1155Handler.getMaxSupply(), 10);
    }

    function testERC1155TokenMaxSupply() public {
        assertEq(erc1155Handler.getTokenMaxSupply(TOKEN_ID), 10);
    }

    function testERC1155AllocatedAmount() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = TOKEN_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2;

        vm.startPrank(alice);
        mockERC1155.setApprovalForAll(address(erc1155Handler), true);
        erc1155Handler.transferNFT(alice, bob, tokenIds, amounts);
        vm.stopPrank();

        assertEq(erc1155Handler.getAllocatedAmount(TOKEN_ID), 2);
    }

    function testERC1155IsApprovedForAll() public {
        vm.startPrank(alice);
        mockERC1155.setApprovalForAll(bob, true);
        vm.stopPrank();

        assertTrue(erc1155Handler.isApprovedForAll(alice, bob));
    }

    function testERC1155TokenExists() public {
        assertTrue(erc1155Handler.tokenExists(TOKEN_ID));
    }

    // Error cases
    function testFailERC721TransferUnauthorized() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = TOKEN_ID;
        uint256[] memory amounts = new uint256[](1);

        vm.startPrank(bob);
        erc721Handler.transferNFT(alice, bob, tokenIds, amounts);
        vm.stopPrank();
    }

    function testFailERC1155ExceedMaxSupply() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = TOKEN_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 11; // Max supply is 10

        vm.startPrank(alice);
        mockERC1155.setApprovalForAll(address(erc1155Handler), true);
        erc1155Handler.transferNFT(alice, bob, tokenIds, amounts);
        vm.stopPrank();
    }

    function testFailERC1155ArrayLengthMismatch() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = TOKEN_ID;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.startPrank(alice);
        erc1155Handler.transferNFT(alice, bob, tokenIds, amounts);
        vm.stopPrank();
    }

    function testFailERC1155OwnerOf() public {
        erc1155Handler.ownerOf(TOKEN_ID);
    }

    receive() external payable {}
}
