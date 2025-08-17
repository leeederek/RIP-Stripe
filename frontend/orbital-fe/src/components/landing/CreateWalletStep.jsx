import React, { useState, useRef, useEffect } from 'react';
import { useSignInWithEmail, useVerifyEmailOTP } from '@coinbase/cdp-hooks';


function labelFor(method) {
    if (method === 'coinbase') return 'Coinbase (email)';
    if (method === 'privy') return 'Privy (email)';
    if (method === 'hardware') return 'Hardware (email)';
    return 'Wallet';
}

export default function CreateWalletStep({ method, onBack, onContinue }) {
    const [email, setEmail] = useState('');
    const [phone, setPhone] = useState('');
    const [contactMethod, setContactMethod] = useState('email'); // 'email' | 'phone'
    const [otp, setOtp] = useState('');
    // Coinbase uses a flow identifier between steps
    const [flowId, setFlowId] = useState(null);
    const [subIndex, setSubIndex] = useState(0); // 0: email, 1: otp
    const [loading, setLoading] = useState(false);

    // Coinbase hooks
    const { signInWithEmail } = useSignInWithEmail();
    const { verifyEmailOTP } = useVerifyEmailOTP();

    const goToSub = (idx) => {
        setSubIndex(idx);
    };

    const getPrimaryButtonLabel = () => {
        switch (subIndex) {
            case 0:
                return 'Continue';
            case 1:
                return 'Verify';
            default:
                return 'Continue';
        }
    };

    const handlePrimary = async () => {
        // Method-specific branching preserved; actual API calls still stubbed
        if (subIndex === 0) {
            setLoading(true);
            switch (method) {
                case 'coinbase': {
                    try {
                        const result = await signInWithEmail({ email });
                        setFlowId(result?.flowId || null);
                    } catch (error) {
                        console.error('Failed to start email sign-in', error);
                    }
                    break;
                }
                case 'privy': {
                    // start Privy email flow (stub)
                    await new Promise((r) => setTimeout(r, 1));
                    break;
                }
                case 'hardware': {
                    // start Hardware provider email flow (stub)
                    await new Promise((r) => setTimeout(r, 1));
                    break;
                }
                default: {
                    await new Promise((r) => setTimeout(r, 1));
                }
            }
            setLoading(false);
            goToSub(1);
            return;
        }
        if (subIndex === 1) {
            setLoading(true);
            switch (method) {
                case 'coinbase': {
                    try {
                        await verifyEmailOTP({ email, flowId, otp });
                    } catch (error) {
                        console.error('OTP verification failed', error);
                        setLoading(false);
                        return;
                    }
                    break;
                }
                case 'privy': {
                    // verify via Privy (stub)
                    await new Promise((r) => setTimeout(r, 1));
                    break;
                }
                case 'hardware': {
                    // verify via Hardware provider (stub)
                    await new Promise((r) => setTimeout(r, 1));
                    break;
                }
                default: {
                    await new Promise((r) => setTimeout(r, 1));
                }
            }
            setLoading(false);
            // onContinue({ method, contactMethod, email, phone });
            return;
        }
    };

    const renderContent = () => {
        return (
            <div style={styles.subViewport}>
                <div style={styles.subSlide}>
                    {subIndex === 0 && (
                        <EmailStep
                            title={labelFor(method)}
                            contactMethod={contactMethod}
                            onContactMethodChange={setContactMethod}
                            email={email}
                            onEmailChange={setEmail}
                            phone={phone}
                            onPhoneChange={setPhone}
                        />
                    )}
                    {subIndex === 1 && (
                        <OtpStep
                            contactMethod={contactMethod}
                            email={email}
                            phone={phone}
                            otp={otp}
                            onOtpChange={setOtp}
                        />
                    )}
                </div>
            </div>
        );
    };

    return (
        <div className="card" style={{ display: 'grid', gap: 10, marginTop: 4, padding: 10 }}>
            {renderContent()}
            <div className="row" style={{ marginTop: 6 }}>
                <button className="btn" onClick={onBack} disabled={loading}>Back</button>
                <button className="btn-primary" onClick={handlePrimary} disabled={loading}>
                    {getPrimaryButtonLabel()}
                </button>
            </div>
        </div>
    );
}

const styles = {
    subViewport: {
        overflow: 'hidden',
        width: '100%',
    },
    subSlides: {
        display: 'flex',
        width: '200%',
        transition: 'transform 260ms ease, opacity 260ms ease',
    },
    subSlide: {
        width: '100%',
        boxSizing: 'border-box',
        display: 'grid',
        gap: 10,
    },
};

