// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { TokenMetadata } from "../../metadata/TokenMetadata.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract TokenMetadataUpgradeable is Initializable, TokenMetadata {
    // solhint-disable func-name-mixedcase

    // solhint-disable no-empty-blocks
    function __TokenMetadata_init() internal onlyInitializing {}

    // solhint-disable no-empty-blocks
    function __TokenMetadata_init_unchained() internal onlyInitializing {}
    // solhint-enable func-name-mixedcase
}
