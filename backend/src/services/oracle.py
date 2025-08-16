from datetime import datetime
from web3 import HTTPProvider, Web3
from src.configs import flare_configs


def get_stablecoin_price(stablecoin: str) -> float:
    """
    Fetch the price of a stablecoin from a blockchain or API.

    Args:
        stablecoin (str): The symbol of the stablecoin (e.g., 'USDT', 'USDC').

    Returns:
        float: The price of the stablecoin.
    """
    web3 = Web3(HTTPProvider(flare_configs.RPC_URL))

    ftsov2 = web3.eth.contract(
        address=web3.to_checksum_address(flare_configs.FTSOV2_ADDRESS),
        abi=flare_configs.ABI,
    )
    feed_id = flare_configs.STABLECOIN_FEED_IDS.get(stablecoin)
    if not feed_id:
        raise ValueError(f"Stablecoin {stablecoin} not supported.")

    # getFeedById returns stablecoin price no decimals, number of decimals, and timestamp
    raw_value, decimals, timestamp = ftsov2.functions.getFeedById(feed_id).call()

    # Convert raw value to true decimal price
    price = raw_value / (10**decimals)

    # Convert timestamp to datetime object.
    date = datetime.fromtimestamp(timestamp)
    return (price, date)
