import React, { useEffect, useState } from 'react';
import Coinbase from '../../assets/svgs/coinbase';
import CreateWalletStep from './CreateWalletStep';
import Privy from '../../assets/svgs/privy';

/**
 * Pop-up dialog for selecting a wallet creation method.
 * Styling matches the app's dark, glassy theme by leveraging CSS variables
 * from `index.css` and reusing existing button classes.
 */
export default function CreateWalletDialog({ isOpen, onClose, onCreate }) {
  const [pageIndex, setPageIndex] = useState(0); // 0: choose, 1: confirm/details
  const [selectedMethod, setSelectedMethod] = useState(null);
  const [slidesOpacity, setSlidesOpacity] = useState(1);

  useEffect(() => {
    if (!isOpen) return;
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    return () => {
      document.body.style.overflow = originalOverflow;
    };
  }, [isOpen]);

  if (!isOpen) return null;

  const goTo = (nextIndex) => {
    // fade + slide animation
    setSlidesOpacity(0.6);
    // move to next frame to ensure opacity change is applied before transform
    requestAnimationFrame(() => {
      setPageIndex(nextIndex);
      requestAnimationFrame(() => setSlidesOpacity(1));
    });
  };

  const handleSelect = (method) => {
    setSelectedMethod(method);
    goTo(1);
  };

  const handleBack = () => {
    goTo(0);
  };

  function labelFor(method) {
    if (method === 'smart') return 'Coinbase (email)';
    if (method === 'privy') return 'Privy (email)';
    if (method === 'hardware') return 'Hardware wallet';
    return 'Wallet';
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="create-wallet-title"
      style={styles.overlay}
      onClick={onClose}
    >
      <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div style={styles.header}>
          <div>
            <div className="kicker">Create</div>
            <h3 id="create-wallet-title" style={{ margin: 0 }}>
              {pageIndex === 0 ? 'Choose a wallet type' : 'Confirm your choice'}
            </h3>
            <div className="muted" style={{ marginTop: 6 }}>
              {pageIndex === 0
                ? 'Select how you want to create your new wallet.'
                : selectedMethod ? `You chose ${labelFor(selectedMethod)}. Continue to set it up.` : 'Continue to set it up.'}
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {pageIndex > 0 && (
              <button className="btn btn-ghost" onClick={handleBack}>
                ← Back
              </button>
            )}
            <button aria-label="Close" className="btn btn-ghost" onClick={onClose}>
              ✕
            </button>
          </div>
        </div>

        <div style={styles.carouselViewport}>
          <div
            style={{
              ...styles.slides,
              transform: pageIndex === 0 ? 'translateX(0%)' : 'translateX(-50%)',
              opacity: slidesOpacity,
            }}
          >
            <div style={styles.slide}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                <OptionCard
                  icon={<Coinbase />}
                  title="Create with Coinbase"
                  description="Use your email address to create a wallet."
                  ctaLabel="Create with Coinbase"
                  onClick={() => handleSelect('coinbase')}
                />

                <OptionCard
                  icon={<Privy />}
                  title="Create with Privy"
                  description="Create a classic wallet secured with a secret recovery phrase."
                  ctaLabel="Create with Privy"
                  onClick={() => handleSelect('privy')}
                />

                <OptionCard
                  title="Hardware wallet"
                  description="Set up with Ledger or Trezor for maximum security."
                  ctaLabel="Connect hardware wallet"
                  onClick={() => handleSelect('hardware')}
                />
              </div>
            </div>

            <div style={styles.slide}>
              <CreateWalletStep
                method={selectedMethod}
                onBack={handleBack}
                onContinue={(payload) => onCreate(payload || selectedMethod || 'coinbase')}
              />
            </div>
          </div>
        </div>

        <div className="footer-cta">
          <button className="btn" onClick={onClose}>Cancel</button>
        </div>
      </div>
    </div>
  );
}


function OptionCard({ title, description, ctaLabel, onClick, variant = 'default', icon }) {
  return (
    <div className='card-interactable' onClick={onClick}>
      <div style={styles.textContainer}>
        {icon}
        <div className={styles.nameContainer}>
          <div style={{ fontWeight: 600 }}>{title}</div>
          <div className="helper">{description}</div>
        </div>
      </div>
    </div>
  );
}

const styles = {
  overlay: {
    position: 'fixed',
    inset: 0,
    background: 'rgba(0,0,0,0.6)',
    backdropFilter: 'blur(6px)',
    display: 'grid',
    placeItems: 'center',
    padding: 20,
    zIndex: 50,
    borderRadius: 18,
  },
  modal: {
    width: '100%',
    maxWidth: 640,
    background: 'linear-gradient(180deg, var(--panel), var(--panel-strong))',
    border: '1px solid var(--border)',
    borderRadius: 16,
    boxShadow: '0 10px 30px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.04)',
    backgroundColor: 'rgba(0,0,0,0.8)',
  },
  header: {
    padding: '18px 22px',
    borderBottom: '1px solid var(--border)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  carouselViewport: {
    overflow: 'hidden',
    width: '100%',
    position: 'relative',
  },
  slides: {
    display: 'flex',
    width: '200%',
    transition: 'transform 280ms ease, opacity 280ms ease',
  },
  slide: {
    width: '50%',
    boxSizing: 'border-box',
    padding: 24,
  },
  // card: {
  //   display: 'flex',
  //   alignItems: 'center',
  //   justifyContent: 'space-between',
  //   gap: 12,
  //   background: 'var(--input)',
  //   border: '1px solid var(--border)',
  //   borderRadius: 12,
  //   padding: 14,
  //   margin: 12,
  // },
  textContainer: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
  },
};


