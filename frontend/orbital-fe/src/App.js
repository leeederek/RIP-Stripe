import React from 'react';
import './App.css';
import NewsHome from './components/newsarticle/NewsHome';
import { CDPHooksProvider } from '@coinbase/cdp-hooks';
import {PrivyProvider} from '@privy-io/react-auth';

const cdpConfig = {
  projectId: process.env.REACT_APP_CDP_PROJECT_ID,
}

function App() {
  return (
    <div className="center-screen">
      <PrivyProvider
        appId={process.env.REACT_APP_PRIVY_APP_ID}
        clientId={process.env.REACT_APP_PRIVY_CLIENT_ID}
        config={{
          // Create embedded wallets for users who don't have a wallet
          embeddedWallets: {
            ethereum: {
              createOnLogin: 'users-without-wallets'
            }
          }
        }}
      >
      <CDPHooksProvider config={cdpConfig}>
        <NewsHome />
      </CDPHooksProvider>
    </PrivyProvider>

    </div>
  );
}

export default App;
