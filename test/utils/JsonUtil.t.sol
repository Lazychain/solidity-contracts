// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { JsonUtil } from "../../contracts/utils/JsonUtil.sol";

contract JsonUtilTest is Test {
    string private constant SIMPLE_JSON = '{"name":"John","age":30,"city":"New York"}';
    string private constant NESTED_JSON =
        '{"person":{"name":"John","age":30,"address":{"city":"New York","zip":"10001"}}}';
    string private constant ARRAY_JSON = '{"numbers":[1,2,3],"names":["John","Jane"]}';
    string private constant COMPLEX_JSON =
        '{"data":{"users":[{"id":1,"name":"John","active":true},{"id":2,"name":"Jane","active":false}]}}';

    function setUp() public {}

    function test_Get() public pure {
        string memory name = JsonUtil.get(SIMPLE_JSON, "name");
        string memory age = JsonUtil.get(SIMPLE_JSON, "age");
        string memory city = JsonUtil.get(SIMPLE_JSON, "city");

        assertEq(name, "John");
        assertEq(age, "30");
        assertEq(city, "New York");
    }

    function test_GetNested() public pure {
        assertEq(JsonUtil.get(NESTED_JSON, "person.name"), "John");
        assertEq(JsonUtil.get(NESTED_JSON, "person.age"), "30");
        assertEq(JsonUtil.get(NESTED_JSON, "person.address.city"), "New York");
        assertEq(JsonUtil.get(NESTED_JSON, "person.address.zip"), "10001");
    }

    function test_GetArray() public pure {
        assertEq(JsonUtil.get(ARRAY_JSON, "numbers[0]"), "1");
        assertEq(JsonUtil.get(ARRAY_JSON, "numbers[1]"), "2");
        assertEq(JsonUtil.get(ARRAY_JSON, "names[0]"), "John");
        assertEq(JsonUtil.get(ARRAY_JSON, "names[1]"), "Jane");
    }

    function test_GetComplex() public pure {
        assertEq(JsonUtil.get(COMPLEX_JSON, "data.users[0].name"), "John");
        assertEq(JsonUtil.get(COMPLEX_JSON, "data.users[1].name"), "Jane");
        assertEq(JsonUtil.get(COMPLEX_JSON, "data.users[0].active"), "true");
        assertEq(JsonUtil.get(COMPLEX_JSON, "data.users[1].active"), "false");
    }

    function test_GetInt() public pure {
        assertEq(JsonUtil.getInt(SIMPLE_JSON, "age"), 30);
        assertEq(JsonUtil.getInt(NESTED_JSON, "person.age"), 30);
    }

    function test_GetUint() public pure {
        assertEq(JsonUtil.getUint(SIMPLE_JSON, "age"), 30);
        assertEq(JsonUtil.getUint(NESTED_JSON, "person.age"), 30);
    }

    function test_GetBool() public pure {
        assertTrue(JsonUtil.getBool(COMPLEX_JSON, "data.users[0].active"));
        assertFalse(JsonUtil.getBool(COMPLEX_JSON, "data.users[1].active"));
    }

    function test_Exists() public pure {
        assertTrue(JsonUtil.exists(SIMPLE_JSON, "name"));
        assertTrue(JsonUtil.exists(NESTED_JSON, "person.address.city"));
        assertFalse(JsonUtil.exists(SIMPLE_JSON, "notexist"));
        assertFalse(JsonUtil.exists(NESTED_JSON, "person.notexist"));
    }

    function test_Validate() public pure {
        assertTrue(JsonUtil.validate(SIMPLE_JSON));
        assertTrue(JsonUtil.validate(NESTED_JSON));
        assertTrue(JsonUtil.validate(ARRAY_JSON));
        assertTrue(JsonUtil.validate(COMPLEX_JSON));
        assertFalse(JsonUtil.validate("{invalid json}"));
    }
}
