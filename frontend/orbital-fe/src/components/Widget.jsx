import React, { useState } from 'react';
import Coinbase from '../assets/svgs/coinbase';
import Privy from '../assets/svgs/privy';
import CreateWalletStep from './landing/CreateWalletStep';
// Removed Swap and Liquidity views for checkout-focused widget
import { useIsSignedIn, useSignOut } from '@coinbase/cdp-hooks';

export default function Widget() {
  const { isSignedIn } = useIsSignedIn();
  const { signOut } = useSignOut();

  // placeholder for future connect flow

  // Inline carousel state (0: payment method, 1: email/otp)
  const [pageIndex, setPageIndex] = useState(0);
  const [slidesOpacity, setSlidesOpacity] = useState(1);
  const [method, setMethod] = useState('coinbase');

  const goTo = (idx) => {
    setSlidesOpacity(0.6);
    requestAnimationFrame(() => {
      setPageIndex(idx);
      requestAnimationFrame(() => setSlidesOpacity(1));
    });
  };


  return (
    <div className="widget">
      <div className="widget-header">
        <div className="brand"><span className="brand-dot" /> Orbital Pay</div>
      </div>
      <div className="widget-body">
        <div className="stack" style={{ gap: 8, marginBottom: 12 }}>
          <div className="kicker">Checkout</div>
          <div style={{ fontSize: 20, fontWeight: 700 }}>Unlock this article</div>
          <div className="row" style={{ alignItems: 'center', justifyContent: 'space-between' }}>
            <div className="helper">Full access immediately after payment</div>
            <span className="tag warning" aria-label="Price tag">$1.00</span>
          </div>
          <div className="card" style={{ padding: 12 }}>
            <div className="row" style={{ alignItems: 'center', justifyContent: 'space-between' }}>
              <div className="stack" style={{ gap: 4 }}>
                <div className="label">Item</div>
                <div style={{ fontWeight: 600 }}>Orbital Daily — Article unlock</div>
              </div>
              <div className="stack" style={{ textAlign: 'right' }}>
                <div className="label">Total</div>
                <div style={{ fontWeight: 700, fontSize: 18 }}>$1.00</div>
              </div>
            </div>
          </div>
        </div>
        {/* Inline carousel */}
        <div style={{ overflow: 'hidden', width: '100%', marginTop: 6 }}>
          <div
            style={{
              display: 'flex',
              width: '200%',
              transition: 'transform 280ms ease, opacity 280ms ease',
              transform: pageIndex === 0 ? 'translateX(0%)' : 'translateX(-50%)',
              opacity: slidesOpacity,
            }}
          >
            <div style={{ width: '50%', boxSizing: 'border-box', paddingRight: 0 }}>
              <PaymentMethodStep
                method={method}
                setMethod={setMethod}
                onConnect={() => goTo(1)}
                onCreate={() => goTo(1)}
              />
            </div>
            <div style={{ width: '50%', boxSizing: 'border-box', paddingLeft: 0 }}>
              <CreateWalletStep
                method={method}
                onBack={() => goTo(0)}
                onContinue={() => goTo(0)}
              />
            </div>
          </div>
        </div>
      </div>
      <div className="footer-cta" style={{ justifyContent: isSignedIn ? 'space-between' : 'flex-end' }}>
        {isSignedIn ? (
          <>
            <button className="btn" onClick={signOut}>Sign out</button>
          </>
        ) : null}
      </div>
    </div>
  );
}

function PaymentMethodStep({ method, setMethod, onConnect, onCreate }) {
  return (
    <div className="stack" style={{ gap: 16 }}>
      <div className="stack">
        <div className="kicker">Payment method</div>
        <h2 style={{ margin: 0 }}>Choose how you'd like to pay</h2>
        <p className="muted" style={{ marginTop: 6 }}>Select an option below, then sign in or create a wallet to pay $1 and unlock the article.</p>
      </div>

      <div className="row" style={{ gap: 12 }}>
        <div
          className="card-interactable"
          onClick={() => setMethod('coinbase')}
          style={{ borderColor: method === 'coinbase' ? 'rgba(124, 92, 255, 0.45)' : undefined, flex: 1 }}
        >
          <div className="row" style={{ alignItems: 'center', gap: 10 }}>
            <Coinbase />
            <div className="stack" style={{ gap: 2 }}>
              <div style={{ fontWeight: 600 }}>Coinbase (email)</div>
              <div className="helper">Fast sign-in and embedded wallet</div>
            </div>
          </div>
        </div>
        <div
          className="card-interactable"
          onClick={() => setMethod('privy')}
          style={{ borderColor: method === 'privy' ? 'rgba(124, 92, 255, 0.45)' : undefined, flex: 1 }}
        >
          <div className="row" style={{ alignItems: 'center', gap: 10 }}>
            <Privy />
            <div className="stack" style={{ gap: 2 }}>
              <div style={{ fontWeight: 600 }}>Privy (email)</div>
              <div className="helper">Email-first wallet with quick setup</div>
            </div>
          </div>
        </div>
        <div
          className="card-interactable"
          onClick={() => setMethod('hardware')}
          style={{ borderColor: method === 'hardware' ? 'rgba(124, 92, 255, 0.45)' : undefined, flex: 1 }}
        >
          <div className="row" style={{ alignItems: 'center', gap: 10 }}>
            <div className="tag">USB</div>
            <div className="stack" style={{ gap: 2 }}>
              <div style={{ fontWeight: 600 }}>Hardware wallet</div>
              <div className="helper">Connect Ledger or Trezor</div>
            </div>
          </div>
        </div>
      </div>

      <div className="row" style={{ marginTop: 4 }}>
        <button className="btn btn-primary" style={{ flex: 1 }} onClick={onConnect}>
          Sign in to pay $1
        </button>
        <button className="btn" style={{ flex: 1 }} onClick={onCreate}>
          Create wallet to pay $1
        </button>
      </div>

      <div className="card">
        <div className="label">Summary</div>
        <div className="stack" style={{ marginTop: 8 }}>
          <div className="helper">• Total due: $1.00</div>
          <div className="helper">• Paying with: {method === 'coinbase' ? 'Coinbase (email)' : method === 'privy' ? 'Privy (email)' : 'Hardware wallet'}</div>
          <div className="helper">• Secure on-chain checkout; access unlocks immediately after payment</div>
        </div>
      </div>
    </div>
  );
}


