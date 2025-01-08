import { Lazy1155 } from "@/contracts/Lazy1155";
import { useAccount } from "wagmi";

const Lazy1155Details: React.FC = () => {

  const account = useAccount();
  const lazy1155 = new Lazy1155(account);

  const { data: totalSupply } = lazy1155.totalSupply();
 
  if (!totalSupply) return <div>L1155 Loading...</div>;

  return (
    <div>
      Total Supply: [{totalSupply !== undefined ? Number(totalSupply) : 0}]
    </div>
  );
};

export default Lazy1155Details;
