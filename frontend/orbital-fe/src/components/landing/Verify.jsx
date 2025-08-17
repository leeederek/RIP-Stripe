import React, { useCallback, useMemo, useState } from 'react';
import { useEvmAddress, useGetAccessToken, useSignEvmTransaction } from '@coinbase/cdp-hooks';
import { PYUSD_BASE_SEPOLIA_ADDRESS } from './WalletStatus';

// Removed unused chain/token constants and viem helpers

// Shared helpers and flow primitives
const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Individual step executors (replace bodies with real endpoint logic later)
async function stepInitialize() {
    await wait(2000);
    return {
        route: 'Mock DEX route',
        amountIn: '1.00 PYUSD',
        expectedOut: '0.99 USDC',
    };
}

async function stepVerifyWallet() {
    await wait(2000);
    return {
        txHash: '0xabc…1234',
        gasLimit: '120,000',
    };
}

const MERCHANT_ADDRESS = '0x74051bf72a90014a515c511fECFe9811dE138235';


// Removed unused step stubs

// Settles a payment by first signing an EVM tx using the hook, then POSTing to x402/settle
// Usage:
//   const settle = useSettleFetch();
//   await settle({ accessToken, to, valueWei, resource, description, payTo, asset })
// eslint-disable-next-line no-unused-vars
function useSettleFetch() {
    const { evmAddress } = useEvmAddress();
    const { signEvmTransaction } = useSignEvmTransaction();
    const { getAccessToken } = useGetAccessToken();

    return async function settle({
        value,
        network = 'base', // 'base' or 'base-sepolia'
        chainId = 84532, // 8453 (Base), 84532 (Base Sepolia)
        resource = 'https://api.example.com/premium/resource/123',
        description = 'Premium API access for data analysis',
        mimeType = 'application/json',
        payTo,
        asset,
        maxAmountRequired = '0',
        maxTimeoutSeconds = 10,
        extra = {},
    }) {
        const accessToken = await getAccessToken();
        console.log("accessToken", accessToken);
        const nowSeconds = Math.floor(Date.now() / 1000);
        const validAfter = String(nowSeconds);
        const validBefore = String(nowSeconds + 600);
        const nonceHex = '0x' + Date.now().toString(16);

        // Prepare a minimal EIP-1559 transaction to sign
        const txToSign = {
            to: payTo,
            value,
            chainId,
            type: 'eip1559',
        };

        const signed = await signEvmTransaction({
            evmAccount: evmAddress,
            transaction: txToSign,
        });

        const signatureHex = signed?.signedTransaction ?? signed; // hook may return object or raw hex

        const body = {
            x402Version: 1,
            paymentPayload: {
                x402Version: 1,
                scheme: 'exact',
                network,
                payload: {
                    signature: signatureHex,
                    authorization: {
                        from: evmAddress,
                        to: payTo,
                        value: String(value),
                        validAfter,
                        validBefore,
                        nonce: nonceHex,
                    },
                },
            },
            paymentRequirements: {
                scheme: 'exact',
                network,
                maxAmountRequired,
                resource,
                description,
                mimeType,
                outputSchema: { data: 'string' },
                payTo,
                maxTimeoutSeconds,
                asset,
                extra,
            },
        };

        const res = await fetch('https://api.cdp.coinbase.com/platform/v2/x402/settle', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!res.ok) {
            const text = await res.text().catch(() => '');
            throw new Error(`Settle failed (${res.status}): ${text}`);
        }
        return res.json();
    };
}

