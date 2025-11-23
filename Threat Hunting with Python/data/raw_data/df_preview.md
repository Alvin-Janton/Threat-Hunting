# Dataset Overview
---

## 🔹 DataFrame Head (first 5 rows)
```
                                   requestParameters                  userAgent  awsRegion   eventType  ...  resources eventCategory  additionalEventData managementEvent
0  {'DescribeInstanceTypesRequest': {'NextToken':...  console.ec2.amazonaws.com  us-east-1  AwsApiCall  ...        NaN           NaN                  NaN             NaN
1  {'filterSet': {}, 'instancesSet': {'items': [{...  console.ec2.amazonaws.com  us-east-1  AwsApiCall  ...        NaN           NaN                  NaN             NaN
2  {'filterSet': {'items': [{'valueSet': {'items'...  console.ec2.amazonaws.com  us-east-1  AwsApiCall  ...        NaN           NaN                  NaN             NaN
3  {'filterSet': {}, 'instancesSet': {'items': [{...  console.ec2.amazonaws.com  us-east-1  AwsApiCall  ...        NaN           NaN                  NaN             NaN
4  {'attribute': 'disableApiTermination', 'instan...  console.ec2.amazonaws.com  us-east-1  AwsApiCall  ...        NaN           NaN                  NaN             NaN

[5 rows x 22 columns]
```

## 🔹 DataFrame Info
```
<class 'pandas.core.frame.DataFrame'>
RangeIndex: 103 entries, 0 to 102
Data columns (total 22 columns):
 #   Column               Non-Null Count  Dtype  
---  ------               --------------  -----  
 0   requestParameters    98 non-null     object 
 1   userAgent            103 non-null    object 
 2   awsRegion            103 non-null    object 
 3   eventType            103 non-null    object 
 4   @version             103 non-null    int64  
 5   userIdentity         103 non-null    object 
 6   recipientAccountId   103 non-null    int64  
 7   responseElements     5 non-null      object 
 8   eventName            103 non-null    object 
 9   sourceIPAddress      103 non-null    object 
 10  eventSource          103 non-null    object 
 11  requestID            103 non-null    object 
 12  @timestamp           103 non-null    object 
 13  eventID              103 non-null    object 
 14  eventVersion         103 non-null    float64
 15  apiVersion           3 non-null      object 
 16  readOnly             13 non-null     float64
 17  sharedEventID        5 non-null      object 
 18  resources            14 non-null     object 
 19  eventCategory        9 non-null      object 
 20  additionalEventData  11 non-null     object 
 21  managementEvent      9 non-null      float64
dtypes: float64(3), int64(2), object(17)
memory usage: 17.8+ KB
```

## 🔹 Columns
```
['requestParameters', 'userAgent', 'awsRegion', 'eventType', '@version', 'userIdentity', 'recipientAccountId', 'responseElements', 'eventName', 'sourceIPAddress', 'eventSource', 'requestID', '@timestamp', 'eventID', 'eventVersion', 'apiVersion', 'readOnly', 'sharedEventID', 'resources', 'eventCategory', 'additionalEventData', 'managementEvent']
```

