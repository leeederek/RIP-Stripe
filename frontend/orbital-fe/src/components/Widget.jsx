import React, { useState } from 'react';
import Landing from './landing/Landing';
import Swap from './swap/Swap';
import Liquidity from './liquidity/Liquidity';

export default function Widget() {
  const [tab, setTab] = useState('wallet');
  const [wallet, setWallet] = useState(null);

  const handleConnect = async () => {
    await new Promise((r) => setTimeout(r, 700));
    setWallet({ address: '0xA1b2...F00D', balance: 1234.56, network: 'Base' });
    setTab('swap');
  };

  return (
    <div className="widget">
      <div className="widget-header">
        <div className="brand"><span className="brand-dot" /> Orbital</div>
        <div className="tabs">
          <button className={`tab ${tab === 'wallet' ? 'active' : ''}`} onClick={() => setTab('wallet')}>Wallet</button>
          <button className={`tab ${tab === 'swap' ? 'active' : ''}`} onClick={() => setTab('swap')} disabled={!wallet}>Swap</button>
          <button className={`tab ${tab === 'liquidity' ? 'active' : ''}`} onClick={() => setTab('liquidity')} disabled={!wallet}>Liquidity</button>
        </div>
      </div>
      <div className="widget-body">
        {tab === 'wallet' && (<Landing onConnect={handleConnect} />)}
        {tab === 'swap' && wallet && (<Swap wallet={wallet} />)}
        {tab === 'liquidity' && wallet && (<Liquidity wallet={wallet} />)}
      </div>
      <div className="footer-cta">
        {!wallet ? (
          <button className="btn btn-primary" onClick={handleConnect}>Get Started</button>
        ) : (
          <button className="btn btn-primary" onClick={async () => { await new Promise(r => setTimeout(r, 400)); }}>Continue</button>
        )}
      </div>
    </div>
  );
}


