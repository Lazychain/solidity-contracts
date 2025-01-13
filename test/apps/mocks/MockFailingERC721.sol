// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockFailingERC721 {
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x80ac58cd; // Return true for ERC721 interface
    }

    function tokenExists(uint256) external pure returns (bool) {
        return false;
    }

    function tokenURI(uint256) external pure returns (string memory) {
        return ""; // Return empty string to trigger NFTNotEligible
    }

    function ownerOf(uint256) external pure returns (address) {
        return address(0);
    }
}
