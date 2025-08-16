import { LoadingSpinner } from "@coinbase/cdp-react/components/LoadingSpinner";

/**
 * App loading screen
 */
function Loading() {
  return (
    <main>
      <h1 className="sr-only">Loading</h1>
      <LoadingSpinner />
    </main>
  );
}

export default Loading;