function EmailStep({ title, contactMethod, onContactMethodChange, email, onEmailChange, phone, onPhoneChange }) {
    return (
        <>
            <div className="label">Selected</div>
            <div style={{ fontWeight: 600 }}>{title}</div>
            <div className="helper">Use your email or phone number to receive a verification code.</div>

            <div className="chip-group" role="tablist" aria-label="Contact method">
                <button
                    type="button"
                    className={`chip ${contactMethod === 'email' ? 'active' : ''}`}
                    onClick={() => onContactMethodChange('email')}
                >
                    Email
                </button>
                <button
                    type="button"
                    className={`chip ${contactMethod === 'phone' ? 'active' : ''}`}
                    onClick={() => onContactMethodChange('phone')}
                >
                    Phone
                </button>
            </div>

            {contactMethod === 'email' ? (
                <input
                    className="input"
                    type="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => onEmailChange(e.target.value)}
                />
            ) : (
                <input
                    className="input"
                    type="tel"
                    inputMode="tel"
                    placeholder="+1 555 123 4567"
                    value={phone}
                    onChange={(e) => onPhoneChange(e.target.value)}
                />
            )}
        </>
    );
}

function OtpStep({ contactMethod, email, phone, otp, onOtpChange }) {
    const inputRefs = useRef(Array.from({ length: 6 }, () => React.createRef()));

    useEffect(() => {
        const firstEmptyIndex = Math.min(5, Math.max(0, (otp || '').length));
        const ref = inputRefs.current[firstEmptyIndex]?.current;
        ref?.focus?.();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const handleChange = (index, e) => {
        const value = e.target.value || '';
        const onlyDigits = value.replace(/\D/g, '');
        const chars = Array.from({ length: 6 }, (_, i) => (otp || '')[i] || '');
        if (onlyDigits.length === 0) {
            chars[index] = '';
            onOtpChange(chars.join(''));
            return;
        }
        let cursor = index;
        for (const ch of onlyDigits) {
            if (cursor > 5) break;
            chars[cursor] = ch;
            cursor += 1;
        }
        onOtpChange(chars.join(''));
        if (cursor <= 5) inputRefs.current[cursor]?.current?.focus?.();
    };

    const handleKeyDown = (index, e) => {
        if (e.key === 'Backspace') {
            e.preventDefault();
            const chars = Array.from({ length: 6 }, (_, i) => (otp || '')[i] || '');
            if (chars[index]) {
                chars[index] = '';
                onOtpChange(chars.join(''));
                return;
            }
            const prevIndex = Math.max(0, index - 1);
            chars[prevIndex] = '';
            onOtpChange(chars.join(''));
            inputRefs.current[prevIndex]?.current?.focus?.();
        }
        if (e.key === 'ArrowLeft') {
            e.preventDefault();
            const prev = Math.max(0, index - 1);
            inputRefs.current[prev]?.current?.focus?.();
        }
        if (e.key === 'ArrowRight') {
            e.preventDefault();
            const next = Math.min(5, index + 1);
            inputRefs.current[next]?.current?.focus?.();
        }
    };

    const handlePaste = (index, e) => {
        e.preventDefault();
        const text = (e.clipboardData?.getData('text') || '').replace(/\D/g, '');
        if (!text) return;
        const next = Array.from({ length: 6 }, (_, i) => (otp || '')[i] || '');
        let cursor = index;
        for (const ch of text) {
            if (cursor > 5) break;
            next[cursor] = ch;
            cursor += 1;
        }
        onOtpChange(next.join(''));
        const focusIndex = Math.min(5, cursor);
        inputRefs.current[focusIndex]?.current?.focus?.();
    };

    const digits = Array.from({ length: 6 }, (_, i) => (otp || '')[i] || '');

    return (
        <>
            <div className="label">Verify {contactMethod}</div>
            <div className="helper">Enter the 6-digit code sent to {contactMethod === 'email' ? email : phone}.</div>
            <div className="otp-inputs">
                {digits.map((ch, idx) => (
                    <input
                        key={idx}
                        ref={inputRefs.current[idx]}
                        className="otp-input"
                        type="text"
                        inputMode="numeric"
                        pattern="[0-9]*"
                        maxLength={1}
                        value={ch}
                        onChange={(e) => handleChange(idx, e)}
                        onKeyDown={(e) => handleKeyDown(idx, e)}
                        onPaste={(e) => handlePaste(idx, e)}
                        aria-label={`Digit ${idx + 1}`}
                    />
                ))}
            </div>
        </>
    );
}

// Removed provider-specific info components; all methods share the same flow

