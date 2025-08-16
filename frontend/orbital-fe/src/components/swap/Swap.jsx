import React, { useState } from 'react';
import WalletSummary from '../common/WalletSummary';
import TokenSelect from '../common/TokenSelect';

export default function Swap({ wallet }) {
  const [from, setFrom] = useState('USDC');
  const [to, setTo] = useState('USDT');
  const [amount, setAmount] = useState('100');

  const handleSwap = async () => {
    await new Promise((r) => setTimeout(r, 600));
    alert(`Pretend-swapped ${amount} ${from} → ${to}`);
  };

  return (
    <div className="stack" style={{ gap: 16 }}>
      <WalletSummary wallet={wallet} />
      <div className="card stack">
        <div className="label">Swap from</div>
        <div className="token-row">
          <TokenSelect value={from} onChange={setFrom} include={["USDC","USDT","DAI","PYUSD","USDe","FRAX"]} />
          <input className="input" value={amount} onChange={(e) => setAmount(e.target.value)} />
        </div>
        <div className="divider" />
        <div className="label">To</div>
        <div className="token-row">
          <TokenSelect value={to} onChange={setTo} include={["USDC","USDT","DAI","PYUSD","USDe","FRAX"]} />
          <input className="input" value={((Number(amount) || 0) * 0.999).toFixed(2)} readOnly />
        </div>
        <div className="actions" style={{ marginTop: 10 }}>
          <span className="helper">Rate: 1 {from} ≈ 1 {to} (mock)</span>
          <button className="btn btn-primary" onClick={handleSwap}>Initiate swap</button>
        </div>
      </div>
    </div>
  );
}


