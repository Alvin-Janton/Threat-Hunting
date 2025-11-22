import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Base directories
BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BASE_DIR / "data"
IMG_DIR = BASE_DIR / "report" / "images"

# Ensure the images directory exists
IMG_DIR.mkdir(parents=True, exist_ok=True)

# CSV paths
S3_ALL = DATA_DIR / "s3_all_events.csv"
S3_MANAGEMENT = DATA_DIR / "s3_management_events.csv"
S3_DATA = DATA_DIR / "s3_data_events.csv"

def plot_event_counts(df: pd.DataFrame, title: str, output_path: Path):
    """
    Creates a bar chart showing the count of each eventName in the DataFrame.
    """
    if "eventName" not in df.columns:
        print(f"⚠ Skipping {output_path.name}: no 'eventName' column found.")
        return

    counts = df["eventName"].value_counts()

    if counts.empty:
        print(f"⚠ Skipping {output_path.name}: no events to plot.")
        return

    plt.figure(figsize=(6, 4))
    counts.plot(kind="bar")

    plt.title(title)
    plt.xlabel("eventName")
    plt.ylabel("Count")

    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()

    print(f"✅ Saved chart: {output_path}")

if __name__ == "__main__":
    print("📊 Generating S3 visuals...\n")

    # 1. All S3 events
    if S3_ALL.exists():
        df_all = pd.read_csv(S3_ALL)
        plot_event_counts(
            df_all,
            title="All S3 Events by Type",
            output_path=IMG_DIR / "s3_all_events.png",
        )
    else:
        print(f"⚠ {S3_ALL} not found")

    # 2. S3 management events
    if S3_MANAGEMENT.exists():
        df_mgmt = pd.read_csv(S3_MANAGEMENT)
        plot_event_counts(
            df_mgmt,
            title="S3 Management Events",
            output_path=IMG_DIR / "s3_management_events.png",
        )
    else:
        print(f"⚠ {S3_MANAGEMENT} not found")

    # 3. S3 data-access events
    if S3_DATA.exists():
        df_data = pd.read_csv(S3_DATA)
        plot_event_counts(
            df_data,
            title="S3 Data-Access Events",
            output_path=IMG_DIR / "s3_data_events.png",
        )
    else:
        print(f"⚠ {S3_DATA} not found")

    print("\n✨ Done generating visuals.")
