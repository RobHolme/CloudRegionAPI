# CloudRegionAPI
API to return the cloud provider and region for a given IPv4 address. Multiple results may be returned - some subnet scopes overlap. 


The API provides the following path based parameters:

>URL examples assume API is running on localhost (127.0.0.1). Replace with the URL of the container / node app this solution is deployed to.
## IP Parameter

__```GET http://127.0.0.1/ip/{IPv4Addres}```__

{IPvAddress} - The IPv4 address of the cloud service.

e.g. ```curl http://127.0.0.1/ip/34.37.1.5```

### Authentication
No authentication required.

### Body
Results returned as a JSON payload

```JSON
[
  {
    "ip_prefix": "34.37.0.0/16",
    "Region": "us-west8",
    "service": "Google Cloud",
    "SubnetSize": "16",
    "CloudProvider": "Google Cloud"
  }
]
```
Multiple results may be returned. Some cloud providers include super nets and smaller subnets that a given IP may match both - or sometimes the same subnet is repeated with different service tags. e.g:

```yaml
[
  {
    "ip_prefix": "3.16.0.0/14",
    "region": "us-east-2",
    "service": "AMAZON",
    "SubnetSize": "14",
    "CloudProvider": "AWS"
  },
  {
    "ip_prefix": "3.16.0.0/14",
    "region": "us-east-2",
    "service": "EC2",
    "SubnetSize": "14",
    "CloudProvider": "AWS"
  }
]
```
## Info Parameter
Displays information about the client connection.

__```GET http://127.0.0.1/info```__


e.g. ```curl http://127.0.0.1/info```

### Authentication
No authentication required.

### Body
Client information returned as a JSON payload

```JSON
{
  "ClientIP": "::ffff:127.0.0.1",
  "Protocol": "http",
  "HTTPVersion": "1.1",
  "Headers": {
    "host": "127.0.0.1",
    "user-agent": "curl/8.10.1",
    "accept": "*/*"
  }
}
```
<br>
<br>

## Notes

IP ranges and region details for each cloud provider are sourced from:
* https://ip-ranges.amazonaws.com/ip-ranges.json
* https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519
* https://www.gstatic.com/ipranges/cloud.json
* https://www.cloudflare.com/ips-v4/#
* https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json
* https://ipinfo.io/widget/demo/akamai.com?dataset=ranges

<br>
<br>


# Build and run via local node.js environment
### Clone the repo
```
$ git clone https://github.com:RobHolme/CloudRegionAPI.git
$ cd CloudRegionAPI
```

### Install release dependencies:
```$ npm install express @types/express --save```

### Install Dev dependencies (needed for build script)
```$ npm install --only=dev```

### Optional: Update the JSON files defining the cloud provider's subnets, regions, and services
>The repo files are updated 12am every Sunday via a GitHub action, so this step can be skipped unless the very latest updates are needed.

Requires powershell 7 (or greater) to run the script. If building on Windows, do not use Powershell 5.1 as the performance will be exceedingly slow. 


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


# Build and run via local docker engine

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
$ sudo docker run --name CloudRegionAPI --publish 80:80 --env NODE_ENV=production --detach robholme/cloud-region-api:latest
```