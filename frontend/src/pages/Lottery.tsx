import {
  useAccount,
  useWaitForTransactionReceipt,
  useWatchContractEvent,
} from "wagmi";

import { useState } from "react";
import { Card } from "@/components/ui/card";
import Button from "@/components/Button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { NFTlottery } from "@/contracts/NFTLottery";
import { Input } from "@/components/ui/input";
import { formatEther, parseEther } from "ethers";
import { useToast } from "@/hooks/use-toast";
import { useEffect } from "react";
import { ToastAction } from "@/components/ui/toast";
import { Lazy1155 } from "@/contracts/Lazy1155";
import Version from "@/components/Version";
import OwnerFunds from "@/components/OwnerFunds";
import Lazy1155Details from "@/components/Lazy1155Details";
import { FairyRingContract } from "@/contracts/FairyRing";

const Lottery: React.FC = () => {
  const account = useAccount();
  const lottery = new NFTlottery(account);
  const lazy1155 = new Lazy1155(account);

  const { toast } = useToast();
  const [selectedValue, setSelectedValue] = useState("");

  const [totalDraws, setTotalDraws] = useState(0);
  const [points, setPoints] = useState(0);
  const [nftBalance, setnftBalance] = useState([0, 0, 0, 0, 0]);
  const [drawResult, setDrawResult] = useState(false);
  const [winTokenId, setwinTokenId] = useState("");

  const [inputsValues, setInputsValues] = useState<Record<string, string>>({});

  const executeFunctions = lottery.getExecuteFuntions();
  const isCampaignOpen = lottery.isCampaignOpen();
  const isFee = lottery.isFee();

  let {
    isLoading,
    isSuccess,
    error: isError,
  } = useWaitForTransactionReceipt({
    hash: lottery.execute.data,
  });

  const onClickExecute = async () => {
    setDrawResult(false);
    console.log(`Function name [${selectedValue}]`);
    console.log(`Inputs [${JSON.stringify(Object.values(inputsValues))}]`);
    if (!selectedValue) return;
    lottery.execute_function(
      selectedValue,
      account,
      Object.values(inputsValues),
      parseEther("1")
    );
  };

  const handleInputChange = (name: string, value: string) => {
    setInputsValues((prev) => ({ ...prev, [name]: value }));
  };

  useEffect(() => {
    if (isError) {
      console.log(isError.message);
      toast({
        variant: "destructive",
        title: "Uh oh! Something went wrong.",
        description: isError.message,
        action: <ToastAction altText="Try again">Try again</ToastAction>,
      });
    }
  }, [isError]);

  useEffect(() => {
    if (isSuccess) {
      toast({
        title: "Transaction Successful",
        description: lottery.execute.data as string,
      });
      // declare the data fetching function
      const fetchPoints = async () => {
        const data = await lottery.isPoints();
        setPoints(Number(data));
      };
      // call the function
      fetchPoints().catch(console.error);

      // declare the data fetching function
      const fetchDraws = async () => {
        const data = await lottery.isTotalDraws();
        setTotalDraws(Number(data));
      };
      // call the function
      fetchDraws().catch(console.error);

      // declare the data fetching function
      const fetchNftBalance = async () => {
        const nftType1 = await lazy1155.balanceOf(1);
        const nftType2 = await lazy1155.balanceOf(2);
        const nftType3 = await lazy1155.balanceOf(3);
        const nftType4 = await lazy1155.balanceOf(4);
        const nftType5 = await lazy1155.balanceOf(5);
        console.log(nftType1);
        setnftBalance([
          Number(nftType1),
          Number(nftType2),
          Number(nftType3),
          Number(nftType4),
          Number(nftType5),
        ]);
      };
      // call the function
      fetchNftBalance().catch(console.error);
    }
  }, [isSuccess]);

  useEffect(() => {
    const fetchNumber = async () => {
      const data = await lottery.isTotalDraws();
      setTotalDraws(Number(data));
    };
    fetchNumber().catch(console.error);
  }, []);

  useWatchContractEvent({
    address: lottery.address,
    abi: lottery.abi,
    eventName: "LotteryDrawn",
    args: {
      player: account.address,
    },
    onLogs: (logs: any) => {
      logs.map((log: any) => {
        if (log.args.result) {
          setDrawResult(true);
          setwinTokenId(log.args.nftId);
        }
      });
    },
    onError(error: any) {
      console.log("ERROR FROM WATCH CONTRACT EVENT", error);
    },
    // enabled: account.isConnected && !!account.address,
  });

  return (
    <Card>
      <h2>Lottery</h2>
      <div>
        Lottery Address: {lottery.address}
        <Version />
        <OwnerFunds />
      </div>
      <div>
        Lazy1155 Address: {lazy1155.address}
        <Lazy1155Details />
      </div>
      <div>FairyRIng Address: {FairyRingContract.address}</div>
      {isCampaignOpen ? <p>Campaign: Open</p> : <p>Campaign: Closed</p>}
      {isFee ? (
        <p>Fee[{formatEther(isFee as string)}] ETH</p>
      ) : (
        <p>Fee[0] ETH</p>
      )}
      <p>TotalDraws[{totalDraws}]</p>
      <p>Points[{points}]</p>
      <p>NFT Balance</p>
      <p>-------------</p>
      <div>
        <ul>
          {nftBalance.map((item) => (
            <li>{item}</li>
          ))}
        </ul>
      </div>
      <p>-------------</p>
      {isLoading ? (
        <Button onClick={() => {}}>"Executing..."</Button>
      ) : (
        <Button onClick={onClickExecute}>"Execute"</Button>
      )}

      <Select
        onValueChange={(value) => {
          setSelectedValue(value);
          setInputsValues({});
        }}
      >
        <SelectTrigger className="w-[180px]">
          <SelectValue placeholder="Execute Functions" />
        </SelectTrigger>
        <SelectContent>
          {executeFunctions.map((item) => (
            <SelectItem key={item.name ?? ""} value={item.name ?? ""}>
              {item.name ?? ""}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      {executeFunctions.map((item) => (
        <div key={item.name ?? ""}>
          {item.name === selectedValue && (
            <div>
              {item.inputs!.map((input) => (
                <div key={input.name}>
                  <label>{input.name}</label>
                  <Input
                    type="text"
                    value={inputsValues[input.name] ?? ""}
                    onChange={(e) =>
                      handleInputChange(input.name, e.target.value)
                    }
                  />
                </div>
              ))}
            </div>
          )}
        </div>
      ))}

      {isSuccess && (
        <>
          {lottery.execute.data && (
            <div>
              Transaction Hash:{" "}
              <a
                href={`http://localhost/tx/${lottery.execute.data}?tab=index`}
                target="_blank"
              >
                Explorer Link
              </a>
            </div>
          )}
          <p>Result: {drawResult ? `Win tokenId[${winTokenId}]` : "Lose!"}</p>
        </>
      )}
    </Card>
  );
};

export default Lottery;
