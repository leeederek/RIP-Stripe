import { signEvmTransaction } from '@coinbase/cdp-core';
import { useEvmAddress, useSendEvmTransaction } from '@coinbase/cdp-hooks';
import { createPublicClient, http, formatEther, parseUnits, encodeFunctionData, getAddress, erc20Abi, decodeErrorResult } from 'viem';
import { sepolia } from 'viem/chains';
import React, { useEffect, useMemo, useState } from 'react';

const ETH_SEPOLIA_CHAIN_ID = 11155111;
const PYUSD = getAddress("0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9");
const USDC = getAddress("0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238");
const SWAP_CONTRACT = "0x66Ca370a48f377E6b9D99bF21007BA5dD238BeE2";

// Shared helpers and flow primitives
const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Individual step executors (replace bodies with real endpoint logic later)
async function stepInitialize() {
    await wait(2000);
}

async function stepVerifyWallet() {
    await wait(2000);
}

async function stepSimulateTransaction() {
    await wait(2000);
}

async function stepSignIntent() {
    await wait(2000);
}

async function stepFinalize() {
    await wait(2000);
}

// Reusable flow hook: drives sequential execution and status updates
function useVerificationFlow(steps) {
    const [statuses, setStatuses] = useState(() => steps.map(() => 'idle'));
    const [isRunning, setIsRunning] = useState(false);

    const reset = () => setStatuses(steps.map(() => 'idle'));

    const run = async () => {
        if (isRunning) return;
        setIsRunning(true);
        reset();
        try {
            for (let i = 0; i < steps.length; i++) {
                setStatuses((prev) => prev.map((s, idx) => (idx === i ? 'active' : s)));
                await steps[i].run();
                setStatuses((prev) => prev.map((s, idx) => (idx === i ? 'done' : s)));
            }
        } finally {
            setIsRunning(false);
        }
    };

    return { statuses, isRunning, run, reset };
}

