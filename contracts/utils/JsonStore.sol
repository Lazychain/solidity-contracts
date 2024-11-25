// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Base64 } from "./Base64.sol";
import { JsonUtil } from "./JsonUtil.sol";
// import { IBase64 } from "../interfaces/precompile/IBase64.sol";
import { IJsonStore } from "../interfaces/precompile/IJsonStore.sol";

library JsonStore {
    // solhint-disable private-vars-leading-underscore
    IJsonStore internal constant STORE = IJsonStore(0x00000000000000000000000000000F043a000007);
    // IBase64 internal constant BASE64 = IBase64(0x00000000000000000000000000000f043a000004);

    ////////////
    // EVENTS //
    ////////////
    event JsonStored(address indexed owner, bytes32 indexed slot);
    event JsonCleared(address indexed owner, bytes32 indexed slot);
    event SlotsPrepaid(address indexed owner, uint64 numSlots);

    struct JsonData {
        string jsonBlob;
        bool exists;
        address owner;
    }

    struct Store {
        mapping(bytes32 => JsonData) jsonStorage;
        mapping(address => uint64) prepaidSlots;
    }

    ////////////
    // Errors //
    ////////////
    error JsonStore__InsufficientPrepaidSlots();
    error JsonStore__SlotDoesNotExist();
    error JsonStore__Unauthorized();
    error JsonStore__InvalidJson();

    // solhint-enable private-vars-leading-underscore

    function exists(Store storage self, address _key, bytes32 _slot) internal view returns (bool) {
        JsonData storage data = self.jsonStorage[_slot];
        return data.exists && data.owner == _key;
    }

    function uri(Store storage self, address _key, bytes32 _slot) internal view returns (string memory) {
        if (!exists(self, _key, _slot)) revert JsonStore__SlotDoesNotExist();
        // Convert JSON to data URI format
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(self.jsonStorage[_slot].jsonBlob))
                )
            );
    }

    function get(Store storage self, address _key, bytes32 _slot) internal view returns (string memory) {
        if (!exists(self, _key, _slot)) revert JsonStore__SlotDoesNotExist();
        return self.jsonStorage[_slot].jsonBlob;
    }

    function prepaid(Store storage self, address _key) internal view returns (uint64) {
        return self.prepaidSlots[_key];
    }

    function exists(bytes32 _slot) internal view returns (bool) {
        return STORE.exists(_slot);
    }

    function uri(bytes32 _slot) internal view returns (string memory) {
        return STORE.uri(_slot);
    }

    function get(bytes32 _slot) internal view returns (string memory) {
        return STORE.get(_slot);
    }

    function prepaid(Store storage self) internal view returns (uint64) {
        return self.prepaidSlots[msg.sender];
    }

    function set(Store storage self, bytes32 _slot, string memory _jsonBlob) internal returns (bool) {
        if (!JsonUtil.validate(_jsonBlob)) revert JsonStore__InvalidJson();

        // Check prepaid slots
        if (self.prepaidSlots[msg.sender] == 0) revert JsonStore__InsufficientPrepaidSlots();

        self.jsonStorage[_slot] = JsonData({ jsonBlob: _jsonBlob, exists: true, owner: msg.sender });

        self.prepaidSlots[msg.sender]--;
        emit JsonStored(msg.sender, _slot);
        return true;
    }

    function clear(Store storage self, bytes32 _slot) internal returns (bool) {
        if (!exists(self, msg.sender, _slot)) revert JsonStore__SlotDoesNotExist();

        delete self.jsonStorage[_slot];
        emit JsonCleared(msg.sender, _slot);
        return true;
    }

    function prepaySlots(Store storage self, address _owner, uint64 _numSlots) internal {
        self.prepaidSlots[_owner] += _numSlots;
        emit SlotsPrepaid(_owner, _numSlots);
    }
}
