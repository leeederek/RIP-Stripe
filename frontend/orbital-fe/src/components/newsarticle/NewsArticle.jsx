import React from 'react';
import Widget from '../Widget';

export default function NewsArticle() {
    return (
        <div style={styles.page}>
            {/* Background newsletter content */}
            <div style={styles.newsContainer} aria-hidden={true}>
                <header style={styles.header}>
                    <div className="brand"><span className="brand-dot" /> Orbital Daily</div>
                </header>
                <main style={styles.content}>
                    <article style={styles.article}>
                        <h1 style={{ marginTop: 0 }}>Crypto markets steady as L2 activity grows</h1>
                        <p className="muted">By Orbital Newsroom • Today</p>
                        <p>
                            Layer-2 ecosystems continue to expand with rising developer activity and new on-chain
                            applications. Wallet onboarding remains a key focus as teams streamline sign-in with
                            email and passkeys.
                        </p>
                        <p>
                            In this edition, we explore improvements to account abstraction, the latest on Base
                            Sepolia testnet tooling, and best practices for secure recovery flows.
                        </p>
                        <p>
                            Market makers report stable volumes across the top pairs while liquidity providers rotate
                            incentives to newer deployments. Teams emphasize progressively decentralized governance
                            and safer defaults for consumer apps. Tooling across the stack—from bundlers to paymasters—
                            continues to mature.
                        </p>
                        <p>
                            Developers also highlighted smoother onboarding patterns using email-first sign-ins that
                            later add passkeys and seedless recovery. With gas sponsorship, many flows complete without
                            requiring a native balance up front, improving first-session conversion rates dramatically.
                        </p>
                        <div className="divider" />
                        <h3 style={{ marginTop: 0 }}>Developer highlights</h3>
                        <ul>
                            <li>Account abstraction SDK updates</li>
                            <li>Gas optimizations across rollups</li>
                            <li>Stablecoin settlement improvements</li>
                        </ul>
                        <p>
                            Beyond the core protocol improvements, the ecosystem is standardizing UI primitives for
                            wallets, swaps, and on-ramps. Expect more accessible, embedded experiences that feel like
                            traditional apps while remaining self-custodial.
                        </p>
                        <p className="helper">Scroll to read more background content behind the widget.</p>
                    </article>
                    <article style={styles.article}>
                        <h2 style={{ marginTop: 0 }}>Security and recovery</h2>
                        <p>
                            Progressive onboarding with email-first flows reduces friction while keeping users in
                            control. Multi-factor recovery and guarded actions continue to be recommended.
                        </p>
                        <p>
                            Educating users about signing domains, human-readable actions, and spending limits is key.
                            Teams are adopting intent-based designs with clear previews, while audits now include UX
                            threat modeling in addition to smart contract reviews.
                        </p>
                        <p>
                            As always, keep private information off-chain, rotate exposed keys immediately, and prefer
                            audited libraries. Security is a continuous practice, not a destination.
                        </p>
                    </article>
                    <article style={styles.article}>
                        <h2 style={{ marginTop: 0 }}>Ecosystem notes</h2>
                        <p>
                            New learning resources and starter templates help teams ship faster with modern stacks.
                            We’ll continue to highlight examples in upcoming issues.
                        </p>
                        <ul>
                            <li>Starter kits with account abstraction and gas sponsorship</li>
                            <li>Example apps for swaps and liquidity provisioning</li>
                            <li>Design kits for consistent, accessible dark themes</li>
                        </ul>
                    </article>
                </main>
            </div>

            {/* Blur overlay and widget */}
            <div style={styles.overlay}>
                <div style={styles.overlayScrim} />
                <div style={styles.overlayCenter}>
                    <Widget />
                </div>
            </div>
        </div>
    );
}

const styles = {
    page: {
        position: 'relative',
        minHeight: '100vh',
    },
    newsContainer: {
        maxWidth: 900,
        margin: '0 auto',
        padding: '40px 20px 160px',
    },
    header: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '12px 0 22px',
        borderBottom: '1px solid var(--border)',
        marginBottom: 22,
    },
    content: {
        display: 'grid',
        gap: 26,
    },
    article: {
        background: 'linear-gradient(180deg, var(--panel), var(--panel-strong))',
        border: '1px solid var(--border)',
        borderRadius: 14,
        padding: 18,
    },
    overlay: {
        position: 'fixed',
        inset: 0,
        zIndex: 40,
        pointerEvents: 'auto',
        display: 'grid',
        placeItems: 'center',
    },
    overlayScrim: {
        position: 'absolute',
        inset: 0,
        background: 'rgba(0,0,0,0.45)',
        backdropFilter: 'blur(14px)',
    },
    overlayCenter: {
        position: 'relative',
        zIndex: 1,
        padding: 10,
        width: '100%',
        maxWidth: 760,
    },
};


