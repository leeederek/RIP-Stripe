import React, { useState } from 'react';
import NewsArticle from './NewsArticle';
import SecurityArticle from './SecurityArticle';
import EcosystemArticle from './EcosystemArticle';
import MarketsWeekly from './MarketsWeekly';

export default function NewsHome() {
    const [selected, setSelected] = useState(null);

    const articles = [
        {
            id: 'l2-growth',
            title: 'Crypto markets steady as L2 activity grows',
            excerpt: 'Layer-2 ecosystems continue to expand with rising developer activity and new on-chain applications.',
            tag: 'Featured',
            priceTag: '1 PYUSD',
            date: 'Today',
            clickable: true,
        },
        {
            id: 'security-recovery',
            title: 'Security and recovery best practices',
            excerpt: 'Progressive onboarding with email-first flows reduces friction while keeping users in control.',
            tag: 'Guide',
            date: 'This week',
            clickable: true,
        },
        {
            id: 'ecosystem-notes',
            title: 'Ecosystem notes and resources',
            excerpt: 'Starter templates, example apps, and design kits to help you ship faster with modern stacks.',
            tag: 'Notes',
            date: 'This week',
            clickable: true,
        },
        {
            id: 'markets-weekly',
            title: 'Markets weekly: flows and funding',
            excerpt: 'A quick look at volumes, incentives, and new deployments across major L2s.',
            tag: 'Weekly',
            date: 'Yesterday',
            clickable: true,
        },
    ];

    if (selected) {
        return (
            <div style={{ position: 'relative' }}>
                <div style={{ position: 'fixed', top: 18, left: 22, zIndex: 60 }}>
                    <button className="btn" onClick={() => setSelected(null)}>← Back</button>
                </div>
                {selected === 'l2-growth' && <NewsArticle />}
                {selected === 'security-recovery' && <SecurityArticle />}
                {selected === 'ecosystem-notes' && <EcosystemArticle />}
                {selected === 'markets-weekly' && <MarketsWeekly />}
            </div>
        );
    }

    return (
        <div style={styles.page}>
            <div style={styles.container}>
                <header style={styles.header}>
                    <div className="brand"><span className="brand-dot" /> Orbital Daily</div>
                </header>

                <div className="stack" style={{ gap: 22 }}>
                    <div className="stack">
                        <div className="kicker">Latest</div>
                        <h2 style={{ margin: 0 }}>Read the Orbital newsletter</h2>
                        <div className="muted" style={{ marginTop: 6 }}>Stories about wallets, L2s, and developer tooling.</div>
                    </div>

                    <div style={styles.grid}>
                        {articles.map((a) => (
                            <article key={a.id} className={a.clickable ? 'card-interactable' : 'card'} onClick={() => a.clickable && setSelected(a.id)} role="button" aria-label={`Open ${a.title}`}>
                                <div className="stack" style={{ gap: 10 }}>
                                    <div className="row" style={{ alignItems: 'center', justifyContent: 'space-between' }}>
                                        <div className="row" style={{ gap: 8, alignItems: 'center' }}>
                                            <span className="tag">{a.tag}</span>
                                            {a.priceTag && <span className="tag warning">{a.priceTag}</span>}
                                        </div>
                                        <span className="helper">{a.date}</span>
                                    </div>
                                    <div style={{ fontWeight: 700, fontSize: 18 }}>{a.title}</div>
                                    <div className="helper">{a.excerpt}</div>
                                    <div className="row" style={{ marginTop: 6 }}>
                                        <button className={`btn ${a.clickable ? 'btn-primary' : ''}`} onClick={(e) => { e.stopPropagation(); if (a.clickable) setSelected(a.id); }}>
                                            {a.clickable ? 'Read' : 'Coming soon'}
                                        </button>
                                    </div>
                                </div>
                            </article>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}

const styles = {
    page: {
        minHeight: '100vh',
    },
    container: {
        maxWidth: 980,
        margin: '0 auto',
        padding: '32px 20px 60px',
    },
    header: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '12px 0 22px',
        borderBottom: '1px solid var(--border)',
        marginBottom: 22,
    },
    grid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
        gap: 14,
    },
};


