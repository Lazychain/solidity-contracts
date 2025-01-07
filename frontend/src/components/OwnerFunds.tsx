import { NFTlottery } from "@/contracts/NFTLottery";
import { useState } from "react";
import { formatEther, parseEther } from "viem";
import {
  useAccount,
  useWaitForTransactionReceipt,
  UseWaitForTransactionReceiptReturnType,
} from "wagmi";

export default function OwnerFunds() {
  const account = useAccount();
  const lottery = new NFTlottery(account);
  const { data: balanceResult } = lottery.OwnerBalance();
  const [withdrawValue, setwithdrawValue] = useState<UseWaitForTransactionReceiptReturnType>();

  const onClickWithdraw = () => {
    lottery.execute_function("withdraw", account, [account.address!], parseEther("1"));
    const wait =  useWaitForTransactionReceipt({
      hash: lottery.execute.data,
    });
    setwithdrawValue(wait);
  };

  return (
    <div>
      <span>
        Lottery Balance: [
        {balanceResult !== null && typeof balanceResult === "bigint"
          ? formatEther(balanceResult as bigint)
          : "0"}
        ]
      </span>
      {balanceResult !== null &&
      typeof balanceResult === "bigint" &&
      balanceResult > BigInt(0) ? (
        <button
          onClick={onClickWithdraw}
          disabled={!account.isConnected || withdrawValue?.isLoading || withdrawValue?.isPending}
          className="ml-3 rounded-xl text-green-400 px-3 py-1 font-bold"
        >
          Withdraw
        </button>
      ) : null}
      {withdrawValue?.isLoading && (
        <span className="ml-3 text-lg">Confirming receipt...</span>
      )}
      {withdrawValue?.isSuccess && (
        <span className="ml-3 text-lg text-green-400">Success</span>
      )}
      {withdrawValue?.isError && (
        <span className="ml-3 text-lg text-red-500">
          {withdrawValue.error.message}
        </span>
      )}
    </div>
  );
}
