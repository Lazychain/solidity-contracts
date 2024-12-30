// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { UpdatableTokenMetadata } from "../../metadata/UpdatableTokenMetadata.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract UpdatableTokenMetadataUpgradeable is Initializable, UpdatableTokenMetadata {
    // solhint-disable func-name-mixedcase
    // solhint-disable no-empty-blocks
    function __UpdatableTokenMetadata_init() internal onlyInitializing {}

    // solhint-disable no-empty-blocks
    function __UpdatableTokenMetadata_init_unchained() internal onlyInitializing {}
    // solhint-enable func-name-mixedcase
}
