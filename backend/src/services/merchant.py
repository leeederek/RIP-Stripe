from src.configs import merchant_configs, orbital_configs, genius_configs
from web3 import HTTPProvider, Web3
from x402.chains import (
    get_chain_id,
    get_token_name,
    get_token_version,
)
from x402.types import (
    PaymentRequirements,
    TokenAmount,
    TokenAsset,
    EIP712Domain,
)

from typing import Dict, Any, Optional


def get_valid_payment_currencies(resource_id: int):
    """Get valid payment methods for a merchant."""
    merchant_name = merchant_configs.MERCHANT_ID_TO_MERCHANT_MAP.get(resource_id)
    merchant_currencies = merchant_configs.MERCHANT_TO_CURRENCY_MAP.get(merchant_name)
    return merchant_currencies


def swap_currencies():
    web3 = Web3(HTTPProvider(orbital_configs.PROVIDER_URL))

    orbital_contract = web3.eth.contract(
        address=web3.to_checksum_address(orbital_configs.CONTRACT_ADDRESS),
        abi=orbital_configs.ABI,
    )
    total_reserves = orbital_contract.functions.totalReserves()
    return total_reserves


def get_stablecoin_data(coin: str):
    found_data = None
    for item in genius_configs.DATA["stablecoins"]:
        if item["name"] == coin:
            found_data = item
            break
    return found_data


def calculate_reserve_risk(reserves: Dict[str, Any]) -> float:
    """Calculate reserve risk score (0-100, lower is better)"""
    score = 0

    # Reserve coverage ratio (should be >= 100%)
    coverage_ratio = reserves["reserve_percent_of_total"]
    if coverage_ratio >= 100:
        score += 20  # Perfect coverage
    elif coverage_ratio >= 95:
        score += 15
    elif coverage_ratio >= 90:
        score += 10
    else:
        score += 0

    # Asset quality (Cash + Treasuries are safest)
    asset_type = reserves["asset_type"].lower()
    if "cash" in asset_type and "treasury" in asset_type:
        score += 30
    elif "cash" in asset_type:
        score += 25
    elif "treasury" in asset_type:
        score += 20
    else:
        score += 10

    # Custodian quality (reputable custodians)
    custodian_count = len(reserves["custodians"])
    if custodian_count >= 2:
        score += 25  # Diversification
    else:
        score += 15

    # Reserve distribution (cash is most liquid)
    cash_percent = reserves["reserve_distribution"]["cash"]
    if cash_percent >= 70:
        score += 25
    elif cash_percent >= 50:
        score += 20
    elif cash_percent >= 30:
        score += 15
    else:
        score += 10

    return min(100, score)  # Cap at 100


def calculate_liquidity_risk(liquidity: Dict[str, Any]) -> float:
    """Calculate liquidity risk score (0-100, lower is better)"""
    score = 0

    # Daily liquidity ratio
    liquidity_ratio = liquidity["daily_liquidity_ratio_percent"]
    if liquidity_ratio >= 80:
        score += 40
    elif liquidity_ratio >= 70:
        score += 30
    elif liquidity_ratio >= 60:
        score += 20
    else:
        score += 10

    # Stress test results
    stress_tests = liquidity["stress_tests"]
    pass_count = sum(1 for result in stress_tests.values() if result == "Pass")
    if pass_count == 3:
        score += 40
    elif pass_count == 2:
        score += 30
    elif pass_count == 1:
        score += 20
    else:
        score += 10

    # Redemption speed
    redemption_days = liquidity["redemption_speed_days"]
    if redemption_days <= 1:
        score += 20
    elif redemption_days <= 3:
        score += 15
    elif redemption_days <= 7:
        score += 10
    else:
        score += 5

    return min(100, score)


