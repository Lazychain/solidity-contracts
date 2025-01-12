// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../../../../contracts/interfaces/token/ILazy1155.sol";

contract MockERC1155 is ILazy1155 {
    mapping(address => mapping(uint256 => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => bool) private _tokenExists;

    function mint(address to, uint256 id, uint256 amount) external {
        _balances[to][id] += amount;
        _tokenExists[id] = true;
    }

    function balanceOf(address account, uint256 id) external view override returns (uint256) {
        return _balances[account][id];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata /*data*/
    ) external override {
        require(_balances[from][id] >= amount, "Insufficient balance");
        _balances[from][id] -= amount;
        _balances[to][id] += amount;
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokenExists(uint256 tokenId) external view override returns (bool) {
        return _tokenExists[tokenId];
    }

    function setURI(string memory newuri) external override {}

    function tokenURI(address from, uint256 tokenId) external view override returns (string memory) {}

    function isOwnerOfToken(address _owner, uint256 _tokenId) external view override returns (bool) {}

    function pause() external override {}

    function unpause() external override {}

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external override {}

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external override {}
}
