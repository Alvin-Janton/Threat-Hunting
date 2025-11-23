import json
import pandas as pd
from pathlib import Path

# Base paths
BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BASE_DIR / "data"

# Original log file (same as before)
LOG_FILE = DATA_DIR / "ec2_proxy_s3_exfiltration" / "ec2_proxy_s3_exfiltration_2020-09-14011940.json"

# Output: cleaned/enriched S3 events
S3_ENRICHED = DATA_DIR / "s3_enriched_events.csv"
S3_ENRICHED_JSON = DATA_DIR / "s3_enriched_events.json"

def load_full_dataset(file_path: Path) -> pd.DataFrame:
    """
    Loads the full CloudTrail JSON Lines dataset into a pandas DataFrame.
    """
    df = pd.read_json(file_path, lines=True)
    return df

def filter_s3_events(df: pd.DataFrame) -> pd.DataFrame:
    """
    Returns only the rows where eventSource corresponds to S3.
    """
    s3_df = df[df["eventSource"] == "s3.amazonaws.com"].copy()
    return s3_df

def ensure_dict(value):
    """
    Ensures the value is a dictionary.
    If it's a JSON string, tries to json.loads() it.
    If it's already a dict or is null/NaN, returns it as-is or {}.
    """
    if isinstance(value, dict):
        return value
    if pd.isna(value):
        return {}
    if isinstance(value, str):
        value = value.strip()
        if not value:
            return {}
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return {}
    return {}

def flatten_s3_event(row: pd.Series) -> dict:
    """
    Flattens a single S3 CloudTrail event into a simpler dict with
    only the fields needed for investigation.
    """
    user_identity = ensure_dict(row.get("userIdentity"))
    req_params = ensure_dict(row.get("requestParameters"))

    # Basic top-level fields
    event_time = row.get("@timestamp")
    event_name = row.get("eventName")
    source_ip = row.get("sourceIPAddress")
    region = row.get("awsRegion")
    user_agent = row.get("userAgent")

    # User identity fields
    user_type = user_identity.get("type")
    user_name = user_identity.get("userName")
    principal_id = user_identity.get("principalId")
    access_key_id = user_identity.get("accessKeyId")

    # Request parameters: bucket + object key
    bucket_name = req_params.get("bucketName")
    object_key = req_params.get("key") or req_params.get("objectKey")

    return {
        "timestamp": event_time,
        "eventName": event_name,
        "bucketName": bucket_name,
        "objectKey": object_key,
        "sourceIPAddress": source_ip,
        "awsRegion": region,
        "userType": user_type,
        "userName": user_name,
        "principalId": principal_id,
        "accessKeyId": access_key_id,
        "userAgent": user_agent,
    }

if __name__ == "__main__":
    print("Loading full CloudTrail dataset...")
    df = load_full_dataset(LOG_FILE)
    print(f"   Total events: {len(df)}")

    print("\nFiltering for S3-related events...")
    s3_df = filter_s3_events(df)
    print(f"   S3 events: {len(s3_df)}")

    print("\nFlattening S3 events into enriched rows...")
    enriched_rows = [flatten_s3_event(row) for _, row in s3_df.iterrows()]
    enriched_df = pd.DataFrame(enriched_rows)

    # Convert eventTime to datetime if possible
    if "timestamp" in enriched_df.columns:
        enriched_df["timestamp"] = pd.to_datetime(enriched_df["timestamp"], errors="coerce")

    # Save to CSV
    S3_ENRICHED.parent.mkdir(parents=True, exist_ok=True)
    enriched_df.to_csv(S3_ENRICHED, index=False)
    enriched_df.to_json(S3_ENRICHED_JSON, orient="records", lines=True, date_format="iso")

    print(f"\nSaved enriched S3 events to: {S3_ENRICHED}")
    print(f"Saved enriched JSON to: {S3_ENRICHED_JSON}")
    print("   Columns included:")
    print(list(enriched_df.columns))

