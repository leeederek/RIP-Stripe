import React from 'react';

export default function MarketsWeekly() {
    return (
        <div style={styles.page}>
            <div style={styles.container}>
                <header style={styles.header}>
                    <div className="brand"><span className="brand-dot" /> Orbital Daily</div>
                </header>
                <article className="card" style={{ padding: 22 }}>
                    <div className="kicker">Weekly</div>
                    <h1 style={{ marginTop: 6 }}>Markets weekly: flows and funding</h1>
                    <p className="muted">This is a placeholder article for demo purposes.</p>
                    <div className="divider" />
                    <p>
                        A quick look at volumes, incentives, and new deployments across major L2s. Funding rounds
                        remain steady with several seed announcements.
                    </p>
                    <ul>
                        <li>Stable volumes on top pairs</li>
                        <li>Liquidity incentives rotate to new deployments</li>
                        <li>Incremental upgrades ship across ecosystems</li>
                    </ul>
                    <p className="helper">End of demo content.</p>
                </article>
            </div>
        </div>
    );
}

const styles = {
    page: { minHeight: '100vh' },
    container: { maxWidth: 900, margin: '0 auto', padding: '32px 20px' },
    header: {
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '12px 0 22px', borderBottom: '1px solid var(--border)', marginBottom: 22,
    },
};


