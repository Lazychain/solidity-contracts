import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ERC721", (m) => {
  const nft = m.contract("ERC721", ["lazyNFT","LNFT"]);
  return { token: nft };
});