export default function Verify({ tokenKey }) {
    const { evmAddress } = useEvmAddress();
    const [ethBalance, setEthBalance] = useState(null);
    const { sendEvmTransaction } = useSendEvmTransaction();
    const client = useMemo(() => createPublicClient({ chain: sepolia, transport: http() }), []);

    // Declarative step config: swap out `run` with real endpoints later
    const steps = useMemo(() => ([
        { key: 'swap', title: 'Swap', description: 'Swapping your original currency to the merchant\'s currency', run: stepInitialize },
        { key: 'settlement', title: 'Paying', description: 'Sending swapped token to merchant', run: stepVerifyWallet },
        { key: 'verify', title: 'Verifying', description: 'Verifying the transaction with the merchant', run: stepSimulateTransaction },
    ]), []);

    const { statuses: stepStatuses, isRunning, run } = useVerificationFlow(steps);

    // useEffect(() => {
    //     (async () => {
    //         if (!evmAddress) return;
    //         try {
    //             const bal = await client.getBalance({ address: evmAddress });
    //             setEthBalance(bal);
    //         } catch (_) {
    //             setEthBalance(null);
    //         }
    //     })();
    // }, [client, evmAddress]);

    // const handleSign = async () => {
    //     if (!evmAddress) return;
    //     const abi = [{
    //         name: 'pay',
    //         type: 'function',
    //         stateMutability: 'payable',
    //         inputs: [
    //             { name: 'tokenIn', type: 'address' },
    //             { name: 'tokenOut', type: 'address' },
    //             { name: 'amountIn', type: 'uint256' },
    //             { name: 'minAmountOut', type: 'uint256' },
    //         ],
    //         outputs: [],
    //     }];

    //     const data = encodeFunctionData({
    //         abi,
    //         functionName: 'pay',
    //         args: [PYUSD, USDC, parseUnits('1', 6), parseUnits('0.999', 6)],
    //     });

    //     try {
    //         const result = await signEvmTransaction({
    //             evmAccount: evmAddress,
    //             transaction: {
    //                 to: SWAP_CONTRACT,
    //                 data,
    //                 value: 0n,
    //                 chainId: ETH_SEPOLIA_CHAIN_ID,
    //                 type: "eip1559"
    //             }
    //         });
    //         console.log("Signed Transaction:", result.signedTransaction);
    //     } catch (error) {
    //         console.error("Failed to sign transaction:", error);
    //     }
    // };

    // const handleSend = async () => {
    //     if (!evmAddress) return;
    //     const abi = [{
    //         name: 'swap',
    //         type: 'function',
    //         stateMutability: 'payable',
    //         inputs: [
    //             { name: 'tokenIn', type: 'address' },
    //             { name: 'tokenOut', type: 'address' },
    //             { name: 'amountIn', type: 'uint256' },
    //             { name: 'minAmountOut', type: 'uint256' },
    //         ],
    //         outputs: [],
    //     }];

    //     const data = encodeFunctionData({
    //         abi,
    //         functionName: 'swap',
    //         args: [PYUSD, USDC, 1000n, 800n],
    //     });

    //     try {

    //         const approveData = encodeFunctionData({
    //             abi: erc20Abi,
    //             functionName: 'approve',
    //             args: [SWAP_CONTRACT, 100000000000000000000n], // or a higher allowance
    //         });
    //         const approveTx = await sendEvmTransaction({
    //             evmAccount: evmAddress,
    //             network: 'ethereum-sepolia',
    //             transaction: { to: PYUSD, data: approveData, gas: 120000n, chainId: ETH_SEPOLIA_CHAIN_ID, type: 'eip1559' },
    //         });
    //         console.log('approve tx hash:', approveTx.transactionHash);

    //         // simulate
    //         try {
    //             await client.simulateContract({
    //                 address: SWAP_CONTRACT,
    //                 abi, // pay/swap/addLiquidity ABI
    //                 functionName: 'swap', // or 'swap'/'addLiquidity'
    //                 args: [PYUSD, USDC, 1000n, 800n],
    //                 account: evmAddress,
    //                 value: 0n,
    //             });
    //         } catch (err) {
    //             console.log(err.shortMessage);
    //             if (err.data) {
    //                 try { console.log(decodeErrorResult({ abi, data: err.data })); } catch { }
    //             }
    //         }
    //         // Provide minimal gas hints to help estimators on empty value txs
    //         const fees = await client.estimateFeesPerGas().catch(() => ({ maxFeePerGas: undefined, maxPriorityFeePerGas: undefined }));
    //         const result = await sendEvmTransaction({
    //             evmAccount: evmAddress,
    //             transaction: {
    //                 to: SWAP_CONTRACT,
    //                 data,
    //                 chainId: ETH_SEPOLIA_CHAIN_ID,
    //                 type: "eip1559",
    //                 // let backend pick nonce; provide only gas limit hint
    //                 gas: 1200000n,
    //                 // maxFeePerGas: fees.maxFeePerGas,
    //                 // maxPriorityFeePerGas: fees.maxPriorityFeePerGas,
    //             },
    //             network: "ethereum-sepolia",
    //         });
    //         console.log("Broadcasted Tx Hash:", result.transactionHash);
    //     } catch (error) {
    //         console.error("Failed to send transaction:", error);
    //     }
    // };

    // // New: test-only addLiquidity button
    // const handleAddLiquidity = async () => {
    //     if (!evmAddress) return;

    //     // await client.simulateContract({
    //     //     address: SWAP_CONTRACT, abi: erc20Abi, functionName: 'approve', args: [SWAP_CONTRACT, 10_000_000n],
    //     //     account: evmAddress,
    //     // });
    //     const approveData = encodeFunctionData({
    //         abi: erc20Abi,
    //         functionName: 'approve',
    //         args: [SWAP_CONTRACT, 1000000000000000000n], // or a higher allowance
    //     });
    //     const approveTx = await sendEvmTransaction({
    //         evmAccount: evmAddress,
    //         network: 'ethereum-sepolia',
    //         transaction: { to: USDC, data: approveData, gas: 120000n, chainId: ETH_SEPOLIA_CHAIN_ID, type: 'eip1559' },
    //     });
    //     console.log('approve tx hash:', approveTx.transactionHash);




    //     const addLiquidityAbi = [{
    //         name: 'addLiquidity',
    //         type: 'function',
    //         stateMutability: 'payable',
    //         inputs: [
    //             { name: 'amounts', type: 'uint256[]' },
    //             { name: 'planeConstant', type: 'uint256' },
    //         ],
    //         outputs: [],
    //     }];

    //     const data = encodeFunctionData({
    //         abi: addLiquidityAbi,
    //         functionName: 'addLiquidity',
    //         args: [[7000000n, 0n, 0n, 0n], 0n],
    //     });

    //     try {
    //         const gas = await client.estimateContractGas({
    //             address: SWAP_CONTRACT,
    //             abi: addLiquidityAbi,
    //             functionName: 'addLiquidity',
    //             args: [[1n, 0n, 0n, 0n], 0n],
    //             account: evmAddress,
    //             value: 0n,
    //         });
    //         const gasWithBuffer = (gas * 120n) / 100n;

    //         const tx = await sendEvmTransaction({
    //             evmAccount: evmAddress,
    //             transaction: {
    //                 to: SWAP_CONTRACT,
    //                 data,
    //                 chainId: ETH_SEPOLIA_CHAIN_ID,
    //                 gas: gasWithBuffer,
    //                 value: 0n,
    //                 type: 'eip1559',
    //             },
    //             network: 'ethereum-sepolia',
    //         });
    //         console.log('addLiquidity tx hash:', tx.transactionHash);
    //     } catch (error) {
    //         console.error('Failed to send addLiquidity:', error);
    //     }
    // };


    return (
        <div className="card" style={{ padding: 14 }}>
            <div className="stack" style={{ gap: 8 }}>
                <div className="kicker">Confirmation</div>
                <div style={{ fontWeight: 700, fontSize: 18 }}>We're about to send your payment</div>
                <div className="helper">Your original currency will be converted to the merchant's currency</div>
            </div>

            <div className="stack" style={{ gap: 30, marginTop: 12 }}>
                {steps.map((step, idx) => {
                    const status = stepStatuses[idx];
                    const isActive = status === 'active';
                    const isDone = status === 'done';
                    return (
                        <div key={idx} className="row" style={{ alignItems: 'center', justifyContent: 'space-between' }}>
                            <div className="row" style={{ alignItems: 'center', gap: 10 }}>
                                <div className="step-index" aria-label={`step-${idx + 1}`}>{idx + 1}</div>
                                <div className="stack" style={{ gap: 2 }}>
                                    <div style={{ fontWeight: 600 }}>{step.title}</div>
                                    <div className="helper">{step.description}</div>
                                </div>
                            </div>
                            <div>
                                {isActive ? (
                                    <span className="spinner" aria-label="loading" />
                                ) : isDone ? (
                                    <span className="tag" aria-label="done">✓</span>
                                ) : null}
                            </div>
                        </div>
                    );
                })}
            </div>

            <div className="row" style={{ marginTop: 14 }}>
                <button
                    className="btn-primary"
                    style={{ flex: 1 }}
                    onClick={run}
                    disabled={isRunning}
                >
                    {isRunning ? <span className="spinner spinner-white" aria-label="loading" /> : 'Confirm payment'}
                </button>
            </div>
        </div>
    );
}


