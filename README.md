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

> Install all the packages

```sh
npm i
# or
npm i --force
```

> Build contracts

```sh
forge build
# Or
npm run build
```

<details>
<summary>
Success message
</summary>

```
> @lazychain/solidity-contracts@0.9.0 build
> forge build --extra-output-files bin --extra-output-files abi

[⠊] Compiling...
[⠢] Compiling 12 files with Solc 0.8.24
[⠆] Solc 0.8.24 finished in 118.77ms
Compiler run successful!
```

</details>

## Tools

[Forge](https://book.getfoundry.sh/getting-started/installation) and [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started#quick-start).
[bun](https://bun.sh/) for typescript

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