def calculate_compliance_risk(compliance: Dict[str, Any]) -> float:
    """Calculate compliance risk score (0-100, lower is better)"""
    score = 0

    # AML/KYC new customers (lower is better for risk)
    new_customers = compliance["aml_kyc_new_customers"]
    if new_customers <= 5000:
        score += 30
    elif new_customers <= 10000:
        score += 25
    elif new_customers <= 20000:
        score += 20
    else:
        score += 15

    # SARs filed (higher monitoring is better)
    sars_filed = compliance["aml_kyc_sars_filed"]
    if sars_filed >= 20:
        score += 25
    elif sars_filed >= 10:
        score += 20
    elif sars_filed >= 5:
        score += 15
    else:
        score += 10

    # Transaction monitoring
    flagged_txns = compliance["txn_monitoring_flagged"]
    if flagged_txns >= 200:
        score += 25
    elif flagged_txns >= 100:
        score += 20
    elif flagged_txns >= 50:
        score += 15
    else:
        score += 10

    # Escalations
    escalations = compliance["txn_monitoring_escalations"]
    if escalations >= 20:
        score += 25
    elif escalations >= 10:
        score += 15
    elif escalations >= 5:
        score += 10
    else:
        score += 5

    return min(100, score)


def calculate_audit_risk(audit: Dict[str, Any]) -> float:
    """Calculate audit risk score (0-100, lower is better)"""
    score = 0

    # Audit status
    status = audit["status"].lower()
    if status == "completed":
        score += 40
    elif status == "ongoing":
        score += 25
    elif status == "pending":
        score += 15
    else:
        score += 10

    # Auditor reputation
    auditor = audit["auditor_name"].lower()
    top_auditors = ["deloitte", "pwc", "ey", "kpmg", "grant thornton"]
    if any(top in auditor for top in top_auditors):
        score += 30
    else:
        score += 20

    # Audit opinion
    opinion = audit["opinion"].lower()
    if opinion == "unqualified":
        score += 30
    elif opinion == "qualified":
        score += 20
    elif opinion == "pending":
        score += 15
    else:
        score += 10

    return min(100, score)


def calculate_volatility_risk(volatility: Dict[str, Any]) -> float:
    """Calculate volatility risk score (0-100, lower is better)"""
    score = 0

    # 30-day rolling standard deviation vs peg
    stddev = volatility["30d_rolling_stddev_vs_peg"]
    if stddev <= 0.001:
        score += 50
    elif stddev <= 0.002:
        score += 40
    elif stddev <= 0.005:
        score += 30
    elif stddev <= 0.01:
        score += 20
    else:
        score += 10

    # Volume volatility
    vol_vol = volatility["volume_volatility"]
    if vol_vol <= 0.3:
        score += 50
    elif vol_vol <= 0.5:
        score += 40
    elif vol_vol <= 0.7:
        score += 30
    else:
        score += 20

    return min(100, score)


def score_to_letter_grade(score: float) -> str:
    """Convert numerical score to letter grade"""
    if score >= 90:
        return "A+"
    elif score >= 85:
        return "A"
    elif score >= 80:
        return "A-"
    elif score >= 75:
        return "B+"
    elif score >= 70:
        return "B"
    elif score >= 65:
        return "B-"
    elif score >= 60:
        return "C+"
    elif score >= 55:
        return "C"
    elif score >= 50:
        return "C-"
    else:
        return "D"


def get_risk_level(score: float) -> str:
    """Convert score to risk level description"""
    if score >= 80:
        return "Low Risk"
    elif score >= 60:
        return "Moderate Risk"
    elif score >= 40:
        return "High Risk"
    else:
        return "Very High Risk"


