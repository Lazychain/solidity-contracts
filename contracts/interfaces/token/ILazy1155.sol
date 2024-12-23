// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILazy1155 {
    function setURI(string memory newuri) external;
    function tokenURI(address from, uint256 tokenId) external view returns (string memory);
    function isOwnerOfToken(address _owner, uint256 _tokenId) external view returns (bool);
    function tokenExists(uint256 _tokenId) external view returns (bool);
    function pause() external;
    function unpause() external;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
