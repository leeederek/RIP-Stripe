# Sphere Swap: an [Orbital](https://www.paradigm.xyz/2025/06/orbital)-based AMM for a future with hundreds of stablecoins

Sphere Swap is a cross-chain implementation of an [Orbital-based](https://www.paradigm.xyz/2025/06/orbital) Automated Market Maker (AMM) that applies the concept of UniswapV3's concentrated liquidity to a new type of liquidity pool that can support hundreds of stablecoins. Instead of drawing tick boundaries along a 2D curve (e.g. y = x * k), Sphere Swap draws tick boundaries as higher-dimension "orbits" or "spheres" around the $1.00 price point. Invariants in the implementation ensure that the collapse or depeg of a stablecoin in the pool will not impact swaps between other tokens (since there are greater than 2 axes), allowing for dozens, if not hundreds, of stablecoins to be concentrated into a single pool to unlock unprecedent levels of capital efficiency.

Sphere Swap has a compliance layer on top using oracles to pull in stablecoin metadata from [GENIUS Act](https://en.wikipedia.org/wiki/GENIUS_Act) Compliant stablecoin issuers (e.g. reserve breakdown, KYC compliance, etc). 

![orbitalgif1](https://raw.githubusercontent.com/leeederek/sphere-swap/main/media/orbital-gif-1.gif) 
###### *Animation from: https://www.paradigm.xyz/2025/06/orbital*

![orbitalgif2](https://raw.githubusercontent.com/leeederek/sphere-swap/main/media/orbital-gif-2.gif) 
###### *Animation from: https://www.paradigm.xyz/2025/06/orbital*
