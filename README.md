# LazyChain Smart Contracts

## Documentation

Check `docs` project.

## Installation

> Install [**`bun`**](https://bun.sh/)

```sh
curl -fsSL https://bun.sh/install | bash
```

> Install [**`foundry`**](https://book.getfoundry.sh/getting-started/installation)

```sh
curl -L https://foundry.paradigm.xyz | bash
# Follow on-screen command
```

## Tests

> Install all the packages

```sh
bun i # openzeppeling
forge install # git modules
```

> Build contracts

```sh
bun run hardhat:compile
forge build
```

> Run tests

```bash

``` 

## Tools

- [Forge](https://book.getfoundry.sh/getting-started/installation) and [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started#quick-start).
- [bun](https://bun.sh/) for typescript
- [slither](https://github.com/crytic/slither) for static code analysis.
- [solhint](https://protofire.github.io/solhint/docs/rules.html#best-practise-rules)

## Foundry Testing

### stateless fuzzing

Test should have to be design to receive (inject) the variable we want to test (Inversion of control). On foundry, we can do this be configuring the `foundry.toml` add `[fuzz]` section.

### State full fuzzing

On foundry:
    - import `StdInvariant.sol`.
    - Inherit on the test contract `is StdInvariant, Test`.
    - On `Setup()` set the entrypoint `targetContract(address(<contract under test>))`.

### Coverage guide fuzzing

on Echidna or Medusa.

### Example

```solidity
// src/contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MyContract {

    struct UserNameSpace {
        address userAddress;
        string nickName;
        uint256 draws_count;
        uint256 win_count;
    }

    function updateUserNameSpace(UserNameSpace calldata newNamespace) public {
        // ... implementation logic
    }
}
```

#### Foundry

```solidity
// test/MyContractTest.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/contracts/MyContract.sol";

contract MyContractTest is Test {
    MyContract myContract;

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    function setUp() public {
        myContract = new MyContract();
    }

    function testUpdateUserNameSpaceFuzz(address userAddress, string memory nickName, uint256 drawsCount, uint256 winCount) public {
        UserNameSpace memory namespace = UserNameSpace(userAddress, nickName, drawsCount, winCount);
        myContract.updateUserNameSpace(namespace);

        // Add assertions here to check the state of the contract after the update
        // ...
    }
}
```

`forge test`

- [invariant-testing](https://book.getfoundry.sh/forge/invariant-testing)
- [differential-ffi-testing](https://book.getfoundry.sh/forge/differential-ffi-testing)

#### Echidna

TODO

## hardhat Test

TODO

### Gas tracking

-[gas-tracking](https://book.getfoundry.sh/forge/gas-tracking)

```bash
forge install transmissions11/solmate
forge remappings
```
