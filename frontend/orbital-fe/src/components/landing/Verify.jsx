import { signEvmTransaction } from '@coinbase/cdp-core';
import { useEvmAddress, useSendEvmTransaction } from '@coinbase/cdp-hooks';
import { createPublicClient, http, formatEther, parseUnits, encodeFunctionData, getAddress, erc20Abi, decodeErrorResult } from 'viem';
import { sepolia } from 'viem/chains';
import React, { useEffect, useMemo, useState } from 'react';

const ETH_SEPOLIA_CHAIN_ID = 11155111;
const PYUSD = getAddress("0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9");
const USDC = getAddress("0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238");
const SWAP_CONTRACT = "0x66Ca370a48f377E6b9D99bF21007BA5dD238BeE2";

export default function Verify({ tokenKey }) {
    const { evmAddress } = useEvmAddress();
    const [ethBalance, setEthBalance] = useState(null);
    const { sendEvmTransaction } = useSendEvmTransaction();
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
        const abi = [{
            name: 'pay',
            type: 'function',
            stateMutability: 'payable',
            inputs: [
                { name: 'tokenIn', type: 'address' },
                { name: 'tokenOut', type: 'address' },
                { name: 'amountIn', type: 'uint256' },
                { name: 'minAmountOut', type: 'uint256' },
            ],
            outputs: [],
        }];

        const data = encodeFunctionData({
            abi,
            functionName: 'pay',
            args: [PYUSD, USDC, parseUnits('1', 6), parseUnits('0.999', 6)],
        });

        try {
            const result = await signEvmTransaction({
                evmAccount: evmAddress,
                transaction: {
                    to: SWAP_CONTRACT,
                    data,
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
        const abi = [{
            name: 'swap',
            type: 'function',
            stateMutability: 'payable',
            inputs: [
                { name: 'tokenIn', type: 'address' },
                { name: 'tokenOut', type: 'address' },
                { name: 'amountIn', type: 'uint256' },
                { name: 'minAmountOut', type: 'uint256' },
            ],
            outputs: [],
        }];

        const data = encodeFunctionData({
            abi,
            functionName: 'swap',
            args: [PYUSD, USDC, 1000n, 800n],
        });

        try {

            const approveData = encodeFunctionData({
                abi: erc20Abi,
                functionName: 'approve',
                args: [SWAP_CONTRACT, 100000000000000000000n], // or a higher allowance
            });
            const approveTx = await sendEvmTransaction({
                evmAccount: evmAddress,
                network: 'ethereum-sepolia',
                transaction: { to: PYUSD, data: approveData, gas: 120000n, chainId: ETH_SEPOLIA_CHAIN_ID, type: 'eip1559' },
            });
            console.log('approve tx hash:', approveTx.transactionHash);

            // simulate
            try {
                await client.simulateContract({
                    address: SWAP_CONTRACT,
                    abi, // pay/swap/addLiquidity ABI
                    functionName: 'swap', // or 'swap'/'addLiquidity'
                    args: [PYUSD, USDC, 1000n, 800n],
                    account: evmAddress,
                    value: 0n,
                });
            } catch (err) {
                console.log(err.shortMessage);
                if (err.data) {
                    try { console.log(decodeErrorResult({ abi, data: err.data })); } catch { }
                }
            }
            // Provide minimal gas hints to help estimators on empty value txs
            const fees = await client.estimateFeesPerGas().catch(() => ({ maxFeePerGas: undefined, maxPriorityFeePerGas: undefined }));
            const result = await sendEvmTransaction({
                evmAccount: evmAddress,
                transaction: {
                    to: SWAP_CONTRACT,
                    data,
                    chainId: ETH_SEPOLIA_CHAIN_ID,
                    type: "eip1559",
                    // let backend pick nonce; provide only gas limit hint
                    gas: 1200000n,
                    // maxFeePerGas: fees.maxFeePerGas,
                    // maxPriorityFeePerGas: fees.maxPriorityFeePerGas,
                },
                network: "ethereum-sepolia",
            });
            console.log("Broadcasted Tx Hash:", result.transactionHash);
        } catch (error) {
            console.error("Failed to send transaction:", error);
        }
    };

    // New: test-only addLiquidity button
    const handleAddLiquidity = async () => {
        if (!evmAddress) return;

        // await client.simulateContract({
        //     address: SWAP_CONTRACT, abi: erc20Abi, functionName: 'approve', args: [SWAP_CONTRACT, 10_000_000n],
        //     account: evmAddress,
        // });
        const approveData = encodeFunctionData({
            abi: erc20Abi,
            functionName: 'approve',
            args: [SWAP_CONTRACT, 1000000000000000000n], // or a higher allowance
        });
        const approveTx = await sendEvmTransaction({
            evmAccount: evmAddress,
            network: 'ethereum-sepolia',
            transaction: { to: USDC, data: approveData, gas: 120000n, chainId: ETH_SEPOLIA_CHAIN_ID, type: 'eip1559' },
        });
        console.log('approve tx hash:', approveTx.transactionHash);




        const addLiquidityAbi = [{
            name: 'addLiquidity',
            type: 'function',
            stateMutability: 'payable',
            inputs: [
                { name: 'amounts', type: 'uint256[]' },
                { name: 'planeConstant', type: 'uint256' },
            ],
            outputs: [],
        }];

        const data = encodeFunctionData({
            abi: addLiquidityAbi,
            functionName: 'addLiquidity',
            args: [[7000000n, 0n, 0n, 0n], 0n],
        });

        try {
            const gas = await client.estimateContractGas({
                address: SWAP_CONTRACT,
                abi: addLiquidityAbi,
                functionName: 'addLiquidity',
                args: [[1n, 0n, 0n, 0n], 0n],
                account: evmAddress,
                value: 0n,
            });
            const gasWithBuffer = (gas * 120n) / 100n;

            const tx = await sendEvmTransaction({
                evmAccount: evmAddress,
                transaction: {
                    to: SWAP_CONTRACT,
                    data,
                    chainId: ETH_SEPOLIA_CHAIN_ID,
                    gas: gasWithBuffer,
                    value: 0n,
                    type: 'eip1559',
                },
                network: 'ethereum-sepolia',
            });
            console.log('addLiquidity tx hash:', tx.transactionHash);
        } catch (error) {
            console.error('Failed to send addLiquidity:', error);
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
            <div className="row" style={{ marginTop: 8, justifyContent: 'space-between', gap: 8, alignItems: 'center' }}>
                <button className="btn" onClick={handleAddLiquidity} disabled={!evmAddress}>Test addLiquidity</button>
                <div className="row" style={{ gap: 8 }}>
                    <button className="btn" onClick={handleSign} disabled={!evmAddress}>Sign only</button>
                    <button className="btn btn-primary" onClick={handleSend} disabled={!evmAddress || (ethBalance !== null && ethBalance === 0n)}>
                        Sign & send
                    </button>
                </div>

            </div>
        </div>
    );
}


