import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useIsSignedIn } from '@coinbase/cdp-hooks';
import { createPublicClient, http, formatEther, formatUnits } from 'viem';
import { sepolia } from 'viem/chains';

const PYUSD_SEPOLIA_ADDRESS = '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9';
const USDC_SEPOLIA_ADDRESS = '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238';
const LINK_SEPOLIA_ADDRESS = '0xCD85B9a767eF2277E264A4B9A14a2deACAB82FfB';

const TOKENS = [
    { key: 'pyusd', address: PYUSD_SEPOLIA_ADDRESS },
    { key: 'usdc', address: USDC_SEPOLIA_ADDRESS },
    { key: 'link', address: LINK_SEPOLIA_ADDRESS },
];
const erc20MinimalAbi = [
    { name: 'balanceOf', type: 'function', stateMutability: 'view', inputs: [{ name: 'owner', type: 'address' }], outputs: [{ type: 'uint256' }] },
    { name: 'decimals', type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint8' }] },
    { name: 'symbol', type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'string' }] },
];
/**
 * Create a viem client to access user's balance on the Base Sepolia network
 */
const client = createPublicClient({ chain: sepolia, transport: http() });


export default function WalletStatus({ onSignOut, evmAddress, onContinue }) {
    const { isSignedIn } = useIsSignedIn();
    const addresses = useMemo(() => (Array.isArray(evmAddress) ? evmAddress : evmAddress ? [evmAddress] : []), [evmAddress]);
    console.log(addresses);
    const [addressToBalances, setAddressToBalances] = useState({});
    const [tokenMetaMap, setTokenMetaMap] = useState({}); // address -> { symbol, decimals }
    const [selectedTokenKey, setSelectedTokenKey] = useState(null);

    const getBalances = useCallback(async () => {
        if (!addresses.length) return;
        // Ensure token metadata is loaded (symbol/decimals for each token)
        const missingMeta = TOKENS.filter(t => !tokenMetaMap[t.address]);
        if (missingMeta.length) {
            try {
                const metas = await Promise.all(
                    missingMeta.map(async (t) => {
                        const [decimals, symbol] = await Promise.all([
                            client.readContract({ address: t.address, abi: erc20MinimalAbi, functionName: 'decimals' }),
                            client.readContract({ address: t.address, abi: erc20MinimalAbi, functionName: 'symbol' }),
                        ]);
                        return [t.address, { decimals, symbol }];
                    })
                );
                setTokenMetaMap((prev) => ({ ...prev, ...Object.fromEntries(metas) }));
            } catch (_) {
                // ignore meta failures; balances will still fetch but formatting may be off
            }
        }

        const entries = await Promise.all(
            addresses.map(async (addr) => {
                try {
                    const [wei, tokenBalances] = await Promise.all([
                        client.getBalance({ address: addr }),
                        Promise.all(
                            TOKENS.map(async (t) => {
                                const bal = await client.readContract({ address: t.address, abi: erc20MinimalAbi, functionName: 'balanceOf', args: [addr] });
                                return [t.address, bal];
                            })
                        ),
                    ]);
                    return [addr, { wei, tokens: Object.fromEntries(tokenBalances) }];
                } catch (e) {
                    return [addr, { wei: undefined, tokens: {} }];
                }
            })
        );
        setAddressToBalances(Object.fromEntries(entries));
    }, [addresses, tokenMetaMap]);

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
        const token = typeof tokenAddressOrToken === 'string' ? TOKENS.find(t => t.address === tokenAddressOrToken) : tokenAddressOrToken;
        const tokenAddress = token.address;
        const meta = tokenMetaMap[tokenAddress] || { symbol: 'Token', decimals: 18 };
        const bal = addressToBalances[addr]?.tokens?.[tokenAddress];
        const formatted = bal === undefined ? '…' : `${formatUnits(bal, meta.decimals)} ${meta.symbol}`;
        const isSelected = selectedTokenKey === token.key;
        return (
            <div
                className="card-interactable"
                style={{ width: 'calc(50% - 5px)', maxWidth: 'calc(50% - 5px)', flex: '0 0 calc(50% - 5px)', boxSizing: 'border-box', borderColor: isSelected ? 'rgba(124, 92, 255, 0.45)' : undefined }}
                key={`${addr}-${tokenAddress}`}
                onClick={() => setSelectedTokenKey(token.key)}
                role="button"
                aria-pressed={isSelected}
            >
                <div className="stack" style={{ gap: 8 }}>
                    <div className="stack" style={{ gap: 2 }}>
                        <div className="row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
                            <div className="label">Token</div>
                            <div className="tag-absolute">Sepolia</div>
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
                        <span className="helper">Connected wallets: {addresses.length}</span>
                    </div>
                </div>

                <div className="divider" />

                <div className="stack" style={{ gap: 10 }}>
                    <div className="row" style={{ gap: 10, flexWrap: 'wrap' }}>
                        {addresses.map((addr) => (
                            <React.Fragment key={addr}>
                                <div style={{ width: '100%', flex: '1 1 100%', padding: '2px 0' }}>
                                    <div className="row" style={{ alignItems: 'baseline', justifyContent: 'space-between', gap: 12 }}>
                                        <div className="stack" style={{ gap: 2 }}>
                                            <div className="label">Address</div>
                                            <div className="helper" style={{ fontWeight: 600 }}>{shorten(addr)}</div>
                                        </div>
                                        <div className="stack" style={{ gap: 2, textAlign: 'right' }}>
                                            <div className="label">Balance</div>
                                            <div className="helper" style={{ fontWeight: 600 }}>{formatEth(addr)}</div>
                                        </div>
                                    </div>
                                </div>
                                {TOKENS.map((t) => renderTokenCard(addr, t))}
                            </React.Fragment>
                        ))}
                        {addresses.length === 0 && (
                            <div className="helper">No addresses available for this session.</div>
                        )}
                    </div>
                    {selectedTokenKey && (
                        <div className="row" style={{ justifyContent: 'flex-end', marginTop: 6 }}>
                            <button className="btn btn-primary" onClick={() => onContinue?.(selectedTokenKey)}>
                                Continue with {(() => { const sel = TOKENS.find(t => t.key === selectedTokenKey); const sym = sel && tokenMetaMap[sel.address]?.symbol; return sym || selectedTokenKey?.toUpperCase(); })()}
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}


