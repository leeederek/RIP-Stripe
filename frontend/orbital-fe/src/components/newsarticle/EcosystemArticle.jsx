import React from 'react';

export default function EcosystemArticle() {
    return (
        <div style={styles.page}>
            <div style={styles.container}>
                <header style={styles.header}>
                    <div className="brand"><span className="brand-dot" /> Orbital Daily</div>
                </header>
                <article className="card" style={{ padding: 22 }}>
                    <div className="kicker">Notes</div>
                    <h1 style={{ marginTop: 6 }}>Ecosystem notes and resources</h1>
                    <p className="muted">This is a placeholder article for demo purposes.</p>
                    <div className="divider" />
                    <ul>
                        <li>Starter kits with account abstraction</li>
                        <li>Example apps for swaps and LP</li>
                        <li>Design tokens and dark-mode themes</li>
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


