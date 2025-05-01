# CloudRegionAPI
API to return the cloud provider and region for a given IPv4 address or hostname. Multiple results may be returned - some subnet scopes overlap. 

> A webpage page that consumes the API is published to the root of the website. Connect to the website root for an example page using this API. e.g. http://127.0.0.1


The API provides the following path based parameters:

## Hostname Path

__```GET http://127.0.0.1/api/hostname/{hostname}```__

### Parameters

__hostname \<string\>__ : The DNS name or IPv4 address of the cloud service.

e.g. ```curl http://127.0.0.1/api/hostname/34.37.1.5```

e.g. ```curl http://127.0.0.1/api/hostname/example.com```

### Authentication
No authentication required.

### Responses
A 200 response code returned on success with the following JSON payload:

```json
[
  {
    "IPAddress": <string>,
    "Subnet": <string>,
    "Region": <string>,
    "Service": <string>,
    "SubnetSize": <string>,
    "CloudProvider": <string>
  }
]
```
A 404 response code is returned on failure with the following JSON payload containing the error message:
```json
{
  "Message": <string>
}
```

#### Examples

```JSON
[
  {
    "IPAddress": "34.37.1.5",
    "Subnet": "34.37.0.0/16",
    "Region": "us-west8",
    "service": "Google Cloud",
    "SubnetSize": "16",
    "CloudProvider": "Google Cloud"
  }
]
```
Multiple results may be returned. 
- DNS names may resolve to multiple IP addresses.
- Some cloud providers include super nets and smaller subnets that a given IP may match both.
- The same subnet is repeated with different service tags. e.g:

```yaml
[
  {
    "IPAddress": "3.16.2.15",
    "Subnet": "3.16.0.0/14",
    "region": "us-east-2",
    "service": "AMAZON",
    "SubnetSize": "14",
    "CloudProvider": "AWS"
  },
  {
    "IPAddress": "3.16.2.15",
    "Subnet": "3.16.0.0/14",
    "region": "us-east-2",
    "service": "EC2",
    "SubnetSize": "14",
    "CloudProvider": "AWS"
  }
]
```

Failure example:
```json
{
  "Message": "DNS lookup failed"
}
```

## Subnets Path
Returns all IPv4 subnets for the specified cloud provider.

__```GET http://127.0.0.1/api/subnets/{CloudProvider}```__

### Parameters

__CloudProvider \<string\>__ : The name of the specific cloud provider. Must be one of "AWS", "Azure", "AzureGovernment", AzureChina", "AzureGermany", "OCI", "GoogleCloud", "DigitalOcean", "Akamai", or "CloudFlare"

e.g. ```curl http://127.0.0.1/api/subnets/aws```

e.g. ```curl http://127.0.0.1/api/subnets/azure```

### Authentication
No authentication required.

### Response
A 200 response code will be returned on success. Results returned as a JSON payload. All subnet ranges associated with the specified cloud provider will be returned. The JSON payload will be and array of objects of the following format:
```json
[
  {
    "Subnet": <string>,
    "Region": <string>,
    "Service": <string>,
    "SubnetSize": <string>,
    "CloudProvider": <string>
  }
]
```
On failure a 404 response code is returned the following JSON payload containing the error message:
```json
{
  "Message": <string>
}
```
### Examples
Example response is truncated for brevity.
```json
[
  {
      "Subnet": "209.199.34.0/25",
      "Region": "",
      "Service": "",
      "SubnetSize": "25",
      "CloudProvider": "Azure"
    },
    {
      "Subnet": "209.199.34.128/25",
      "Region": "",
      "Service": "",
      "SubnetSize": "25",
      "CloudProvider": "Azure"
    },
    {
      "Subnet": "209.199.35.0/25",
      "Region": "",
      "Service": "",
      "SubnetSize": "25",
      "CloudProvider": "Azure"
    },
    {
      "Subnet": "213.199.169.0/24",
      "Region": "",
      "Service": "",
      "SubnetSize": "24",
      "CloudProvider": "Azure"
    }
    .
    .
    .
]
```

## Info Path
Displays information about the client connection.


__```GET http://127.0.0.1/api/info```__

### Parameters
None.

e.g. ```curl http://127.0.0.1/api/info```

### Authentication
No authentication required.

### Response
Client information returned as a JSON payload
```json
{
  "BuildDate": <string>,
  "ClientIP": <string>,
  "Protocol": <string>,
  "HTTPVersion": <string>,
  "Headers": <object> {
  }
}
```


#### Examples

```json
{
  "BuildDate": "12-March-2025",
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
* AWS: https://ip-ranges.amazonaws.com/ip-ranges.json
* Azure (Public): https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519
* Azure (Government): https://www.microsoft.com/download/details.aspx?id=57063
* Azure (China): https://www.microsoft.com/download/details.aspx?id=57062
* Azure (Germany): https://www.microsoft.com/download/details.aspx?id=57064
* Google Cloud: https://www.gstatic.com/ipranges/cloud.json
* Oracle CLoud: https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json
* Digital Ocean: https://digitalocean.com/geo/google.csv
* CloudFlare: https://www.cloudflare.com/ips-v4/#
* Akamai: https://ipinfo.io/widget/demo/akamai.com?dataset=ranges

<br>
<br>


# Build / Run Options

## Option 1: Build and run via local node.js environment
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


<br>
<br>


## Option 2: Build and run via local docker engine

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

### Run the container from local image
```
$ sudo docker run --name CloudRegionAPI --publish 80:80 --env NODE_ENV=production --detach robholme/cloud-region-api:latest
```

## Option 3: Run published container from GitHub Container Registry

### Run the container
```
$ sudo docker run --name CloudRegionAPI --publish 80:80 --env NODE_ENV=production --detach ghcr.io/robholme/cloud-region-api:latest
```
