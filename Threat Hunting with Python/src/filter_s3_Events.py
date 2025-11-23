import json
import pandas as pd
from pathlib import Path
from io import StringIO

# Base paths (relative to this script)
BASE_DIR = Path(__file__).resolve().parents[1]   # project root (…/Threat hunting with python)
DATA_DIR = BASE_DIR / "data"

LOG_FILE = DATA_DIR / "ec2_proxy_s3_exfiltration" / "ec2_proxy_s3_exfiltration_2020-09-14011940.json"

S3_ALL = DATA_DIR / "s3_all_events.csv"
S3_ALL_JSON = DATA_DIR / "s3_all_events.json"

S3_MANAGEMENT = DATA_DIR / "s3_management_events.csv"
S3_MANAGEMENT_JSON = DATA_DIR / "s3_management_events.json"

S3_DATA = DATA_DIR / "s3_data_events.csv"
S3_DATA_JSON = DATA_DIR / "s3_data_events.json"


# Define which S3 operations belong to which category
S3_MANAGEMENT_EVENTS = {
    "ListBuckets"
}

S3_DATA_EVENTS = {
    "ListObjects",
    "GetObject"
}

def load_as_dataframe(file_path):
    """Loads the entire JSON Lines dataset as a pandas DataFrame."""
    return pd.read_json(file_path, lines=True)

def filter_s3_events(df: pd.DataFrame) -> pd.DataFrame:
    """
    Returns only the rows where eventSource corresponds to S3.
    """
    s3_df = df[df["eventSource"] == "s3.amazonaws.com"].copy()
    return s3_df

def split_s3_categories(s3_df: pd.DataFrame):
    """
    Splits S3 events into management vs data-access DataFrames.
    """
    management_df = s3_df[s3_df["eventName"].isin(S3_MANAGEMENT_EVENTS)].copy()
    data_df = s3_df[s3_df["eventName"].isin(S3_DATA_EVENTS)].copy()

    return management_df, data_df


if __name__ == "__main__":

    #print("Loading full CloudTrail dataset...")
    df = load_as_dataframe(LOG_FILE)
    #print(f"   Total events: {len(df)}")

    #print("\nFiltering for S3-related events (eventSource == 's3.amazonaws.com')...")
    s3_df = filter_s3_events(df)
    #print(f"   S3 events: {len(s3_df)}")

    #print("\nUnique S3 event names:")
    #print(s3_df["eventName"].value_counts())

    print("\n📁 Splitting S3 events into categories...")
    management_df, data_df = split_s3_categories(s3_df)

    print(f"   Management events: {len(management_df)}")
    print(f"   Data-access events: {len(data_df)}")

    # Save results
    management_df.to_csv(S3_MANAGEMENT, index=False)
    management_df.to_json(S3_MANAGEMENT_JSON, orient="records", lines=True, date_format="iso")

    data_df.to_csv(S3_DATA, index=False)
    data_df.to_json(S3_DATA_JSON, orient="records", lines=True, date_format="iso")

    s3_df.to_csv(S3_ALL, index=False)
    s3_df.to_json(S3_ALL_JSON, orient="records", lines=True, date_format="iso")

    print("\n💾 Saved filtered files to /data/:")
    print(f"   - All S3 events:       {S3_ALL.name}")
    print(f"   - Management events:   {S3_MANAGEMENT.name}")
    print(f"   - Data-access events:  {S3_DATA.name}")


