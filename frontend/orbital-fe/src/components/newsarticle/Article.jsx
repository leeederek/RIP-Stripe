import React from 'react';

// Reusable article template for news posts
// Props:
// - title: string
// - description: string
// - author: string
// - date: string
// - texts: string[] (array of paragraph texts)
export default function Article({ title, description, author, date, texts = [] }) {
    return (
        <article className="card" style={{ padding: 18 }}>
            {title ? <h1 style={{ marginTop: 0 }}>{title}</h1> : null}
            {(author || date) ? (
                <p className="muted" style={{ marginTop: 0 }}>
                    {author ? `By ${author}` : ''}{author && date ? ' • ' : ''}{date || ''}
                </p>
            ) : null}
            {description ? <p className="helper" style={{ marginTop: 6 }}>{description}</p> : null}

            {(texts && texts.length > 0) ? (
                <div style={{ marginTop: 12 }}>
                    {texts.map((paragraph, idx) => (
                        <p key={idx} style={{ marginTop: idx === 0 ? 0 : 12 }}>{paragraph}</p>
                    ))}
                </div>
            ) : null}
        </article>
    );
}

