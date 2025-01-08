import { formatEther } from "viem";
import {
  useAccount,
  useWaitForTransactionReceipt,
  useWriteContract,
} from "wagmi";
import { NFTlotteryContract } from "../contracts/NFTLottery";

export default function Draw() {
  const account = useAccount();
  const {
    data: hashDraw,
    isPending: drawPending,
    writeContract,
  } = useWriteContract({
    mutation: {
      onSuccess: () => {},
    },
  });

  const {
    isLoading: isDrawing,
    isSuccess: isSuccessDraw,
    error: errorDraw,
  } = useWaitForTransactionReceipt({
    hash: hashDraw,
  });

  const onClickWithdraw = (guess: number) => {
    writeContract(
      {
        ...NFTlotteryContract,
        functionName: "draw",
        account: account.address,
        args: [guess], // TODO: Add input text for destination wallet
      },
      {
        onError: (error) => {
          console.error(error.message);
        },
      },
    );
  };

  return (
    <div className="flex items-center justify-center">
      <span className="text-lg font-bold">
        Lottery Balance: [{balanceResult !== undefined ? formatEther(balanceResult) : "0"}]
      </span>
      {balanceResult && balanceResult > BigInt(0) ? (
        <button
          onClick={onClickWithdraw}
          disabled={!account.isConnected || isWithdrawing || withdrawPending}
          className="ml-3 rounded-xl bg-gray-600 px-3 py-1 font-bold"
        >
          Withdraw
        </button>
      ) : null}
      {isWithdrawing && (
        <span className="ml-3 text-lg">Confirming receipt...</span>
      )}
      {isSuccessWithdraw && (
        <span className="ml-3 text-lg text-green-400">Success</span>
      )}
      {errorWithdraw && (
        <span className="ml-3 text-lg text-red-500">
          {errorWithdraw.message}
        </span>
      )}
    </div>
  );
}