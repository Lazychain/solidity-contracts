import React from "react";
import { useAccount, useConnect, useDisconnect } from "wagmi";
import UserFunds from "@/components/UserFunds";

const Home: React.FC = () => {
  const account = useAccount();
  const { connectors, connect, error } = useConnect();
  const { disconnect } = useDisconnect();
  return (
    <>
      <div>
        {connectors.map((connector) => (
          <button
            key={connector.uid}
            onClick={() => connect({ connector })}
            type="button"
          >
            {connector.name}
          </button>
        ))}
      </div>
      {account.status === "connected" && (
        <button type="button" onClick={() => disconnect()}>
          Disconnect
        </button>
      )}
      <div>
        <h2>Account</h2>
        <div>{error?.message}</div>
        <div>
          addresses: {JSON.stringify(account.addresses)}
          chainId: {account.chainId}
          <UserFunds />
        </div>
      </div>
    </>
  );
};

export default Home;
