import React, { useEffect, useState } from 'react';
import Widget from '../Widget';
import Article from './Article';

export default function NewsArticle() {
    const getArticle = React.useCallback(async () => {
        const response = await fetch('http://localhost:8000/get-resource/123', {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
        });
        return response;
    }, []);

    const [doesHaveAccess, setDoesHaveAccess] = useState(false);
    const [article, setArticle] = useState(null);

    useEffect(() => {
        async function getDoesHaveAccessData() {
            // You can await here
            const response = await getArticle();
            setDoesHaveAccess(response.status === 200 ? true : false);
            if (response.status === 200) {
                // parse article
            }
        }
        getDoesHaveAccessData();
    }, [setDoesHaveAccess, getArticle]);


    return (
        <div style={styles.page}>
            {!doesHaveAccess ? (
                <div style={styles.overlay}>
                    <div style={styles.overlayScrim} />
                    <div style={styles.overlayCenter}>
                        <Widget getArticle={getArticle} setDoesHaveAccess={setDoesHaveAccess} />
                    </div>
                </div>
            ) : <div style={styles.newsContainer} aria-hidden={true}><Article
                title="Crypto markets steady as L2 activity grows"
                description="Layer-2 ecosystems continue to expand with rising developer activity."
                author="Orbital Newsroom"
                date="Today"
                texts={[
                    "Crypto markets traded in a tight range as liquidity stayed resilient across major pairs. While spot prices barely moved, on-chain activity remained elevated on Base and other L2s thanks to lower fees, faster confirmations, and a steady stream of new app launches. Teams highlighted continued improvements to rollup infrastructure and a growing pipeline of consumer-focused experiences.",
                    "For builders, the priority remains onboarding. Email-first sign-ins, gas sponsorship, and clearer signing prompts are reducing first-session friction and boosting conversion. Account abstraction patterns are gaining traction, enabling safer recovery, spending limits, and human-readable actions—without forcing users to manage seed phrases on day one.",
                    "Looking ahead, security and scalability top the roadmap alongside better education. Cross-chain liquidity and bridging UX are improving but still require careful review. Despite macro headwinds, momentum in L2 ecosystems points to sustained growth in real usage, with stablecoin payments, embedded wallets, and intent-based flows leading adoption.",
                    "Across Layer-2s, daily active addresses and transactions per second continue to climb, with Base showing sustained fee efficiency even during periods of heightened activity. TVL has diversified as more protocols deploy, and new incentive programs are shifting liquidity toward newer pools and periphery apps that focus on consumer use cases rather than purely speculative trading.",
                    "Developer tooling matured further this week. New SDK releases simplified bundler integration, paymaster configuration, and session key management, helping application teams ship safer flows with fewer footguns. Starter templates now incorporate sensible defaults around domain-separated signatures, limits, and human-readable prompts to reduce user error.",
                    "Payments remain a bright spot. Stablecoin settlement, combined with instant onboarding, is enabling smoother checkout experiences for digital goods and subscription content. More teams are experimenting with earn-and-spend loops that keep users on-chain without forcing complex wallet setup, while custodial off-ramps integrate directly into the app experience.",
                    "Risk management is front and center. Projects continue to expand bug bounty programs and adopt continuous audit practices. On the UX side, transaction previews and intent-based flows are helping users understand what they’re approving, while MEV-aware routing and simulation reduce surprises between quote and execution.",
                    "Regulatory headlines were mixed but largely status quo for crypto markets. The industry focus is shifting to practical consumer protections—clear disclosures, spend caps, and better fraud tooling—paired with developer guardrails that prevent common misconfigurations. As frameworks solidify, teams expect a faster path from prototype to production.",
                    "Into next week, watch for updates to rollup compression and L1 data availability, which could lower fees further during peak periods. Several consumer apps are planning feature drops around embedded wallets and loyalty rewards, and a handful of governance proposals aim to streamline incentive allocations toward sticky user growth instead of transient farm-and-dump cycles.",
                    "Bottom line: fundamentals are improving beneath a quiet tape. If teams keep shipping safer defaults and intuitive onboarding, the next wave of users won’t need to understand the plumbing to benefit from it—precisely the point of this infrastructure cycle."
                ]}
            />

            </div>
            }
            {/* Background newsletter content */}
            {!doesHaveAccess && <div style={styles.newsContainer} aria-hidden={true}>
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
            </div>}


        </div>
    );
}

const styles = {
    page: {
        position: 'relative',
        maxHeight: '100vh',
        overflowY: 'hidden',
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


