# Foundry

## Scripting

### Deploy on Forma blockchain

- [mainnet](https://github.com/forma-dev/hyperlane-bridge-ui/blob/6e2726ac694d344e73daf41d6b3b7fd28e5313cf/src/consts/chains.ts#L11-L35)
- [testnet](https://github.com/forma-dev/hyperlane-bridge-ui/blob/6e2726ac694d344e73daf41d6b3b7fd28e5313cf/src/consts/chains.ts#L150-L174)

new wallet: `cast wallet new-mnemonic --words 24`

1 - Set env

```bash
cp .env.example .env
source .env
# Inside theres the `ANVIL_MNEMONIC`
```

2- Import PK with cast

```bash
# For testnet or mainnet
export PRIVATE_KEY="..." 
cast wallet import --private-key $PRIVATE_KEY deployer
```

3- Test the lottery deploy on Local host (anvil)

```bash
source .env.example
anvil -m "$ANVIL_MNEMONIC" --block-base-fee-per-gas 0 --gas-price 0
```

```bash
source .env.example
forge script script/lottery-local.s.sol:Deploy 5 "ipfs://hash/{id}.json" 10000000000000000 --sig 'run(uint256,string,uint256)' --fork-url $ANVIL_CHAIN_RPC --broadcast
```

4- Test the lottery deploy on local host with docker (hardhat + block-scout)

```bash
source .env.example
cd docker && docker-compose -f hardhat.yml up -d
cd docker && docker-compose -f blockscout.yml up -d
forge script script/lottery-local.s.sol:Deploy 5 "ipfs://bafybeiblder7ccleothvbdfaycwi7wobstz5tyay4qvkmrn6tfkrim7e54/{id}.json" 10000000000000000 --sig 'run(uint256,string,uint256)' --fork-url $ANVIL_CHAIN_RPC --broadcast
```

Reset hardhat and block-scout:

```bash
bun hardhat clean --global
sudo rm -rf services/stats-db-data/ services/blockscout-db-data/ services/redis-data/ services/logs/ services/dets/
```

Metamask:

Settings -> `Add Custom Network`

```text
name: hardhat
RPC: 127.0.0.1:8545
Chain Id: 31337
Symbol: ETH
Block explorer: localhost:80
```

4- Forma testnet

```shell
source .env.example
export WEI=10000000000000000
export TOKENS_ID_CAP=5
export IPFS_HASH="ipfs://bafybeiblder7ccleothvbdfaycwi7wobstz5tyay4qvkmrn6tfkrim7e54/{id}.json"
export FAIRYRING_ADDR="0xcA6cC5c1c4Fc025504273FE61fc0E09100B03D98"
export ACCOUNT="sketchpad_1"
export PRIVATE_KEY="..."
export QUANTITY=1000

forge script script/lottery.s.sol:Deploy \
  $TOKENS_ID_CAP "$IPFS_HASH" $WEI "$FAIRYRING_ADDR" \
  --sig 'run(uint256,string,uint256,address)' \
  --fork-url $FORMA_TESTNET_CHAIN_RPC \
  --keystore ~/.foundry/keystores/$ACCOUNT

forge script script/lottery.s.sol:Deploy \
  $TOKENS_ID_CAP "$IPFS_HASH" $WEI "$FAIRYRING_ADDR" \
  --sig 'run(uint256,string,uint256,address)' \
  --rpc-url $FORMA_TESTNET_CHAIN_RPC \
  --keystore ~/.foundry/keystores/$ACCOUNT \
  --resume \
  --verify \
  --verifier blockscout \
  --verifier-url $FORMA_TESTNET_EXPLORER_URL/api/
```
