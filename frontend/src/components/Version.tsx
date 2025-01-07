import { useAccount } from "wagmi";
import { NFTlottery } from "@/contracts/NFTLottery";

export default function Version() {
  const account = useAccount();
  const lottery = new NFTlottery(account);

  const { data, isLoading, error } = lottery.version();

  return (
    <div>
      {isLoading ? (
        <div>Version Loading...</div>
      ) : error ? (
          <div>Error loading version { error?.name }</div>
      ) : (
        <div>Version: {data as string ?? "Not Available"}</div>
      )}
    </div>
  );
}