// Reusable flow hook: drives sequential execution and status updates
function useVerificationFlow(steps) {
    const [statuses, setStatuses] = useState(() => steps.map(() => 'idle'));
    const [isRunning, setIsRunning] = useState(false);
    const [results, setResults] = useState(() => steps.map(() => null));

    const reset = () => {
        setStatuses(steps.map(() => 'idle'));
        setResults(steps.map(() => null));
    };

    const run = async () => {
        if (isRunning) return;
        setIsRunning(true);
        reset();
        try {
            for (let i = 0; i < steps.length; i++) {
                setStatuses((prev) => prev.map((s, idx) => (idx === i ? 'active' : s)));
                const data = await steps[i].run();
                setResults((prev) => prev.map((r, idx) => (idx === i ? data : r)));
                setStatuses((prev) => prev.map((s, idx) => (idx === i ? 'done' : s)));
            }
        } finally {
            setIsRunning(false);
        }
    };

    return { statuses, isRunning, run, reset, results };
}

export default function Verify({ tokenKey, getArticle }) {
    const settle = useSettleFetch();
    const stepSimulateTransaction = useCallback(async () => {
        await wait(2000);
        await getArticle();
        return {
            merchantRef: 'CONF-12345',
            status: 'pending',
        };
    }, [getArticle]);

    const stepSettle = useCallback(async () => {
        const res = await settle({
            value: 1,
            network: 'base-sepolia', // 'base' or 'base-sepolia'
            chainId: 84532, // 8453 (Base), 84532 (Base Sepolia)
            resource: 'http://localhost:8000/get-resource/123',
            description: 'Purcahse of article',
            mimeType: 'application/json',
            payTo: MERCHANT_ADDRESS,
            asset: PYUSD_BASE_SEPOLIA_ADDRESS,
        });
        console.log("res", res);
        return res;
    }, [settle]);

    // Declarative step config: swap out `run` with real endpoints later
    const steps = useMemo(() => ([
        {
            key: 'swap',
            title: 'Swap',
            description: 'Swapping your original currency to the merchant\'s currency',
            run: stepInitialize,
            render: (data) => (
                <div className="stack" style={{ gap: 4 }}>
                    <div className="helper">Route: {data?.route}</div>
                    <div className="helper">In: {data?.amountIn}</div>
                    <div className="helper">Expected out: {data?.expectedOut}</div>
                </div>
            ),
        },
        {
            key: 'settlement',
            title: 'Paying',
            description: 'Sending swapped token to merchant',
            run: stepSettle,
            render: (data) => (
                <div className="stack" style={{ gap: 4 }}>
                    <div className="helper">Tx hash: {data?.txHash}</div>
                    <div className="helper">Gas limit: {data?.gasLimit}</div>
                </div>
            ),
        },
        {
            key: 'verify',
            title: 'Verifying',
            description: 'Verifying the transaction with the merchant',
            run: stepSimulateTransaction,
            render: (data) => (
                <div className="stack" style={{ gap: 4 }}>
                    <div className="helper">Ref: {data?.merchantRef}</div>
                    <div className="helper">Status: {data?.status}</div>
                </div>
            ),
        },
    ]), [stepSimulateTransaction]);

    const { statuses: stepStatuses, isRunning, run, results: stepResults } = useVerificationFlow(steps);

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
            <div className="stack" style={{ gap: 8, marginBottom: 6 }}>
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
                        <div key={idx} className="stack" style={{ gap: 8 }}>
                            <div className="row" style={{ alignItems: 'center', justifyContent: 'space-between' }}>
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
                            {stepResults[idx] ? (
                                <div style={{ paddingLeft: 34 }}>
                                    {typeof step.render === 'function'
                                        ? step.render(stepResults[idx])
                                        : <div className="helper">{JSON.stringify(stepResults[idx])}</div>}
                                </div>
                            ) : null}
                        </div>
                    );
                })}
            </div>

            <div className="row" style={{ marginTop: 14 }}>
                <button
                    className="btn-primary"
                    style={{ flex: 1, marginTop: 12 }}
                    onClick={run}
                    disabled={isRunning}
                >
                    {isRunning ? <span className="spinner spinner-white" aria-label="loading" /> : 'Confirm payment'}
                </button>
            </div>
        </div>
    );
}


