interface BalanceDetailsProps {
  balanceData?: {
    decimals: number;
    formatted: string;
    symbol: string;
    value: bigint;
  };
}

const BalanceDetails: React.FC<BalanceDetailsProps> = ({ balanceData }) => {
  if (!balanceData) return <div>BD Loading...</div>;

  return (
    <div>
      Balance: {Number(balanceData.formatted).toFixed(2)} [{balanceData.symbol}]
    </div>
  );
};

export default BalanceDetails;
