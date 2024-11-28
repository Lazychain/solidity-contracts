import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Asset", (m) => {
  const asset = m.contract("LazyAsset", ["Lazy Asset", "LZA"]);
  return { asset };
});
