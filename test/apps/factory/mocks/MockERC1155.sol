// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../../../../contracts/interfaces/token/ILazy1155.sol";

contract MockERC1155 is ILazy1155 {
    error ERC1155TransferToZeroAddress();
    error ERC1155InsufficientBalance();
    error ERC1155NotApproved();

    mapping(address => mapping(uint256 => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => bool) private _tokenExists;
    mapping(uint256 => string) private _tokenURIs;
    bool private _paused;
    string private _uri;

    function mint(address to, uint256 id, uint256 amount) external {
        require(to != address(0), "ERC1155: mint to the zero address");
        _balances[to][id] += amount;
        _tokenExists[id] = true;
    }

    function balanceOf(address account, uint256 id) external view override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[account][id];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata /*data*/
    ) external override {
        if (to == address(0)) revert ERC1155TransferToZeroAddress();
        if (_balances[from][id] < amount) revert ERC1155InsufficientBalance();
        if (!_isApprovedOrOwner(msg.sender, from)) revert ERC1155NotApproved();
        require(!_paused, "ERC1155: token transfer while paused");

        _balances[from][id] -= amount;
        _balances[to][id] += amount;
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != address(0), "ERC1155: approve to the zero address");
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokenExists(uint256 tokenId) external view override returns (bool) {
        return _tokenExists[tokenId];
    }

    function setURI(string memory newuri) external override {
        _uri = newuri;
    }

    function tokenURI(address /*from*/, uint256 tokenId) external view override returns (string memory) {
        require(_tokenExists[tokenId], "ERC1155: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function isOwnerOfToken(address _owner, uint256 _tokenId) external view override returns (bool) {
        return _balances[_owner][_tokenId] > 0;
    }

    function pause() external override {
        _paused = true;
    }

    function unpause() external override {
        _paused = false;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory) external override {
        require(account != address(0), "ERC1155: mint to the zero address");
        _balances[account][id] += amount;
        _tokenExists[id] = true;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory) external override {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[to][ids[i]] += amounts[i];
            _tokenExists[ids[i]] = true;
        }
    }

    function _isApprovedOrOwner(address operator, address owner) internal view returns (bool) {
        return operator == owner || _operatorApprovals[owner][operator];
    }
}
