### Example rumble query with python client

```
python3 rumble_client.py  --output output.txt --data '
  for $doc in json-file("hdfs://analytix/project/monitoring/archive/wmarchive/raw/metric/2020/09/15")
  return $doc.data.wmaid
'
```

