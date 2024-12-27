// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

// solhint-disable no-empty-blocks
abstract contract ERC721Base is ERC721Royalty {}
