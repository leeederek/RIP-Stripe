import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useIsSignedIn } from '@coinbase/cdp-hooks';
import { createPublicClient, http, formatEther, formatUnits } from 'viem';
import { baseSepolia, sepolia } from 'viem/chains';

export const PYUSD_SEPOLIA_ADDRESS = '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9';
export const USDC_SEPOLIA_ADDRESS = '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238';
export const LINK_SEPOLIA_ADDRESS = '0xCD85B9a767eF2277E264A4B9A14a2deACAB82FfB';

// Base Sepolia token addresses
// USDC source: Circle developers documentation (Base Sepolia)
export const USDC_BASE_SEPOLIA_ADDRESS = '0x036CbD53842c5426634e7929541eC2318f3dCF7e';
// PYUSD is not officially deployed on Base Sepolia as of now
export const PYUSD_BASE_SEPOLIA_ADDRESS = null;
// LINK ERC-20 is not officially listed on Base Sepolia as of now
export const LINK_BASE_SEPOLIA_ADDRESS = null;

const TOKENS = [
    { key: 'pyusd', address: PYUSD_SEPOLIA_ADDRESS, network: "Sepolia" },
    { key: 'usdc', address: USDC_SEPOLIA_ADDRESS, network: "Sepolia" },
    { key: 'link', address: LINK_SEPOLIA_ADDRESS, network: "Sepolia" },
];

const BASE_SEPOLIA_TOKENS = [
    { key: 'usdc-base', address: USDC_BASE_SEPOLIA_ADDRESS, network: "Base Sepolia" },
];

const erc20MinimalAbi = [
    { name: 'balanceOf', type: 'function', stateMutability: 'view', inputs: [{ name: 'owner', type: 'address' }], outputs: [{ type: 'uint256' }] },
    { name: 'decimals', type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint8' }] },
    { name: 'symbol', type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'string' }] },
];
/**
 * Create a viem client to access user's balance on the Base Sepolia network
 */
const sepoliaClient = createPublicClient({ chain: sepolia, transport: http() });

const baseSepoliaClient = createPublicClient({ chain: baseSepolia, transport: http() });

const getTokenKey = (token) => `${token.network}:${token.address}`;
const getClientForToken = (token) => (token.network === 'Base Sepolia' ? baseSepoliaClient : sepoliaClient);

const getNetworkTagStyle = (network) => {
    if (network === 'Base Sepolia') {
        // Stronger blue with darker text for readability
        return { backgroundColor: '#DBEAFE', color: '#0B3B8A', fontWeight: 600 };
    }
    // Stronger purple with darker text for readability (Sepolia)
    return { backgroundColor: '#E9D5FF', color: '#4C1D95', fontWeight: 600 };
};


