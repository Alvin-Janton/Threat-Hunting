import json
import pandas as pd
from pathlib import Path
from io import StringIO

# Base paths (relative to this script)
BASE_DIR = Path(__file__).resolve().parents[1]   # project root (…/Threat hunting with python)
DATA_DIR = BASE_DIR / "data"

LOG_FILE = DATA_DIR / "ec2_proxy_s3_exfiltration" / "ec2_proxy_s3_exfiltration_2020-09-14011940.json"
RAW_LOGS_PREVIEW = DATA_DIR / "raw_preview.json"
DATAFRAME_PREVIEW = DATA_DIR / "df_preview.md"


def preview_raw_events(file_path, num_lines=5):
    """Reads the first N lines of a CloudTrail JSON Lines file."""
    events = []
    with open(file_path, "r", encoding="utf-8") as f:
        for _ in range(num_lines):
            line = f.readline()
            if not line:
                break
            events.append(json.loads(line))
    return events


def save_preview_to_json(events, output_path):
    """Save pretty-printed raw events to a JSON file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as outfile:
        for idx, event in enumerate(events, start=1):
            outfile.write(f"--- Event {idx} ---\n")
            outfile.write(json.dumps(event, indent=2))
            outfile.write("\n\n")


def generate_markdown_summary(df, output_path):
    """Exports df.head(), df.info(), and df.columns into a markdown file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Capture df.info() output
    buffer = StringIO()
    df.info(buf=buffer)
    info_text = buffer.getvalue()

    md = []
    md.append("# Dataset Overview\n")
    md.append("---\n\n")

    md.append("## 🔹 DataFrame Head (first 5 rows)\n")
    md.append("```\n")
    md.append(str(df.head()))
    md.append("\n```\n\n")

    md.append("## 🔹 DataFrame Info\n")
    md.append("```\n")
    md.append(info_text)
    md.append("```\n\n")

    md.append("## 🔹 Columns\n")
    md.append("```\n")
    md.append(str(df.columns.tolist()))
    md.append("\n```\n\n")

    with open(output_path, "w", encoding="utf-8") as f:
        f.writelines(md)


def load_as_dataframe(file_path):
    """Loads the entire JSON Lines dataset as a pandas DataFrame."""
    return pd.read_json(file_path, lines=True)


if __name__ == "__main__":
    print("🔍 Previewing raw events...")
    sample_events = preview_raw_events(LOG_FILE, 5)

    print("📄 Saving preview JSON...")
    #save_preview_to_json(sample_events, RAW_LOGS_PREVIEW)

    print("📊 Loading dataset into DataFrame...")
    df = load_as_dataframe(LOG_FILE)

    print("📝 Generating markdown summary file...")
    generate_markdown_summary(df, DATAFRAME_PREVIEW)

    print(f"\n✨ Done!")
    print(f"   Raw preview saved to: {RAW_LOGS_PREVIEW}")
    print(f"   Markdown summary saved to: {DATAFRAME_PREVIEW}")
