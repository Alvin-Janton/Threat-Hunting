| Category                     | Command                                                                 |
|-----------------------------|-------------------------------------------------------------------------|
| Load Data                   | df = pd.read_csv("filename.csv")                                        |
| View Data                   | df.head()                                                               |
| View Data                   | df.tail(10)                                                             |
| View Data                   | df.columns                                                              |
| View Data                   | df.shape                                                                |
| View Data                   | df.info()                                                               |
| Filter Rows                 | df[df['eventName'] == 'GetObject']                                      |
| Filter Rows                 | df[df["sourceIPAddress"].str.contains("192.")]                          |
| Filter Rows                 | df[df["@timestamp"] >= "2020-09-14T00:00:00Z"]                          |
| Select Columns              | df[["@timestamp", "eventName", "sourceIPAddress"]]                      |
| Sort and Group              | df.sort_values(by="sourceIPAddress")                                    |
| Sort and Group              | df.groupby("eventName").size()                                          |
| Sort and Group              | df.groupby("eventName").count()                                         |
| Clean or Replace            | df.dropna()                                                             |
| Clean or Replace            | df.fillna("Unknown")                                                    |
| Clean or Replace            | df["userAgent"].replace("-", "Unknown")                                 |
| Export                      | df.to_csv("output.csv", index=False)                                    |
| Bonus: Threat-Hunting Use Case | df[(df["eventName"] == "GetObject") & (df["sourceIPAddress"] != "your-ip")] |
