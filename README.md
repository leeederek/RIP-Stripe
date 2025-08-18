# Kyma Pay: A cheaper and trustless Stripe alternative for stablecoin payments
Kyma Pay is on-chain financial infrastructure for merchants to accept [GENIUS Act](https://www.congress.gov/bill/119th-congress/senate-bill/394/text) Compliant stablecoin payments: instantly and globally for 10x less compared to Stripe (0.15% vs. [Stripe's 1.5% fee for stablecoin payments](https://stripe.com/pricing#payments)). Request payment in your preferred token and network while users pay using any stablecoin and from any network they want. Fully chain abstracted.

Under the hood, all swaps are handled instantly on-chain using a new type of AMM design based on [Orbital](https://www.paradigm.xyz/2025/06/orbital) that offers high capital efficiency (via concentrated liquidity) and low slippage. Kyma Pay uses the previously abandoned `HTTP 402: Payment Required` response type for programmatic payments and LayerZero's OFT adapaters to facilitate omnichain stablecoin swaps to/from a single liquidity pool. 

[Kyma was a Finalist at ETHGlobal NYC 2025 Hackathon](https://ethglobal.com/showcase/kyma-pay-yn65a)

*Kyma (κῦμα), the Greek word for "wave", symbolizes the powerful wave of transformation that stablecoins are bringing to global finance.”*

## User Flow:
<img width="1511" height="995" alt="Screenshot 2025-08-17 at 12 12 19 AM" src="https://github.com/user-attachments/assets/4f99f426-0fa4-40ea-9796-0043d3fa9115" />

* :white_check_mark: Merchants choose the stablecoin they wish to receive & get access to GENIUS Act Compliant, borderless, and instant payments infrastructure for 10x cheaper without needing to know/use the blockchain directly.
* :white_check_mark: Customers pay using any stablecoin they want and from any chain they are on with near zero slippage and with deep on-chain liquidity.
* :white_check_mark: Stablecoin issuers get direct, on-chain distribution for their assets in the Ethereum ecosystem without fragmenting liquidity.
* :white_check_mark: Liquidity providers, like with UniswapV3, earn valuable swap fees by concentrating their liquidity around $1.00 but across hundreds of stablecoins in a single pool: unlocking unparalleled capital efficiency.

## Tech stack
### 1. Orbital: A new AMM [design by Paradigm](https://www.paradigm.xyz/2025/06/orbital) that supports swaps between hundreds of stablecoins from a single pool: offering unified liquidity while being highly capital efficient and robust
To enable highly capital efficient stablecoin swaps between merchants and customers, Kyma Pay implements the [Orbital](https://www.paradigm.xyz/2025/06/orbital) AMM design. This design is unique because it applies the concept of [UniswapV3's concentrated liquidity](https://docs.uniswap.org/concepts/protocol/concentrated-liquidity) to a new type of liquidity pool that can support hundreds of stablecoins, including PYUSD, UDSC, USDT, USDe, and many others. Animations below are from the [Orbital Whitepaper](https://www.paradigm.xyz/2025/06/orbital).

| <img src="https://raw.githubusercontent.com/leeederek/sphere-swap/main/media/orbital-gif-1.gif" width="400" alt="Orbital GIF 1" /> | <img src="https://raw.githubusercontent.com/leeederek/sphere-swap/main/media/orbital-gif-2.gif" width="400" alt="Orbital GIF 2" /> |
|---|---|

Instead of drawing tick boundaries along a 2D curve like with Uniswap's design (e.g. `y = x * k`), our implementation draws tick boundaries as higher-dimension "orbits" or "spheres" around the $1.00 price point. Certain invariants are enforced to ensure that the collapse/depeg of any stablecoin in the pool will not adversely impact swaps between other stablecoins (since there are greater than 2 axes), allowing for dozens, if not hundreds, of stablecoins to be concentrated into a single pool to unlock unprecedented levels of capital efficiency. 

### 2. Coinbase's x402: `HTTP 402 Payment Required` response status for the scalability that payment systems need
We use Coinbase's x402 payment protocol to embed stablecoin payments directly into web applications, such as merchant checkout flows. To be precise: the client receives a `HTTP 402: Payment Required` response when/if they try to access or purchase something without payment. This 402 response from Kyma Pay will contain the merchant's accepted stablecoins (if defined) and network. 

<img width="300" height="300" alt="Screenshot 2025-08-17 at 12 03 39 AM" src="https://github.com/user-attachments/assets/9b34fbb8-023a-4b3f-94d4-394e6816b555" />

Settlement and verification of the payment is then handled by [Coinbase's x402 Facilitator](https://docs.cdp.coinbase.com/api-reference/v2/rest-api/x402-facilitator/x402-facilitator) before allowing the customer to complete the transaction. 

Payment to the merchant is done on their preferred network and in their desired stablecoin at the cost of just gas and swap fees (0.15%) - a fraction of the cost that they would otherwise pay to Stripe to accept stablecoin payments.

### 3. Coinbase's embedded wallets
We use Coinbase's embedded wallet product to allow new users to provision and login to smart contract wallets using social logins (email, SMS) to make onboarding seamless. 

<img width="300" height="300" alt="Screenshot 2025-08-17 at 12 03 00 AM" src="https://github.com/user-attachments/assets/f7b42311-c08b-46f3-aa14-11d023aa380a" />
<img width="300" height="300" alt="Screenshot 2025-08-17 at 12 03 07 AM" src="https://github.com/user-attachments/assets/e051022d-2346-43c1-b714-36a583a409c3" />

### 4. GENIUS Act Compliance for risk-based, actionable insights for merchants and liquidity providers 
Kyma Pay ingests monthly compliance data from issuers of all stablecoins that are deposited into its pool. Metrics such as: the breakdown of backing reserves, audit history, circulating supply, liquidity stress test results, and other information are used to produce a Risk Score for merchants to use when assessing which stablecoins to use. Most of this information is mandated by the US Government for US-issued stablecoins as part of the recently passed GENIUS Act and making this information available and actionable for merchants is a key differentiator of Kyma Pay that does not exist on the market today.

### 5. LayerZero OFTs for a chain-abstracted experience 
LayerZero OFT Adapters are used to burn and mint tokens from other chains before initiating swaps with the Orbital stablecoin AMM pool as Orbital's smart contracts themselves reside on Ethereum Sepolia

## Motivation
Stablecoins are the future of global finance and capitalizing on this momentum with trustless solutions is critical to ensuring we don't build new centralized systems that are extractive and closed. Today, Stripe charges merchants large fees for processing payments. With the advent of blockchain technology, we can democratize access to payments infrastructure while making them cheaper and more efficient too for a more globally connected, collaborative economy.
* In 2024, total stablecoin transaction volume reached $27.6 USD trillion, surpassing the combined volume on the Visa and Mastercard networks *combined* ([source](https://blog.cex.io/ecosystem/stablecoin-landscape-34864)). 
* [Robinhood](https://newsroom.aboutrobinhood.com/robinhood-launches-stock-tokens-reveals-layer-2-blockchain-and-expands-crypto-suite-in-eu-and-us-with-perpetual-futures-and-staking/) and [Stripe](https://cryptobriefing.com/stripe-builds-tempo-blockchain-paradigm/) are launching their own RWA and payment's focused chains in 2026
* The United States Congress passed the [GENIUS Act](https://www.congress.gov/bill/119th-congress/senate-bill/394/text), which sets clear rules and guidelines for stablecoin issuers
* Visa and other incumbents are [launching their own blockchain-based networks](https://corporate.visa.com/en/about-visa/visanet.html) as a reactionary response to the real threat that blockchains and stablecoins have on their business

All of these tailwinds set up the perfect environment for a solution that both: (1) brings the benefits of a distributed ledger for payments (instant, global, cheap) to the masses and (2) helps accelerate distribution of stablecoins and access to finance across the globe.


















