# CDP React App

This project was generated with [`@coinbase/create-cdp-app`](https://coinbase.github.io/cdp-web/modules/_coinbase_create-cdp-app.html) using the React template.

## Project Structure

```
src/
├── App.tsx                # Main application component with routing and layout
├── config.ts             # CDP configuration settings
├── Header.tsx            # Navigation header with authentication status
├── Icons.tsx             # Reusable icon components
├── index.css            # Global styles and theme variables
├── Loading.tsx          # Loading state component
├── main.tsx            # Entry point with CDP provider setup
├── SignedInScreen.tsx   # Screen displayed after successful authentication
├── SignInScreen.tsx     # Authentication screen with CDP sign-in flow
├── theme.ts            # Theme configuration and styling constants
├── Transaction.tsx     # Example transaction flow using CDP Hooks
├── UserBalance.tsx     # Component to display user's wallet balance
```

## Getting Started

First, make sure you have your CDP Project ID:

1. Sign in or create an account on the [CDP Portal](https://portal.cdp.coinbase.com)
2. Copy your Project ID from the dashboard
3. Go to the [Embedded Wallets CORS settings](https://portal.cdp.coinbase.com/products/embedded-wallets/cors)
4. Click add origin and whitelist `http://localhost:3000` (or wherever your app will run)

Then, copy the `env.example` file to `.env`, and populate the `VITE_CDP_PROJECT_ID` with your project id.

Now you can start the development server:

Using npm:
```bash
# Install dependencies
npm install

# Start the development server
npm run dev
```

Using yarn:
```bash
# Install dependencies
yarn

# Start the development server
yarn dev
```

Using pnpm:
```bash
# Install dependencies
pnpm install

# Start the development server
pnpm dev
```

Visit [http://localhost:3000](http://localhost:3000) to see your app.

## Features

This template comes with:
- CDP React components for authentication
- Example transaction components for Base Sepolia
- Vite for fast development and building
- TypeScript for type safety
- ESLint for code quality

## Learn More

- [CDP Documentation](https://docs.cloud.coinbase.com/cdp/docs)
- [CDP React Documentation](https://docs.cloud.coinbase.com/cdp/docs/react-components)
- [CDP Portal](https://portal.cdp.coinbase.com)
- [Vite Documentation](https://vitejs.dev)
