// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Compress } from "./Compress.sol";
import { JsonUtil } from "./JsonUtil.sol";

library CompressedJSON {
    using Compress for bytes;
    error InvalidJSON();

    /**
     * @dev Unwraps the compressed JSON data.
     * @param _data The compressed JSON data.
     * @return The uncompressed JSON data as a string.
     */
    function unwrap(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) {
            return "{}";
        }
        return string(_data.decompress());
    }

    /**
     * @dev Wraps the JSON data into a compressed format.
     * @param _jsonBlob The JSON data to be compressed.
     * @return The compressed JSON data.
     */
    function wrap(string memory _jsonBlob) internal pure returns (bytes memory) {
        if (JsonUtil.validate(_jsonBlob)) revert InvalidJSON();
        string memory compacted = JsonUtil.compact(_jsonBlob);
        return bytes(compacted).compress();
    }
}
