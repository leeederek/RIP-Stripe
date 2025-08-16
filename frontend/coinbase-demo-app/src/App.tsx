import { useIsInitialized, useIsSignedIn } from "@coinbase/cdp-hooks";

import Loading from "./Loading";
import SignedInScreen from "./SignedInScreen";
import SignInScreen from "./SignInScreen";

/**
 * This component how to use the useIsIntialized, useEvmAddress, and useIsSignedIn hooks.
 * It also demonstrates how to use the AuthButton component to sign in and out of the app.
 */
function App() {
  const { isInitialized } = useIsInitialized();
  const { isSignedIn } = useIsSignedIn();

  return (
    <div className="app flex-col-container flex-grow">
      {!isInitialized && <Loading />}
      {isInitialized && (
        <>
          {!isSignedIn && <SignInScreen />}
          {isSignedIn && <SignedInScreen />}
        </>
      )}
    </div>
  );
}

export default App;
