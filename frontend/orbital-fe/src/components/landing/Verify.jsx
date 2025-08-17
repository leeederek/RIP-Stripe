import React, { useCallback, useMemo, useState } from 'react';
import { useEvmAddress, useGetAccessToken, useSignEvmTransaction } from '@coinbase/cdp-hooks';
import { PYUSD_SEPOLIA_ADDRESS, USDC_BASE_SEPOLIA_ADDRESS, USDC_SEPOLIA_ADDRESS } from './WalletStatus';
import { sendEvmTransaction, signEvmTypedData } from '@coinbase/cdp-core';
import { createPublicClient, decodeErrorResult, encodeFunctionData, erc20Abi, http } from 'viem';
import { sepolia } from 'viem/chains';


const CUSTOM_USDC_ADDRESS = "0xa1DBc4F41540a2aA338e9aD2F5058deF509E1b95"
const CUSTOM_USDT_ADDRESS = "0xC01def8bD0C4C9790199ABa304C944Be9491FCc3"
const CUSTOM_PYUSD_ADDRESS = "0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9"


const SWAP_CONTRACT = '0xBAB68589Ca860B06F839D7Ab41F7d81A7ae5f470';
const ETH_SEPOLIA_CHAIN_ID = 11155111;
const sepoliaClient = createPublicClient({ chain: sepolia, transport: http() });


// Removed unused chain/token constants and viem helpers

// Shared helpers and flow primitives
const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Generate a 32-byte nonce as 0x-prefixed hex (bytes32)
function generateBytes32Nonce() {
    if (typeof crypto !== 'undefined' && crypto.getRandomValues) {
        const bytes = new Uint8Array(32);
        crypto.getRandomValues(bytes);
        return '0x' + Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');
    }
    // Fallback: deterministic padded hex from time (not cryptographically secure)
    const hex = Date.now().toString(16);
    return '0x' + hex.padStart(64, '0');
}

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

    return async function settle({
        accessToken,
        value,
        network = 'base-sepolia', // 'base' or 'base-sepolia'
        chainId = 84532, // 8453 (Base), 84532 (Base Sepolia)
        resource = 'https://api.example.com/premium/resource/123',
        description = 'Premium API access for data analysis',
        mimeType = 'application/json',
        payTo,
        asset,
        maxAmountRequired,
        maxTimeoutSeconds = 10,
        extra = {},
    }) {
        if (!payTo) throw new Error('payTo is required');
        if (!asset) throw new Error('asset is required');
        const nowSeconds = Math.floor(Date.now() / 1000);
        const validAfter = nowSeconds;
        const validBefore = nowSeconds + 600;
        const nonceHex = generateBytes32Nonce();
        const now = Math.floor(Date.now() / 1000);


        const typedData = {
            domain: {
                name: 'USDC',        // match token
                version: '2',        // match token
                chainId,             // e.g., 84532 for Base Sepolia
                verifyingContract: asset, // ERC-20 contract address (must match `asset`)
            },
            types: {
                EIP712Domain: [
                    { name: 'name', type: 'string' },
                    { name: 'version', type: 'string' },
                    { name: 'chainId', type: 'uint256' },
                    { name: 'verifyingContract', type: 'address' },
                ],
                TransferWithAuthorization: [
                    { name: 'from', type: 'address' },
                    { name: 'to', type: 'address' },
                    { name: 'value', type: 'uint256' },
                    { name: 'validAfter', type: 'uint256' },
                    { name: 'validBefore', type: 'uint256' },
                    { name: 'nonce', type: 'bytes32' },
                ],
            },
            primaryType: 'TransferWithAuthorization',
            message: {
                from: evmAddress,
                to: payTo,                 // must equal paymentRequirements.payTo
                value: '1',          // base units (e.g., 1 USDC = "1000000")
                validAfter: String(now),
                validBefore: String(now + 600),
                nonce: nonceHex,           // 32-byte hex
            },
        };

        // 2) Sign typed data
        const { signature } = await signEvmTypedData({ evmAccount: evmAddress, typedData });

        // 3) Build X-PAYMENT header value (base64-encoded JSON)
        function toBase64Json(obj) {
            const json = JSON.stringify(obj);
            return typeof window !== 'undefined' && window.btoa
                ? window.btoa(unescape(encodeURIComponent(json)))
                : Buffer.from(json, 'utf-8').toString('base64');
        }

        const xPaymentHeader = toBase64Json({
            x402Version: 1,
            scheme: 'exact',
            network,
            payload: {
                signature,
                authorization: {
                    from: evmAddress,
                    to: payTo,
                    value: '1',
                    validAfter: String(now),
                    validBefore: String(now + 600),
                    nonce: nonceHex,
                },
            },
        });
        const res = await fetch('http://localhost:8000/verify', {
            headers: { 'X-PAYMENT': xPaymentHeader, 'Accept': 'application/json' },
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

export default function Verify({ tokenKey, getArticle, setDoesHaveAccess }) {
    const settle = useSettleFetch();
    const { evmAddress } = useEvmAddress();
    const stepSimulateTransaction = useCallback(async () => {
        await wait(2000);
        await getArticle();
        setDoesHaveAccess(true);
        return {
            merchantRef: 'CONF-12345',
            status: 'pending',
        };
    }, [getArticle]);

    const handleSwap = async () => {
        if (!evmAddress) return;

        try {
            const approveData = encodeFunctionData({
                abi: erc20Abi,
                functionName: 'approve',
                args: [SWAP_CONTRACT, 100000000000000000000n], // or a higher allowance
            });
            const approveTx = await sendEvmTransaction({
                evmAccount: evmAddress,
                network: 'ethereum-sepolia',
                transaction: { to: CUSTOM_PYUSD_ADDRESS, data: approveData, gas: 120000n, chainId: ETH_SEPOLIA_CHAIN_ID, type: 'eip1559' },
            });
            console.log('approve tx hash:', approveTx.transactionHash);

            const abi = [{
                name: 'swap',
                type: 'function',
                stateMutability: 'payable',
                inputs: [
                    { name: 'tokenIn', type: 'uint256' },
                    { name: 'tokenOut', type: 'uint256' },
                    { name: 'amountIn', type: 'uint256' },
                    { name: 'minAmountOut', type: 'uint256' },
                ],
                outputs: [],
            }];

            const data = encodeFunctionData({
                abi,
                functionName: 'swap',
                args: [2, 0, 1000n, 800n],
            });

            // Provide minimal gas hints to help estimators on empty value txs
            const fees = await sepoliaClient.estimateFeesPerGas().catch(() => ({ maxFeePerGas: undefined, maxPriorityFeePerGas: undefined }));
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

    const stepSettle = useCallback(async () => {
        // await wait(2000);
        const accessToken = await fetch("http://localhost:8000/access-token", {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
        });
        const json = await accessToken.json();
        const res = await settle({
            accessToken: json.access_token,
            value: '1',
            network: 'base-sepolia', // 'base' or 'base-sepolia'
            chainId: 84532, // 8453 (Base), 84532 (Base Sepolia)
            resource: 'http://localhost:8000/get-resource/123',
            description: 'Purcahse of article',
            mimeType: 'application/json',
            payTo: MERCHANT_ADDRESS,
            asset: USDC_BASE_SEPOLIA_ADDRESS,
            extra: {
                gasLimit: "1000000"
            }
        });
        console.log("res", res);
        return;
    }, [settle]);

    // Declarative step config: swap out `run` with real endpoints later
    const steps = useMemo(() => ([
        {
            key: 'swap',
            title: 'Swap',
            description: 'Swapping your original currency to the merchant\'s currency',
            run: handleSwap,
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


