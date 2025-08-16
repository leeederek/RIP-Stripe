import React from 'react';

export default function WalletSummary({ wallet }) {
  if (!wallet) return null;
  return (
    <div className="row" style={{ gap: 12 }}>
      <div className="card" style={{ flex: 1 }}>
        <div className="label">Address</div>
        <div style={{ marginTop: 6 }}>{wallet.address}</div>
      </div>
      <div className="card" style={{ width: 160 }}>
        <div className="label">Balance</div>
        <div style={{ marginTop: 6 }}>${wallet.balance.toLocaleString()}</div>
      </div>
      <div className="card" style={{ width: 120 }}>
        <div className="label">Network</div>
        <div style={{ marginTop: 6 }}>{wallet.network}</div>
      </div>
    </div>
  );
}


