import { useAccount, useBalance } from "wagmi";
import BalanceDetails from "./BalanceDetails";

export default function UserFunds() {
  const { address } = useAccount();
  const {
    data: balanceData,
    isError,
    isLoading,
  } = useBalance({
    address: address, // Fetch balance for the connected address
  });

  if (isLoading) {
    return <div>Loading Balance...</div>;
  }

  if (isError) {
    return <div>Error fetching balance</div>;
  }

  return <BalanceDetails balanceData={balanceData} />;
}
