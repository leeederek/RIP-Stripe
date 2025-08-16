"""
ORBITAL AMM - Complete Lifecycle Example
=======================================

This example walks through the complete lifecycle of an Orbital AMM:
1. Pool initialization
2. LP liquidity provision
3. Swap execution and state changes
4. Liquidity removal

Uses the existing Orbital AMM implementation with detailed explanations.
"""

import math
from typing import List, Dict, Tuple
from dataclasses import dataclass

# Import the existing Orbital AMM classes (assuming they're available)
# from orbital_amm import OrbitalAMM, TickState, ReserveBounds, etc.

def demonstrate_orbital_lifecycle():
    """Complete walkthrough of Orbital AMM lifecycle"""
    
    print("=" * 60)
    print("ORBITAL AMM COMPLETE LIFECYCLE DEMONSTRATION")
    print("=" * 60)
    
    # ========================================================================
    # STEP 1: INITIALIZE N-TOKEN POOL
    # ========================================================================
    
    print("\n🏗️  STEP 1: POOL INITIALIZATION")
    print("-" * 40)
    
    # Required inputs for pool creation
    token_symbols = ['USDC', 'USDT', 'DAI', 'FRAX', 'LUSD']  # 5 stablecoins
    base_rate = 0.001  # Scaling factor (deployer choice)
    
    print(f"Creating pool with:")
    print(f"  Tokens: {token_symbols}")
    print(f"  Number of tokens (n): {len(token_symbols)}")
    print(f"  Base rate: {base_rate}")
    
    # Create the AMM
    amm = OrbitalAMM(token_symbols, base_rate)
    
    print(f"\n✅ Pool initialized successfully!")
    print(f"  Pool ID: orbital-{'-'.join(token_symbols)}")
    print(f"  Initial state: Empty (no liquidity)")
    
    # ========================================================================
    # STEP 2: THREE LPS PROVIDE LIQUIDITY
    # ========================================================================
    
    print("\n💰 STEP 2: LIQUIDITY PROVISION")
    print("-" * 40)
    
    # Define LP parameters
    lps = [
        {"name": "Alice", "capital": 10000, "depeg_tolerance": 0.98, "type": "Conservative"},
        {"name": "Bob", "capital": 25000, "depeg_tolerance": 0.95, "type": "Moderate"},
        {"name": "Carol", "capital": 50000, "depeg_tolerance": 0.85, "type": "Aggressive"}
    ]
    
    print("Adding liquidity providers:")
    
    for lp in lps:
        print(f"\n📍 {lp['name']} ({lp['type']} LP):")
        print(f"  Capital: ${lp['capital']:,}")
        print(f"  Depeg tolerance: {lp['depeg_tolerance']} (${lp['depeg_tolerance']:.2f} minimum)")
        
        # Calculate what will happen before adding liquidity
        radius = lp['capital'] * base_rate
        n = len(token_symbols)
        sqrt_n = math.sqrt(n)
        
        # Calculate k-bounds and expected k
        k_min = radius * (sqrt_n - 1)
        k_max = radius * (n - 1) / sqrt_n
        
        print(f"  Expected radius: {radius}")
        print(f"  K-bounds: [{k_min:.3f}, {k_max:.3f}]")
        
        # Add liquidity
        result = amm.add_liquidity(lp['name'].lower(), lp['capital'], lp['depeg_tolerance'])
        
        if result['status'] == 'success':
            print(f"  ✅ Tick created successfully!")
            print(f"  Tick ID: {result['tick_id']}")
            print(f"  Actual k-value: {result['k_value']:.3f}")
            print(f"  Capital efficiency: {result['capital_efficiency']}")
            print(f"  Virtual reserves: {result['virtual_reserves']:.3f}")
            print(f"  Initial reserves per token: {result['initial_reserves'][0]:.3f}")
        else:
            print(f"  ❌ Error: {result['message']}")
    
    # Show pool state after all LPs
    print(f"\n📊 Pool state after LP additions:")
    pool_stats = amm.get_pool_statistics()
    print(f"  Total ticks: {pool_stats['total_ticks']}")
    print(f"  Interior ticks: {pool_stats['interior_ticks']}")
    print(f"  Boundary ticks: {pool_stats['boundary_ticks']}")
    print(f"  Total liquidity: ${pool_stats['total_liquidity']:,}")
    print(f"  Total reserves per token: {pool_stats['total_reserves'][0]:.3f}")
    print(f"  All token prices: {list(pool_stats['current_prices'].values())}")
    
    # ========================================================================
    # STEP 3: EXECUTE SWAPS AND OBSERVE STATE CHANGES
    # ========================================================================
    
    print("\n🔄 STEP 3: SWAP EXECUTION AND STATE CHANGES")
    print("-" * 40)
    
    # Execute multiple swaps to show state evolution
    swaps = [
        {"amount": 500, "from": "USDC", "to": "USDT", "description": "Small swap"},
        {"amount": 2000, "from": "USDT", "to": "DAI", "description": "Medium swap"},
        {"amount": 5000, "from": "DAI", "to": "FRAX", "description": "Large swap"}
    ]
    
    for i, swap in enumerate(swaps, 1):
        print(f"\n🔁 Swap {i}: {swap['description']}")
        print(f"  Trading {swap['amount']} {swap['from']} → {swap['to']}")
        
        # Show pre-swap state
        pre_stats = amm.get_pool_statistics()
        pre_reserves = pre_stats['total_reserves']
        pre_prices = pre_stats['current_prices']
        
        from_idx = token_symbols.index(swap['from'])
        to_idx = token_symbols.index(swap['to'])
        
        print(f"  Pre-swap reserves: {swap['from']}={pre_reserves[from_idx]:.2f}, {swap['to']}={pre_reserves[to_idx]:.2f}")
        
        # Execute swap
        trade_result = amm.execute_trade(swap['amount'], swap['from'], swap['to'])
        
        if trade_result['status'] == 'success':
            print(f"  ✅ Swap successful!")
            print(f"  Input: {trade_result['input_amount']} {swap['from']}")
            print(f"  Output: {trade_result['output_amount']:.3f} {swap['to']}")
            print(f"  Effective price: {trade_result['effective_price']:.6f}")
            
            # Show post-swap state
            post_stats = amm.get_pool_statistics()
            post_reserves = post_stats['total_reserves']
            post_prices = post_stats['current_prices']
            
            print(f"  Post-swap reserves: {swap['from']}={post_reserves[from_idx]:.2f}, {swap['to']}={post_reserves[to_idx]:.2f}")
            print(f"  Interior ticks: {post_stats['interior_ticks']}, Boundary ticks: {post_stats['boundary_ticks']}")
            
            # Check for state transitions
            if post_stats['boundary_ticks'] > pre_stats['boundary_ticks']:
                print(f"  ⚠️  Some ticks transitioned from Interior → Boundary")
            elif post_stats['boundary_ticks'] < pre_stats['boundary_ticks']:
                print(f"  ↩️  Some ticks transitioned from Boundary → Interior")
            
        else:
            print(f"  ❌ Swap failed: {trade_result['message']}")
        
        # Show tick-level details after each major swap
        if i == len(swaps):  # After last swap
            print(f"\n📋 Individual tick states after all swaps:")
            for tick_id, tick in amm.ticks.items():
                alpha = sum(tick.reserves) / math.sqrt(len(tick.reserves))
                utilization = alpha / tick.k if tick.k > 0 else 0
                
                print(f"  Tick {tick_id} ({tick.owner.title()}):")
                print(f"    State: {tick.state.value}")
                print(f"    Radius: {tick.radius}")
                print(f"    K-value: {tick.k:.3f}")
                print(f"    Alpha: {alpha:.3f}")
                print(f"    Boundary utilization: {utilization:.1%}")
                print(f"    Reserves: [{', '.join(f'{r:.2f}' for r in tick.reserves)}]")
    
    # ========================================================================
    # STEP 4: LIQUIDITY REMOVAL (CONCEPTUAL - NOT IN CURRENT IMPLEMENTATION)
    # ========================================================================
    
    print("\n💸 STEP 4: LIQUIDITY REMOVAL (CONCEPTUAL)")
    print("-" * 40)
    
    print("Note: Liquidity removal is not implemented in the current code,")
    print("but here's how it would work:")
    
    # Simulate Alice wanting to remove 50% of her liquidity
    alice_tick_id = 1  # Assuming Alice was first
    removal_percentage = 0.5
    
    if alice_tick_id in amm.ticks:
        alice_tick = amm.ticks[alice_tick_id]
        
        print(f"\n📤 Simulating Alice removing {removal_percentage:.0%} of her liquidity:")
        print(f"  Current tick radius: {alice_tick.radius}")
        print(f"  Current reserves: [{', '.join(f'{r:.3f}' for r in alice_tick.reserves)}]")
        
        # Calculate what she would receive
        withdrawal_reserves = [r * removal_percentage for r in alice_tick.reserves]
        remaining_reserves = [r * (1 - removal_percentage) for r in alice_tick.reserves]
        new_radius = alice_tick.radius * (1 - removal_percentage)
        
        print(f"  Would withdraw: [{', '.join(f'{r:.3f}' for r in withdrawal_reserves)}]")
        print(f"  Would remain: [{', '.join(f'{r:.3f}' for r in remaining_reserves)}]")
        print(f"  New tick radius: {new_radius}")
        
        # Verify sphere constraint would be maintained
        remaining_norm = math.sqrt(sum(r**2 for r in remaining_reserves))
        constraint_satisfied = abs(remaining_norm - new_radius) < 1e-10
        
        print(f"  Sphere constraint maintained: {'✅' if constraint_satisfied else '❌'}")
        
        # Show impact on pool
        current_total_liquidity = sum(tick.liquidity for tick in amm.ticks.values())
        impact_percentage = (alice_tick.liquidity * removal_percentage) / current_total_liquidity
        
        print(f"  Impact on total pool liquidity: -{impact_percentage:.1%}")

