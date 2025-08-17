import React, { useState } from 'react';
import CreateWalletDialog from './CreateWalletDialog';
import Coinbase from '../../assets/svgs/coinbase';
import Privy from '../../assets/svgs/privy';
import WalletStatus from './WalletStatus';
import { useCurrentUser, useEvmAddress, useIsSignedIn } from '@coinbase/cdp-hooks';

export default function Landing({ onConnect, onSignOut }) {
  const [renderCreateWalletDialog, setRenderCreateWalletDialog] = useState(false);
  const [selectedMethod, setSelectedMethod] = useState('coinbase');

  // coinbase
  const { isSignedIn } = useIsSignedIn();
  const { currentUser } = useCurrentUser();
  const { evmAddress } = useEvmAddress();
  console.log('evmAddress', evmAddress);
  console.log('currentUser', currentUser);

  return (
    <div className="stack" style={{ gap: 16 }}>
      {isSignedIn && currentUser ? (
        <WalletStatus onSignOut={onSignOut} userId={currentUser.id} evmAddress={currentUser.evmAccounts} />
      ) : (
        <SignedOutLanding
          onConnect={onConnect}
          method={selectedMethod}
          setMethod={setSelectedMethod}
          onOpenCreate={() => setRenderCreateWalletDialog(true)}
        />
      )}

      <CreateWalletDialog
        isOpen={renderCreateWalletDialog}
        onClose={() => setRenderCreateWalletDialog(false)}
        onCreate={() => onConnect('create')}
        initialMethod={selectedMethod}
      />
    </div>
  );
}

function SignedOutLanding({ onConnect, onOpenCreate, method, setMethod }) {
  return (
    <>
      <div className="stack">
        <div className="kicker">Payment method</div>
        <h2 style={{ margin: 0 }}>Choose how you'd like to pay</h2>
        <p className="muted" style={{ marginTop: 6 }}>Select an option below, then sign in or create a wallet to pay 1 USDC and unlock the article.</p>
      </div>

      <div className="row" style={{ gap: 12 }}>
        <div
          className="card-interactable"
          onClick={() => setMethod('coinbase')}
          style={{ borderColor: method === 'coinbase' ? 'rgba(124, 92, 255, 0.45)' : undefined }}
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
          style={{ borderColor: method === 'privy' ? 'rgba(124, 92, 255, 0.45)' : undefined }}
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
          style={{ borderColor: method === 'hardware' ? 'rgba(124, 92, 255, 0.45)' : undefined }}
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
        <button className="btn-primary" style={{ flex: 1 }} onClick={() => onConnect('connect')}>
          Sign in to pay 1 USDC
        </button>
        <button className="btn" style={{ flex: 1 }} onClick={onOpenCreate}>
          Create wallet to pay 1 USDC
        </button>
      </div>

      <div className="card">
        <div className="label">Summary</div>
        <div className="stack" style={{ marginTop: 8 }}>
          <div className="helper">• Total due: 1 USDC</div>
          <div className="helper">• Paying with: {method === 'coinbase' ? 'Coinbase (email)' : method === 'privy' ? 'Privy (email)' : 'Hardware wallet'}</div>
          <div className="helper">• Secure on-chain checkout; access unlocks immediately after payment</div>
        </div>
      </div>
    </>
  );
}
