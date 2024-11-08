// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library JsonParser {
    // Use uint8 instead of uint256 for error codes to save gas
    uint8 constant RETURN_SUCCESS = 0;
    uint8 constant RETURN_ERROR_INVALID_JSON = 1;
    uint8 constant RETURN_ERROR_PART = 2;
    uint8 constant RETURN_ERROR_NO_MEM = 3;

    enum JsonType {
        UNDEFINED,
        OBJECT,
        ARRAY,
        STRING,
        PRIMITIVE
    }

    struct Token {
        JsonType jsonType;
        uint256 start;
        uint256 end;
        uint8 size;
        bool startSet;
        bool endSet;
    }

    struct Parser {
        uint256 pos;
        uint256 toknext;
        int256 toksuper;
    }

    function init(uint256 length) internal pure returns (Parser memory parser, Token[] memory tokens) {
        parser = Parser(0, 0, -1);
        tokens = new Token[](length);
    }

    function allocateToken(
        Parser memory parser,
        Token[] memory tokens
    ) internal pure returns (bool success, Token memory token) {
        if (parser.toknext >= tokens.length) {
            return (false, tokens[tokens.length - 1]);
        }
        token = Token(JsonType.UNDEFINED, 0, 0, 0, false, false);
        tokens[parser.toknext] = token;
        parser.toknext++;
        return (true, token);
    }

    function fillToken(
        Token memory token,
        JsonType jsonType,
        uint256 start,
        uint256 end
    ) internal pure returns (Token memory) {
        token.jsonType = jsonType;
        token.start = start;
        token.end = end;
        token.startSet = true;
        token.endSet = true;
        token.size = 0;
        return token;
    }

    function parseString(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s
    ) internal pure returns (uint8 returnCode, Token memory token) {
        uint256 start = parser.pos;
        parser.pos++;

        for (; parser.pos < s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            if (c == '"') {
                (bool success, Token memory newToken) = allocateToken(parser, tokens);
                if (!success) {
                    parser.pos = start;
                    return (RETURN_ERROR_NO_MEM, token);
                }
                token = fillToken(newToken, JsonType.STRING, start + 1, parser.pos);
                return (RETURN_SUCCESS, token);
            }

            // Handle escaped characters
            if (uint8(c) == 92 && parser.pos + 1 < s.length) {
                parser.pos++;
                bytes1 nextChar = s[parser.pos];
                if (isValidEscapeChar(nextChar)) {
                    continue;
                }
                parser.pos = start;
                return (RETURN_ERROR_INVALID_JSON, token);
            }
        }
        parser.pos = start;
        return (RETURN_ERROR_PART, token);
    }

    function isValidEscapeChar(bytes1 c) internal pure returns (bool) {
        return (c == '"' || c == "/" || c == "\\" || c == "f" || c == "r" || c == "n" || c == "b" || c == "t");
    }

    function parsePrimitive(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s
    ) internal pure returns (uint8 returnCode, Token memory token) {
        uint256 start = parser.pos;
        bool found = false;

        for (; parser.pos < s.length; parser.pos++) {
            bytes1 c = s[parser.pos];
            if (isTerminatingChar(c)) {
                found = true;
                break;
            }
            if (!isValidPrimitiveChar(c)) {
                parser.pos = start;
                return (RETURN_ERROR_INVALID_JSON, token);
            }
        }

        if (!found) {
            parser.pos = start;
            return (RETURN_ERROR_PART, token);
        }

        (bool success, Token memory newToken) = allocateToken(parser, tokens);
        if (!success) {
            parser.pos = start;
            return (RETURN_ERROR_NO_MEM, token);
        }

        token = fillToken(newToken, JsonType.PRIMITIVE, start, parser.pos);
        parser.pos--;
        return (RETURN_SUCCESS, token);
    }

    function parse(
        string memory json,
        uint256 numberElements
    ) public pure returns (uint8 returnCode, Token[] memory tokens, uint256 tokenCount) {
        bytes memory s = bytes(json);
        Parser memory parser;
        (parser, tokens) = init(numberElements);

        for (; parser.pos < s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            if (isWhitespace(c)) continue;

            if (isOpeningBracket(c)) {
                if (!processOpeningBracket(parser, tokens, s)) return (RETURN_ERROR_NO_MEM, tokens, 0);
                continue;
            }

            if (isClosingBracket(c)) {
                if (!processClosingBracket(parser, tokens, c)) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                continue;
            }

            if (c == '"') {
                (uint8 stringResult, ) = parseString(parser, tokens, s);
                if (stringResult != RETURN_SUCCESS) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;
                continue;
            }

            if (c == ":") {
                parser.toksuper = int256(parser.toknext - 1);
                continue;
            }

            if (c == ",") {
                processComma(parser, tokens);
                continue;
            }

            if (isPrimitiveStartChar(c)) {
                (uint8 primResult, ) = parsePrimitive(parser, tokens, s);
                if (primResult != RETURN_SUCCESS) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;
                continue;
            }

            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
        }

        return (RETURN_SUCCESS, tokens, parser.toknext);
    }

    function processOpeningBracket(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s // Need to pass in the bytes array
    ) internal pure returns (bool) {
        (bool success, Token memory token) = allocateToken(parser, tokens);
        if (!success) return false;

        if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;

        // Fix: Compare the actual byte at parser.pos
        token.jsonType = (s[parser.pos] == bytes1(0x7b)) ? JsonType.OBJECT : JsonType.ARRAY;
        token.start = parser.pos;
        token.startSet = true;
        parser.toksuper = int256(parser.toknext - 1);
        return true;
    }

    function processClosingBracket(Parser memory parser, Token[] memory tokens, bytes1 c) internal pure returns (bool) {
        JsonType tokenType = (c == bytes1(0x7d)) ? JsonType.OBJECT : JsonType.ARRAY;

        for (uint256 i = parser.toknext - 1; i < parser.toknext; i--) {
            Token memory token = tokens[i];
            if (token.startSet && !token.endSet) {
                if (token.jsonType != tokenType) return false;
                parser.toksuper = -1;
                tokens[i].end = parser.pos + 1;
                tokens[i].endSet = true;
                return true;
            }
            if (i == 0) break;
        }
        return false;
    }

    function processComma(Parser memory parser, Token[] memory tokens) internal pure {
        for (uint256 i = parser.toknext - 1; i < parser.toknext; i--) {
            if (
                (tokens[i].jsonType == JsonType.ARRAY || tokens[i].jsonType == JsonType.OBJECT) &&
                tokens[i].startSet &&
                !tokens[i].endSet
            ) {
                parser.toksuper = int256(i);
                break;
            }
            if (i == 0) break;
        }
    }

    function isOpeningBracket(bytes1 c) internal pure returns (bool) {
        return (c == bytes1(0x7b) || c == bytes1(0x5b));
    }

    function isClosingBracket(bytes1 c) internal pure returns (bool) {
        return (c == bytes1(0x7d) || c == bytes1(0x5d));
    }

    function isWhitespace(bytes1 c) internal pure returns (bool) {
        return (c == bytes1(0x20) || c == bytes1(0x09) || c == bytes1(0x0a) || c == bytes1(0x0d));
    }

    function isPrimitiveStartChar(bytes1 c) internal pure returns (bool) {
        return ((c >= bytes1(0x30) && c <= bytes1(0x39)) || // 0-9
            c == bytes1(0x2d) || // -
            c == bytes1(0x66) || // f
            c == bytes1(0x74) || // t
            c == bytes1(0x6e)); // n
    }

    function isTerminatingChar(bytes1 c) internal pure returns (bool) {
        return (c == bytes1(0x20) ||
            c == bytes1(0x09) ||
            c == bytes1(0x0a) ||
            c == bytes1(0x0d) ||
            c == bytes1(0x2c) ||
            c == bytes1(0x7d) ||
            c == bytes1(0x5d));
    }

    function isValidPrimitiveChar(bytes1 c) internal pure returns (bool) {
        return (uint8(c) >= 32 && uint8(c) <= 127);
    }

    // String utility functions
    function getBytes(string memory json, uint256 start, uint256 end) public pure returns (string memory) {
        bytes memory s = bytes(json);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = s[i];
        }
        return string(result);
    }

    function parseInt(string memory _a) public pure returns (int256) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint256 _b) public pure returns (int256) {
        bytes memory bresult = bytes(_a);
        int256 mint = 0;
        bool decimals = false;
        bool negative = false;
        uint256 divisor = 1;

        for (uint256 i = 0; i < bresult.length; i++) {
            if (bresult[i] == bytes1(0x2d)) {
                negative = true;
            } else if (bresult[i] == bytes1(0x2e)) {
                decimals = true;
            } else if (uint8(bresult[i]) >= 48 && uint8(bresult[i]) <= 57) {
                if (decimals && _b > 0) {
                    divisor *= 10;
                    mint = mint * 10 + int256(uint256(uint8(bresult[i]) - 48));
                    _b--;
                } else if (!decimals) {
                    mint = mint * 10 + int256(uint256(uint8(bresult[i]) - 48));
                }
            }
        }
        return negative ? -mint / int256(divisor) : mint / int256(divisor);
    }

    function uint2str(uint256 i) public pure returns (string memory) {
        if (i == 0) return "0";
        uint256 temp = i;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (i != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(i % 10)));
            i /= 10;
        }
        return string(buffer);
    }

    function parseBool(string memory _a) public pure returns (bool) {
        return strCompare(_a, "true") == 0;
    }

    function strCompare(string memory _a, string memory _b) public pure returns (int256) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length < b.length ? a.length : b.length;

        for (uint256 i = 0; i < minLength; i++) {
            if (a[i] < b[i]) return -1;
            if (a[i] > b[i]) return 1;
        }

        if (a.length < b.length) return -1;
        if (a.length > b.length) return 1;
        return 0;
    }
}
