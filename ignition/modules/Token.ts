import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Token", (m) => {
  const token = m.contract("TokenERC20", ["TIA", "tia"]);
  return { token };
});
