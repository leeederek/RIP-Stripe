import React, { useState } from 'react';
import Landing from './landing/Landing';
import Swap from './swap/Swap';
import Liquidity from './liquidity/Liquidity';
import { useIsSignedIn, useSignOut } from '@coinbase/cdp-hooks';

export default function Widget() {
  const [tab, setTab] = useState('wallet');
  const [wallet, setWallet] = useState(null);
  const { isSignedIn } = useIsSignedIn();
  const { signOut } = useSignOut();

  const handleConnect = async () => {
    await new Promise((r) => setTimeout(r, 700));
    setWallet({ address: '0xA1b2...F00D', balance: 1234.56, network: 'Base' });
    setTab('swap');
  };


  return (
    <div className="widget">
      <div className="widget-header">
        <div className="brand"><span className="brand-dot" /> Orbital</div>
        {wallet && (
          <div className="tabs">
            <button className={`tab ${tab === 'wallet' ? 'active' : ''}`} onClick={() => setTab('wallet')}>Wallet</button>
            <button className={`tab ${tab === 'swap' ? 'active' : ''}`} onClick={() => setTab('swap')} disabled={!wallet}>Swap</button>
            <button className={`tab ${tab === 'liquidity' ? 'active' : ''}`} onClick={() => setTab('liquidity')} disabled={!wallet}>Liquidity</button>
          </div>
        )}
      </div>
      <div className="widget-body">
        {tab === 'wallet' && (<Landing onConnect={handleConnect} isSignedIn={isSignedIn} onSignOut={signOut} />)}
        {tab === 'swap' && wallet && (<Swap wallet={wallet} />)}
        {tab === 'liquidity' && wallet && (<Liquidity wallet={wallet} />)}
      </div>
      <div className="footer-cta" style={{ justifyContent: wallet ? 'space-between' : 'flex-end' }}>
        {isSignedIn ? (
          <>
            <button className="btn" onClick={signOut}>Sign out</button>
          </>
        ) : null}
      </div>
    </div>
  );
}


