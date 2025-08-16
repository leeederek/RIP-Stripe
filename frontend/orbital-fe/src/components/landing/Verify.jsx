import { signEvmTransaction } from '@coinbase/cdp-core';
import { useEvmAddress, useSendEvmTransaction } from '@coinbase/cdp-hooks';
import { createPublicClient, http, formatEther } from 'viem';
import { sepolia } from 'viem/chains';
import React, { useEffect, useMemo, useState } from 'react';

const ETH_SEPOLIA_CHAIN_ID = 11155111;

export default function Verify({ tokenKey }) {
    const { evmAddress } = useEvmAddress();
    const [ethBalance, setEthBalance] = useState(null);
    const { sendEvmTransaction, data } = useSendEvmTransaction();
    const client = useMemo(() => createPublicClient({ chain: sepolia, transport: http() }), []);

    useEffect(() => {
        (async () => {
            if (!evmAddress) return;
            try {
                const bal = await client.getBalance({ address: evmAddress });
                setEthBalance(bal);
            } catch (_) {
                setEthBalance(null);
            }
        })();
    }, [client, evmAddress]);

    const handleSign = async () => {
        if (!evmAddress) return;

        try {
            const result = await signEvmTransaction({
                evmAccount: evmAddress,
                transaction: {
                    to: "0x22862546E1004054E51a345Ab58De18258090c63",
                    value: 0n,
                    chainId: ETH_SEPOLIA_CHAIN_ID,
                    type: "eip1559"
                }
            });
            console.log("Signed Transaction:", result.signedTransaction);
        } catch (error) {
            console.error("Failed to sign transaction:", error);
        }
    };

    const handleSend = async () => {
        if (!evmAddress) return;
        try {
            const result = await sendEvmTransaction({
                evmAccount: evmAddress,
                transaction: {
                    to: "0x22862546E1004054E51a345Ab58De18258090c63",
                    value: 0n,
                    chainId: ETH_SEPOLIA_CHAIN_ID,
                    type: "eip1559",
                },
                network: "ethereum-sepolia",
            });
            console.log("Broadcasted Tx Hash:", result.transactionHash);
        } catch (error) {
            console.error("Failed to send transaction:", error);
        }
    };
    return (
        <div className="card" style={{ minHeight: 120 }}>
            <div className="row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
                <div className="stack" style={{ gap: 2 }}>
                    <div className="label">Network</div>
                    <div className="helper">Sepolia (11155111)</div>
                </div>
                <div className="stack" style={{ gap: 2, textAlign: 'right' }}>
                    <div className="label">ETH balance</div>
                    <div className="helper">{ethBalance == null ? '…' : `${formatEther(ethBalance)} ETH`}</div>
                </div>
            </div>
            <div className="row" style={{ marginTop: 8, justifyContent: 'flex-end', gap: 8 }}>
                <button className="btn" onClick={handleSign} disabled={!evmAddress}>Sign only</button>
                <button className="btn btn-primary" onClick={handleSend} disabled={!evmAddress || (ethBalance !== null && ethBalance === 0n)}>
                    {data?.status === 'pending' ? 'Sending…' : 'Sign & send'}
                </button>
            </div>
        </div>
    );
}