def implementation_notes():
    """Additional implementation notes and considerations"""
    
    print("\n" + "=" * 60)
    print("IMPLEMENTATION NOTES AND CONSIDERATIONS")
    print("=" * 60)
    
    print("\n🔧 Key Implementation Details:")
    print("• Each LP creates an independent tick (mini-AMM)")
    print("• Ticks have individual radii based on capital contribution")
    print("• K-values determine risk tolerance (depeg protection)")
    print("• All ticks start at equal price point for mathematical consistency")
    print("• Trading uses consolidated state but updates individual ticks proportionally")
    
    print("\n⚠️  Current Limitations:")
    print("• Liquidity removal not implemented")
    print("• Fee mechanisms not included")
    print("• Simplified trade execution (should use quartic solver)")
    print("• No boundary crossing detection during trades")
    print("• No slippage protection")
    
    print("\n🎯 Production Considerations:")
    print("• Base rate should be carefully chosen for numerical stability")
    print("• Need robust boundary crossing detection and trade segmentation")
    print("• Should implement proper quartic equation solver for trades")
    print("• Fee collection and distribution mechanisms required")
    print("• Gas optimization for tick updates")
    print("• Oracle integration for fair pricing")
    
    print("\n📈 Capital Efficiency Benefits:")
    print("• Conservative LPs: High efficiency, low risk")
    print("• Aggressive LPs: Lower efficiency, higher fee earning potential")
    print("• Nested tick structure allows optimal capital allocation")
    print("• Individual risk management per LP")

if __name__ == "__main__":
    # Note: This assumes the OrbitalAMM class from previous artifact is available
    # In practice, you would import it from the orbital_amm module
    
    try:
        demonstrate_orbital_lifecycle()
        implementation_notes()
    except NameError:
        print("Error: OrbitalAMM class not found.")
        print("Please ensure the Orbital AMM implementation is available.")
        print("This example requires the classes from the previous artifact.")