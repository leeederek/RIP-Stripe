import { useEvmAddress } from "@coinbase/cdp-hooks";
import { Button } from "@coinbase/cdp-react/components/Button";
import { LoadingSkeleton } from "@coinbase/cdp-react/components/LoadingSkeleton";
import {
  SendTransactionButton,
  type SendTransactionButtonProps,
} from "@coinbase/cdp-react/components/SendTransactionButton";
import { useMemo, useState } from "react";

interface Props {
  balance?: string;
  onSuccess?: () => void;
}

/**
 * This component demonstrates how to send an EVM transaction using the CDP hooks.
 *
 * @param {Props} props - The props for the Transaction component.
 * @param {string} [props.balance] - The user's balance.
 * @param {() => void} [props.onSuccess] - A function to call when the transaction is successful.
 * @returns A component that displays a transaction form and a transaction hash.
 */
function Transaction(props: Props) {
  const { balance, onSuccess } = props;
  const { evmAddress } = useEvmAddress();
  const [transactionHash, setTransactionHash] = useState("");
  const [error, setError] = useState("");

  const hasBalance = useMemo(() => {
    return balance && balance !== "0";
  }, [balance]);

  const transaction = useMemo<SendTransactionButtonProps["transaction"]>(() => {
    return {
      to: evmAddress, // Send to yourself for testing
      value: 1000000000000n, // 0.000001 ETH in wei
      gas: 21000n,
      chainId: 84532, // Base Sepolia
      type: "eip1559",
    };
  }, [evmAddress]);

  const handleTransactionError: SendTransactionButtonProps["onError"] = error => {
    setTransactionHash("");
    setError(error.message);
  };

  const handleTransactionSuccess: SendTransactionButtonProps["onSuccess"] = hash => {
    setTransactionHash(hash);
    setError("");
    onSuccess?.();
  };

  const handleReset = () => {
    setTransactionHash("");
    setError("");
  };

  return (
    <>
      {balance === undefined && (
        <>
          <h2 className="card-title">Send a transaction</h2>
          <LoadingSkeleton className="loading--text" />
          <LoadingSkeleton className="loading--btn" />
        </>
      )}
      {balance !== undefined && (
        <>
          {!transactionHash && error && (
            <>
              <h2 className="card-title">Oops</h2>
              <p>{error}</p>
              <Button className="tx-button" onClick={handleReset} variant="secondary">
                Reset and try again
              </Button>
            </>
          )}
          {!transactionHash && !error && (
            <>
              <h2 className="card-title">Send a transaction</h2>
              {hasBalance && evmAddress && (
                <>
                  <p>Send 0.000001 ETH to yourself on Base Sepolia</p>
                  <SendTransactionButton
                    account={evmAddress}
                    network="base-sepolia"
                    transaction={transaction}
                    onError={handleTransactionError}
                    onSuccess={handleTransactionSuccess}
                  />
                </>
              )}
              {!hasBalance && (
                <>
                  <p>You need ETH to send a transaction, but you have none.</p>
                  <p>
                    Get some from{" "}
                    <a
                      href="https://portal.cdp.coinbase.com/products/faucet"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Base Sepolia Faucet
                    </a>
                  </p>
                </>
              )}
            </>
          )}
          {transactionHash && (
            <>
              <h2 className="card-title">Transaction sent</h2>
              <p>
                Transaction hash:{" "}
                <a
                  href={`https://sepolia.basescan.org/tx/${transactionHash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {transactionHash.slice(0, 6)}...{transactionHash.slice(-4)}
                </a>
              </p>
              <Button variant="secondary" className="tx-button" onClick={handleReset}>
                Send another transaction
              </Button>
            </>
          )}
        </>
      )}
    </>
  );
}

export default Transaction;
