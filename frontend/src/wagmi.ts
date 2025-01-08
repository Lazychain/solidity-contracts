import { http, createConfig } from "wagmi";
import { forma, sketchpad, anvil } from "wagmi/chains";
import { injected } from "wagmi/connectors";

export const config = createConfig({
  chains: [forma, sketchpad,anvil],
  connectors: [injected()],
  transports: {
    [forma.id]: http(),
    [sketchpad.id]: http(),
    [anvil.id]: http(),
  },
  ssr: true, // you want this to avoid hydration errors.
});

declare module "wagmi" {
  interface Register {
    config: typeof config;
  }
}
