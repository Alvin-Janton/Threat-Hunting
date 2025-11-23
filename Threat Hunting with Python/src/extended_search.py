import json
import pandas as pd
from pathlib import Path

# Base project paths
BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BASE_DIR / "data"

# Full original dataset
LOG_FILE = DATA_DIR / "ec2_proxy_s3_exfiltration" / "ec2_proxy_s3_exfiltration_2020-09-14011940.json"

# Output files for investigation results (JSONL instead of CSV)
OUT_PRINCIPAL = DATA_DIR / "search_principalId.jsonl"
OUT_ACCESSKEY = DATA_DIR / "search_accessKeyId.jsonl"
OUT_USERAGENT = DATA_DIR / "search_userAgent.jsonl"
OUT_COMBINED_JSON = DATA_DIR / "extended_search_results.jsonl"

# Indicators extracted from enrichment step
COMPROMISED_PRINCIPAL = "AROA5FLZVX4OAMSW6BCRH:i-0317f6c6b66ae9c40"
COMPROMISED_ACCESSKEY = "ASIA5FLZVX4OPVKKVBMX"
COMPROMISED_USERAGENT = "[aws-cli/1.18.136 Python/3.8.5 Darwin/19.5.0 botocore/1.17.59]"


def load_full_dataset(path: Path) -> pd.DataFrame:
    """Loads full CloudTrail JSON Lines dataset."""
    return pd.read_json(path, lines=True)


def safe_get(value, key, default=None):
    """Helper: safely access nested dict values."""
    if isinstance(value, dict):
        return value.get(key, default)
    return default


def save_jsonl(df: pd.DataFrame, path: Path):
    """Writes a DataFrame to JSONL."""
    df.to_json(path, orient="records", lines=True, date_format="iso")


if __name__ == "__main__":
    print("📂 Loading full dataset...")
    df = load_full_dataset(LOG_FILE)
    print(f"   Total events: {len(df)}")

    # Extract nested fields for searching
    df["principalId"] = df["userIdentity"].apply(lambda x: safe_get(x, "principalId"))
    df["accessKeyId"] = df["userIdentity"].apply(lambda x: safe_get(x, "accessKeyId"))
    df["ua"] = df["userAgent"]

    print("\nRunning independent pivot searches...")

    # ---- Pivot 1: principalId ----
    pivot_principal = df[df["principalId"] == COMPROMISED_PRINCIPAL]
    save_jsonl(pivot_principal, OUT_PRINCIPAL)

    # ---- Pivot 2: accessKeyId ----
    pivot_access = df[df["accessKeyId"] == COMPROMISED_ACCESSKEY]
    save_jsonl(pivot_access, OUT_ACCESSKEY)

    # ---- Pivot 3: userAgent ----
    pivot_ua = df[df["ua"] == COMPROMISED_USERAGENT]
    save_jsonl(pivot_ua, OUT_USERAGENT)

    # Combined JSONL for full review
    combined = pd.concat([pivot_principal, pivot_access, pivot_ua],ignore_index=True)

    # Use eventID (hashable string) to drop duplicates safely
    if "eventID" in combined.columns:
        combined = combined.drop_duplicates(subset=["eventID"])

    save_jsonl(combined, OUT_COMBINED_JSON)

    print("\n📊 Search results:")
    print(f"   By principalId:  {len(pivot_principal)} events")
    print(f"   By accessKeyId:  {len(pivot_access)} events")
    print(f"   By userAgent:    {len(pivot_ua)} events")
    print(f"   Combined unique: {len(combined)} events")

    print("\n💾 Saved output files:")
    print(f"   - {OUT_PRINCIPAL.name}")
    print(f"   - {OUT_ACCESSKEY.name}")
    print(f"   - {OUT_USERAGENT.name}")
    print(f"   - {OUT_COMBINED_JSON.name}")

    print("\n✨ Extended search complete.")
