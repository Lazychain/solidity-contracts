# Foundry

## Scripting

### Deploy on Forma blockchain

- [mainnet](https://github.com/forma-dev/hyperlane-bridge-ui/blob/6e2726ac694d344e73daf41d6b3b7fd28e5313cf/src/consts/chains.ts#L11-L35)
- [testnet](https://github.com/forma-dev/hyperlane-bridge-ui/blob/6e2726ac694d344e73daf41d6b3b7fd28e5313cf/src/consts/chains.ts#L150-L174)

1 - Set env

```bash
source .env

export PRIVATE_KEY="..."
```

2- Import PK with cast

```bash
cast wallet import --private-key $PRIVATE_KEY deployer
```

3- Test the lottery deploy on Local host

```bash
anvil -m "$ANVIL_MNEMONIC"
forge script script/lottery.s.sol:Deploy 5 "ipfs://hash/{id}.json" 10000000000000000 "0x1234567890123456789012345678901234567890" "0x1234567890123456789012345678901234567890"  --sig 'run(uint256,string,uint256,address,address)' --fork-url $ANVIL_CHAIN_RPC
```

4- Forma testnet

```bash
forge script script/Lottery:Deploy \
  --rpc-url $FORMA_TESTNET_CHAIN_RPC \
  --key-store ~/.foundry/keystores/deployer \
  --resume \
  --verify \
  --verifier blockscout \
  --verifier-url $FORMA_TESTNET_EXPLORER_URL/api/
```

