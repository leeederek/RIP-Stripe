import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useIsSignedIn } from '@coinbase/cdp-hooks';
import { createPublicClient, http, formatEther } from 'viem';
import { baseSepolia } from 'viem/chains';

/**
 * Create a viem client to access user's balance on the Base Sepolia network
 */
const client = createPublicClient({
    chain: baseSepolia,
    transport: http(),
});


export default function WalletStatus({ onSignOut, evmAddress }) {
    const { isSignedIn } = useIsSignedIn();
    const addresses = useMemo(() => (Array.isArray(evmAddress) ? evmAddress : evmAddress ? [evmAddress] : []), [evmAddress]);
    const [addressToBalance, setAddressToBalance] = useState({});

    const getBalances = useCallback(async () => {
        if (!addresses.length) return;
        const entries = await Promise.all(
            addresses.map(async (addr) => {
                try {
                    const wei = await client.getBalance({ address: addr });
                    return [addr, wei];
                } catch (e) {
                    return [addr, undefined];
                }
            })
        );
        setAddressToBalance(Object.fromEntries(entries));
    }, [addresses]);

    useEffect(() => {
        getBalances();
        const interval = setInterval(getBalances, 5000);
        return () => clearInterval(interval);
    }, [getBalances]);

    const format = (addr) => {
        const bal = addressToBalance[addr];
        if (bal === undefined) return '…';
        return `${formatEther(bal)} ETH`;
    };

    const shorten = (addr) => (addr && addr.length > 10 ? `${addr.slice(0, 6)}…${addr.slice(-4)}` : addr);

    const statusLabel = isSignedIn ? 'Signed in' : 'Signed out';

    return (
        <div className="stack" style={{ gap: 12 }}>
            <div className="stack">
                <div className="kicker">Wallet</div>
                <h2 style={{ margin: 0 }}>You are signed in</h2>
                <p className="muted" style={{ marginTop: 6 }}>Session is active. Manage your wallet or sign out below.</p>
            </div>

            <div className="card">
                <div className="stack" style={{ gap: 6 }}>
                    <div className="label">Status</div>
                    <div className="row" style={{ alignItems: 'center', gap: 8 }}>
                        <span className="tag">{statusLabel}</span>
                        <span className="helper">Connected wallets: {addresses.length}</span>
                    </div>
                </div>

                <div className="divider" />

                <div className="stack" style={{ gap: 10 }}>
                    <div className="row" style={{ gap: 12, flexWrap: 'wrap' }}>
                        {addresses.map((addr) => (
                            <div key={addr} className="card" style={{ minWidth: 220, flex: '1 1 220px' }}>
                                <div className="stack" style={{ gap: 8 }}>
                                    <div className="row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
                                        <div className="label">Address</div>
                                        <div className="tag">Base Sepolia</div>
                                    </div>
                                    <div style={{ fontWeight: 600 }}>{shorten(addr)}</div>
                                    <div className="divider" />
                                    <div className="label">Balance</div>
                                    <div style={{ fontWeight: 600 }}>{format(addr)}</div>
                                </div>
                            </div>
                        ))}
                        {addresses.length === 0 && (
                            <div className="helper">No addresses available for this session.</div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}