def compute_risk_score(coin: str) -> Optional[Dict[str, Any]]:
    """
    Calculate comprehensive risk score for a stablecoin.

    Args:
        coin (str): Name of the stablecoin (e.g., 'USDC', 'USDT')

    Returns:
        Dict containing overall risk score and breakdown by category, or None if coin not found
    """
    data = get_stablecoin_data(coin)
    if not data:
        return None

    try:
        risk_scores = {}

        # 1. RESERVE RISK (Weight: 30%)
        reserve_score = calculate_reserve_risk(data["reserves"])
        risk_scores["reserve_risk"] = reserve_score

        # 2. LIQUIDITY RISK (Weight: 25%)
        liquidity_score = calculate_liquidity_risk(data["risk_liquidity"])
        risk_scores["liquidity_risk"] = liquidity_score

        # 3. COMPLIANCE RISK (Weight: 20%)
        compliance_score = calculate_compliance_risk(data["compliance"])
        risk_scores["compliance_risk"] = compliance_score

        # 4. AUDIT RISK (Weight: 15%)
        audit_score = calculate_audit_risk(data["audit"])
        risk_scores["audit_risk"] = audit_score

        # 5. VOLATILITY RISK (Weight: 10%)
        volatility_score = calculate_volatility_risk(data["issuance"]["volatility"])
        risk_scores["volatility_risk"] = volatility_score

        # Calculate weighted overall score
        weights = {
            "reserve_risk": 0.30,
            "liquidity_risk": 0.25,
            "compliance_risk": 0.20,
            "audit_risk": 0.15,
            "volatility_risk": 0.10,
        }

        overall_score = sum(
            risk_scores[category] * weights[category] for category in weights
        )

        # Convert to letter grade
        letter_grade = score_to_letter_grade(overall_score)

        return {
            "coin_name": coin,
            "overall_risk_score": round(overall_score, 2),
            "letter_grade": letter_grade,
            "risk_level": get_risk_level(overall_score),
            "risk_breakdown": risk_scores,
            "weights": weights,
            "analysis_date": data.get("report_metadata", {})
            .get("reporting_period", {})
            .get("submission_date", "Unknown"),
        }

    except Exception as e:
        print(f"Error calculating risk score for {coin}: {e}")
        return None


def get_all_stablecoin_risk_scores() -> Dict[str, Any]:
    """Get risk scores for all available stablecoins."""
    if not hasattr(genius_configs, "DATA") or not genius_configs.DATA:
        return {}

    all_scores = {}
    for stablecoin in genius_configs.DATA["stablecoins"]:
        coin_name = stablecoin["name"]
        risk_data = compute_risk_score(coin_name)
        if risk_data:
            all_scores[coin_name] = risk_data

    return all_scores


def check_genius_compliance(coin: str) -> bool:
    """
    Check if a stablecoin meets genius compliance standards.

    Args:
        coin (str): Name of the stablecoin

    Returns:
        bool: True if compliant, False otherwise
    """
    risk_data = compute_risk_score(coin)
    if not risk_data:
        return False

    # Define compliance thresholds
    min_score = 70  # Minimum score to be considered compliant
    min_grade = "B"  # Minimum letter grade

    # Check numerical score
    score_compliant = risk_data["overall_risk_score"] >= min_score

    # Check letter grade (convert to comparable format)
    grade_order = ["D", "C-", "C", "C+", "B-", "B", "B+", "A-", "A", "A+"]
    current_grade = risk_data["letter_grade"]
    grade_compliant = grade_order.index(current_grade) >= grade_order.index(min_grade)

    return score_compliant and grade_compliant


# def get_risk_comparison(coins: list) -> Dict[str, Any]:
#     """
#     Compare risk scores between multiple stablecoins.

#     Args:
#         coins (list): List of stablecoin names to compare

#     Returns:
#         Dict containing comparison data
#     """
#     comparison = {
#         "coins_compared": coins,
#         "risk_scores": {},
#         "rankings": [],
#         "summary": {},
#     }

#     # Get risk scores for all requested coins
#     for coin in coins:
#         risk_data = compute_risk_score(coin)
#         if risk_data:
#             comparison["risk_scores"][coin] = risk_data

#     # Create rankings
#     if comparison["risk_scores"]:
#         sorted_coins = sorted(
#             comparison["risk_scores"].items(),
#             key=lambda x: x[1]["overall_risk_score"],
#             reverse=True,
#         )

#         comparison["rankings"] = [
#             {
#                 "rank": i + 1,
#                 "coin": coin,
#                 "score": data["overall_risk_score"],
#                 "grade": data["letter_grade"],
#                 "risk_level": data["risk_level"],
#             }
#             for i, (coin, data) in enumerate(sorted_coins)
#         ]

#         # Summary statistics
#         scores = [
#             data["overall_risk_score"] for data in comparison["risk_scores"].values()
#         ]
#         comparison["summary"] = {
#             "average_score": round(sum(scores) / len(scores), 2),
#             "highest_score": max(scores),
#             "lowest_score": min(scores),
#             "score_range": max(scores) - min(scores),
#         }

#     return comparison


def get_payment_requirements():
    return merchant_configs.PAYMENT_REQUIREMENT
