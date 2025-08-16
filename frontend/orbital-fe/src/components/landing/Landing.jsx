import React, { useState } from 'react';
import CreateWalletDialog from './CreateWalletDialog';

export default function Landing({ onConnect, isSignedIn = false, onSignOut }) {
  const [renderCreateWalletDialog, setRenderCreateWalletDialog] = useState(false);

  return (
    <div className="stack" style={{ gap: 16 }}>
      {isSignedIn ? (
        <WalletStatus onSignOut={onSignOut} />
      ) : (
        <SignedOutLanding
          onConnect={onConnect}
          onOpenCreate={() => setRenderCreateWalletDialog(true)}
        />
      )}

      <CreateWalletDialog
        isOpen={renderCreateWalletDialog}
        onClose={() => setRenderCreateWalletDialog(false)}
        onCreate={() => onConnect('create')}
      />
    </div>
  );
}

function SignedOutLanding({ onConnect, onOpenCreate }) {
  return (
    <>
      <div className="stack">
        <div className="kicker">Welcome</div>
        <h2 style={{ margin: 0 }}>Connect or create a wallet</h2>
        <p className="muted" style={{ marginTop: 6 }}>
          All actions are placeholders for the hackathon demo.
        </p>
      </div>

      <div className="row" style={{ marginTop: 4 }}>
        <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => onConnect('connect')}>
          Connect existing wallet
        </button>
        <button className="btn" style={{ flex: 1 }} onClick={onOpenCreate}>
          Create new wallet
        </button>
      </div>

      <div className="card">
        <div className="label">What happens next?</div>
        <div className="stack" style={{ marginTop: 8 }}>
          <div className="helper">• We simulate an async call and then show wallet info</div>
          <div className="helper">• You can try Swap and Liquidity tabs with mock data</div>
        </div>
      </div>
    </>
  );
}

function WalletStatus({ onSignOut }) {
  const mock = {
    address: '0x12a3...9fB2',
    network: 'Base Sepolia',
    balance: '1.23 ETH',
    email: 'user@example.com',
    status: 'Signed in',
  };

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
            <span className="tag">{mock.status}</span>
            <span className="helper">Signed in as {mock.email}</span>
          </div>
        </div>

        <div className="divider" />

        <div className="stack" style={{ gap: 10 }}>
          <div className="row" style={{ gap: 16 }}>
            <div className="stack" style={{ minWidth: 180 }}>
              <div className="label">Address</div>
              <div style={{ fontWeight: 600 }}>{mock.address}</div>
            </div>
            <div className="stack" style={{ minWidth: 160 }}>
              <div className="label">Network</div>
              <div style={{ fontWeight: 600 }}>{mock.network}</div>
            </div>
            <div className="stack" style={{ minWidth: 140 }}>
              <div className="label">Balance</div>
              <div style={{ fontWeight: 600 }}>{mock.balance}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}


