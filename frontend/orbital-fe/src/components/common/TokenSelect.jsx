import React, { useMemo } from 'react';
import { TOKENS } from '../../constants/tokens';

export default function TokenSelect({ value, onChange, include }) {
  const options = useMemo(
    () => TOKENS.filter((t) => !include || include.includes(t.symbol)),
    [include]
  );
  return (
    <select className="select" value={value} onChange={(e) => onChange(e.target.value)}>
      {options.map((t) => (
        <option key={t.symbol} value={t.symbol}>
          {t.symbol} — {t.name}
        </option>
      ))}
    </select>
  );
}


