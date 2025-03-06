# CloudRegionAPI
API to return the cloud provider and region for a given IPv4 address. Multiple results may be returned - some subnet scopes overlap. 

IP ranges and region details for each cloud provider are sourced from:
* https://ip-ranges.amazonaws.com/ip-ranges.json
* https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519
* https://www.gstatic.com/ipranges/cloud.json
* https://www.cloudflare.com/ips-v4/#
* https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json
* https://ipinfo.io/widget/demo/akamai.com?dataset=ranges

<br>
<br>


# Running under local node.js
### Clone the repo
```
$ git clone https://github.com:RobHolme/CloudRegionAPI.git
$ cd CloudRegionAPI
```

### Install release dependencies:
```$ npm install express @types/express --save```

### Install Dev dependencies (needed for build script)
```$ npm install --only=dev```

### Update the JSON files defining the cloud provider's subnets, regions, and services
Requires powershell 7 (or greater) to run the script. If building on Windows, do not use Powershell 5.1 as the performance will be exceedingly slow. 

If this script isn't run the API will use the potentially older versions of the JSON files included in the repo.

```$ pwsh -File ./update-cloudprovidersjson.ps1```

### Build
```$ node --run build```

### Run
```$ node --run serve```

### Connect
connect to http://127.0.0.1/ip/{ipaddress}  (where {ipaddress} is the IPv4 address to search on)

example:
http://127.0.0.1/ip/20.60.182.68

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
<br>
<br>


# Running under local docker engine

### Install node build dependencies:
```bash
$ npm install express @types/express --save
$ npm install --only=dev
```

### Clone the repo
```
$ git clone https://github.com:RobHolme/CloudRegionAPI.git
$ cd CloudRegionAPI
```
### Update the JSON files defining the cloud provider's subnets, regions, and services
Requires powershell 7 (or greater) to run the script. If building on Windows, do not use Powershell 5.1 as the performance will be exceedingly slow. 

If this script isn't run the API will use the potentially older versions of the JSON files included in the repo.

```$ pwsh -File ./update-cloudprovidersjson.ps1```

### Build the container
```bash
$ sudo ./build-container.sh
```

### Run the container
```bash
$ sudo docker compose up -d
```