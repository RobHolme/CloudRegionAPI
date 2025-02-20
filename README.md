# CloudRegionAPI
API to return the cloud provider and region for a given IPv4 address. Multiple results may be returned - some subnet scopes overlap. 


## Running under local node.js

### Install release dependencies:
``` npm install express @types/express --save```

### Install Dev dependencies (needed for build script)
``npm install --only=dev``

### Build
``` node --run build```

### Run
``` node --run start```

### Connect
```http://127.0.0.1:3000/ip/{ipaddress}```

example:
http://127.0.0.1:3000/ip/20.60.182.68

Results will be returned as a JSON string. Multiple matches may be returned with overlap between larger and smaller subnets:
```json
[
  {
    "ip_prefix": "20.60.182.0/23",
    "Region": "australiaeast",
    "Service": "AzureStorage",
    "SubnetSize": "23",
    "CloudProvider": "Azure"
  },
  {
    "ip_prefix": "20.60.0.0/16",
    "Region": "",
    "Service": "AzureStorage",
    "SubnetSize": "16",
    "CloudProvider": "Azure"
  }
]
```
