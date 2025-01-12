// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../../../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract MockERC721 is IERC721Enumerable {
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidOperator(address operator);

    uint256 private _totalSupply;
    uint256[] private _allTokens;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Enumerable mappings
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(uint256 => address) private _tokenApprovals;

    function mint(address to, uint256 tokenId) external {
        _owners[tokenId] = to;
        _balances[to]++;
        _totalSupply++;
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _owners[tokenId];
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return _balances[owner];
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(_owners[tokenId] == from, "ERC721: transfer from incorrect owner");

        // Check if msg.sender is approved or owner
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert ERC721InsufficientApproval(msg.sender, tokenId);
        }

        // Update ownership
        _owners[tokenId] = to;
        _balances[from]--;
        _balances[to]++;

        delete _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        require(index < _balances[owner], "Index out of bounds");
        return _ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) external view override returns (uint256) {
        require(index < _totalSupply, "Index out of bounds");
        return _allTokens[index];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId];
        return (spender == owner || _operatorApprovals[owner][spender] || _tokenApprovals[tokenId] == spender);
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {}

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external override {}

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {}

    function approve(address to, uint256 tokenId) external override {}

    function getApproved(uint256 tokenId) external view override returns (address operator) {}
}
