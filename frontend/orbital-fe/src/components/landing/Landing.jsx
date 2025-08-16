import React from 'react';

export default function Landing({ onConnect }) {
  return (
    <div className="stack" style={{ gap: 16 }}>
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
        <button className="btn" style={{ flex: 1 }} onClick={() => onConnect('create')}>
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
    </div>
  );
}


