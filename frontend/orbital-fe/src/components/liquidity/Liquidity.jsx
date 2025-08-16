import React, { useState } from 'react';
import WalletSummary from '../common/WalletSummary';
import { TOKENS } from '../../constants/tokens';

export default function Liquidity({ wallet }) {
  const [selected, setSelected] = useState(['USDC', 'USDT']);
  const [fee, setFee] = useState('0.05');
  const [boundary, setBoundary] = useState('small');

  const toggle = (symbol) => {
    setSelected((prev) => (prev.includes(symbol) ? prev.filter((s) => s !== symbol) : [...prev, symbol]));
  };

  const submit = async () => {
    await new Promise((r) => setTimeout(r, 700));
    alert(`Created mock LP with [${selected.join(', ')}], fee ${fee}% and boundary ${boundary}.`);
  };

  return (
    <div className="stack" style={{ gap: 16 }}>
      <WalletSummary wallet={wallet} />

      <div className="card stack">
        <div className="label">Select stablecoins</div>
        <div className="chip-group">
          {TOKENS.map((t) => (
            <button
              key={t.symbol}
              className={`chip ${selected.includes(t.symbol) ? 'active' : ''}`}
              onClick={() => toggle(t.symbol)}
            >
              {t.symbol}
              {t.genius ? (
                <span className="tag" style={{ marginLeft: 8 }}>GENIUS</span>
              ) : (
                <span className="tag warning" style={{ marginLeft: 8 }}>Non-compliant</span>
              )}
            </button>
          ))}
        </div>
        <div className="helper">Pick any number of tokens. Some are labelled as GENIUS compliant.</div>
      </div>

      <div className="card stack">
        <div className="label">Liquidity boundary</div>
        <div className="chip-group">
          <button className={`chip ${boundary === 'small' ? 'active' : ''}`} onClick={() => setBoundary('small')}>
            Small: $0.999 ≥ x ≥ $1.001
          </button>
          <button className={`chip ${boundary === 'medium' ? 'active' : ''}`} onClick={() => setBoundary('medium')}>
            Medium: $0.995 ≥ x ≥ $1.005
          </button>
          <button className={`chip ${boundary === 'large' ? 'active' : ''}`} onClick={() => setBoundary('large')}>
            Large: $0.99 ≥ x ≥ $1.01
          </button>
        </div>
        <div className="helper">
          {boundary === 'small' && 'Steady fees, typically lower fee tier due to lower risk.'}
          {boundary === 'medium' && 'More exotic and risky; can command higher fees with less volume.'}
          {boundary === 'large' && 'Captures large fees if a depeg happens. Most risky.'}
        </div>
      </div>

      <div className="card stack">
        <div className="label">Fee tier</div>
        <div className="chip-group">
          {['0.01', '0.02', '0.05', '0.1'].map((opt) => (
            <button key={opt} className={`chip ${fee === opt ? 'active' : ''}`} onClick={() => setFee(opt)}>
              {opt}%
            </button>
          ))}
          <input
            className="chip-input"
            placeholder="Custom %"
            onChange={(e) => setFee(e.target.value)}
            style={{ maxWidth: 120 }}
          />
        </div>
      </div>

      <div className="actions">
        <span className="helper">You will be providing liquidity for: {selected.join(', ') || 'None'}</span>
        <button className="btn btn-primary" onClick={submit}>Create position</button>
      </div>
    </div>
  );
}


