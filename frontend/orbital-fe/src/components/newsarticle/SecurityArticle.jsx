import React from 'react';

export default function SecurityArticle() {
    return (
        <div style={styles.page}>
            <div style={styles.container}>
                <header style={styles.header}>
                    <div className="brand"><span className="brand-dot" /> Orbital Daily</div>
                </header>
                <article className="card" style={{ padding: 22 }}>
                    <div className="kicker">Guide</div>
                    <h1 style={{ marginTop: 6 }}>Security and recovery best practices</h1>
                    <p className="muted">This is a placeholder article for demo purposes.</p>
                    <div className="divider" />
                    <p>
                        Progressive onboarding with email-first sign-ins reduces friction while enabling safer
                        recoveries. Consider passkeys, session limits, and human-readable signing prompts.
                    </p>
                    <ul>
                        <li>Use intent previews for high-risk actions</li>
                        <li>Adopt multi-factor recovery flows</li>
                        <li>Rotate credentials promptly if exposed</li>
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