export default function WalletStatus({ onSignOut, evmAddress, onContinue, setDoesHaveAccess }) {
    const { isSignedIn } = useIsSignedIn();
    const address = useMemo(() => (typeof evmAddress === 'string' ? evmAddress : null), [evmAddress]);
    const [addressToBalances, setAddressToBalances] = useState({});
    const [tokenMetaMap, setTokenMetaMap] = useState({}); // address -> { symbol, decimals }
    const [selectedTokenKey, setSelectedTokenKey] = useState(null);
    const [copied, setCopied] = useState(false);

    const copyFullAddress = useCallback(async () => {
        if (!address) return;
        try {
            if (navigator?.clipboard?.writeText) {
                await navigator.clipboard.writeText(address);
            } else {
                const textArea = document.createElement('textarea');
                textArea.value = address;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
            }
            setCopied(true);
            setTimeout(() => setCopied(false), 1200);
        } catch (_) {
            // no-op on failure
        }
    }, [address]);

    const getBalances = useCallback(async () => {
        if (!address) return;
        // Ensure token metadata is loaded (symbol/decimals for each token across networks)
        const allTokens = [...TOKENS, ...BASE_SEPOLIA_TOKENS];
        const missingMeta = allTokens.filter((t) => !tokenMetaMap[getTokenKey(t)]);
        if (missingMeta.length) {
            try {
                const metas = await Promise.all(
                    missingMeta.map(async (t) => {
                        const client = getClientForToken(t);
                        const [decimals, symbol] = await Promise.all([
                            client.readContract({ address: t.address, abi: erc20MinimalAbi, functionName: 'decimals' }),
                            client.readContract({ address: t.address, abi: erc20MinimalAbi, functionName: 'symbol' }),
                        ]);
                        return [getTokenKey(t), { decimals, symbol }];
                    })
                );
                setTokenMetaMap((prev) => ({ ...prev, ...Object.fromEntries(metas) }));
            } catch (_) {
                // ignore meta failures; balances will still fetch but formatting may be off
            }
        }

        try {
            const [wei, tokenBalances] = await Promise.all([
                sepoliaClient.getBalance({ address }),
                Promise.all(
                    [...TOKENS, ...BASE_SEPOLIA_TOKENS].map(async (t) => {
                        const client = getClientForToken(t);
                        const bal = await client.readContract({ address: t.address, abi: erc20MinimalAbi, functionName: 'balanceOf', args: [address] });
                        return [getTokenKey(t), bal];
                    })
                ),
            ]);
            setAddressToBalances({ [address]: { wei, tokens: Object.fromEntries(tokenBalances) } });
        } catch (e) {
            setAddressToBalances({ [address]: { wei: undefined, tokens: {} } });
        }
    }, [address, tokenMetaMap]);

    useEffect(() => {
        getBalances();
        const interval = setInterval(getBalances, 5000);
        return () => clearInterval(interval);
    }, [getBalances]);

    const formatEth = (addr) => {
        const bal = addressToBalances[addr]?.wei;
        if (bal === undefined) return '…';
        return `${formatEther(bal)} ETH`;
    };

    const renderTokenCard = (addr, tokenAddressOrToken) => {
        const allTokens = [...TOKENS, ...BASE_SEPOLIA_TOKENS];
        const token = typeof tokenAddressOrToken === 'string' ? allTokens.find(t => t.address === tokenAddressOrToken) : tokenAddressOrToken;
        const keyForMeta = getTokenKey(token);
        const meta = tokenMetaMap[keyForMeta] || { symbol: 'Token', decimals: 18 };
        const bal = addressToBalances[addr]?.tokens?.[keyForMeta];
        const formatted = bal === undefined ? '…' : `${formatUnits(bal, meta.decimals)} ${meta.symbol}`;
        const isSelected = selectedTokenKey === token.key;
        return (
            <div
                className="card-interactable"
                style={{ width: 'calc(50% - 5px)', maxWidth: 'calc(50% - 5px)', flex: '0 0 calc(50% - 5px)', boxSizing: 'border-box', borderColor: isSelected ? 'rgba(124, 92, 255, 0.45)' : undefined }}
                key={`${addr}-${keyForMeta}`}
                onClick={() => setSelectedTokenKey(token.key)}
                role="button"
                aria-pressed={isSelected}
            >
                <div className="stack" style={{ gap: 8 }}>
                    <div className="stack" style={{ gap: 2 }}>
                        <div className="row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
                            <div className="label">Token</div>
                            <div className="tag-absolute" style={getNetworkTagStyle(token.network)}>{token.network}</div>
                        </div>
                        <div style={{ fontWeight: 600 }}>{meta.symbol}</div>
                    </div>
                    <div className="divider" style={{ margin: '4px 0' }} />
                    <div className="stack" style={{ gap: 2 }}>
                        <div className="label">Balance</div>
                        <div style={{ fontWeight: 600 }}>{formatted}</div>
                    </div>
                </div>
            </div>
        );
    };

    const shorten = (addr) => (addr && addr.length > 10 ? `${addr.slice(0, 6)}…${addr.slice(-4)}` : addr);

    const statusLabel = isSignedIn ? 'Signed in' : 'Signed out';

    return (
        <div className="stack" style={{ gap: 6, marginTop: 16 }}>
            <div className="stack" style={{ gap: 6 }}>
                <div className="kicker">Wallet</div>
                <div style={{ fontSize: 20, fontWeight: 700 }}>You are signed in</div>
                <div className="helper" style={{ marginTop: 0, marginBottom: 8 }}>Select a stable coin to pay with</div>
            </div>

            <div className="card" style={{ padding: '14px' }}>
                <div className="stack" style={{ gap: 6 }}>
                    <div className="label">Status</div>
                    <div className="row" style={{ alignItems: 'center', gap: 8 }}>
                        <span className="tag">{statusLabel}</span>
                        <span className="helper">Connected wallets: {address ? 1 : 0}</span>
                    </div>
                </div>

                <div className="divider" />

                <div className="stack" style={{ gap: 10 }}>
                    <div className="row" style={{ gap: 10, flexWrap: 'wrap' }}>
                        {address ? (
                            <>
                                <div style={{ width: '100%', flex: '1 1 100%', padding: '2px 0' }}>
                                    <div className="row" style={{ alignItems: 'baseline', justifyContent: 'space-between', gap: 12 }}>
                                        <div className="stack" style={{ gap: 2 }}>
                                            <div className="label">Address</div>
                                            <div className="row" style={{ alignItems: 'center', gap: 8 }}>
                                                <div className="helper" style={{ fontWeight: 600 }}>{shorten(address)}</div>
                                                <button
                                                    className="btn"
                                                    onClick={copyFullAddress}
                                                    aria-label="Copy address to clipboard"
                                                    title="Copy full address"
                                                    style={{ padding: '2px 6px', fontSize: 11 }}
                                                >
                                                    {copied ? 'Copied' : 'Copy'}
                                                </button>
                                            </div>
                                        </div>
                                        <div className="stack" style={{ gap: 2, textAlign: 'right' }}>
                                            <div className="label">Balance</div>
                                            <div className="helper" style={{ fontWeight: 600 }}>{formatEth(address)}</div>
                                        </div>
                                    </div>
                                </div>
                                {TOKENS.map((t) => renderTokenCard(address, t))}
                                {BASE_SEPOLIA_TOKENS.map((t) => renderTokenCard(address, t))}
                            </>
                        ) : (
                            <div className="helper">No address available for this session.</div>
                        )}
                    </div>
                    {selectedTokenKey && (
                        <div className="row" style={{ justifyContent: 'flex-end', marginTop: 6 }}>
                            <button className="btn-primary" onClick={() => onContinue?.(selectedTokenKey)}>
                                Continue with {(() => { const sel = [...TOKENS, ...BASE_SEPOLIA_TOKENS].find(t => t.key === selectedTokenKey); const sym = sel && tokenMetaMap[getTokenKey(sel)]?.symbol; return sym || selectedTokenKey?.toUpperCase(); })()}
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}


