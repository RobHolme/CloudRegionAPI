# CloudRegionAPI
API to return the cloud provider and region for a given IPv4 address or hostname. Multiple results may be returned - some subnet scopes overlap. 

> A webpage page that consumes the API is published to the root of the node website. Connect to the website root for an example page using this API. e.g. http://127.0.0.1


The API provides the following path based parameters:

## IP Parameter

__```GET http://127.0.0.1/api/hostname/{hostname}```__

__hostname \<string\>__ : The DNS name or IPv4 address of the cloud service.

e.g. ```curl http://127.0.0.1/api/hostname/34.37.1.5```

e.g. ```curl http://127.0.0.1/api/hostname/example.com```

### Authentication
No authentication required.

### Body
Results returned as a JSON payload

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
    "Subnet": "3.16.0.0/14",
    "region": "us-east-2",
    "service": "AMAZON",
    "SubnetSize": "14",
    "CloudProvider": "AWS"
  },
  {
    "Subnet": "3.16.0.0/14",
    "region": "us-east-2",
    "service": "EC2",
    "SubnetSize": "14",
    "CloudProvider": "AWS"
  }
]
```
## Info Parameter
Displays information about the client connection.

__```GET http://127.0.0.1/api/info```__


e.g. ```curl http://127.0.0.1/api/info```

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

## Azure Parameter
Returns all Azure IPv4 subnets.

__```GET http://127.0.0.1/api/azure```__


### Authentication
No authentication required.

### Body
All Azure subnets returned as a JSON payload

## AWS Parameter
Returns all AWS IPv4 subnets.

__```GET http://127.0.0.1/api/aws```__


### Authentication
No authentication required.

### Body
All AWS subnets returned as a JSON payload

## OCI Parameter
Returns all Oracle Cloud (OCI) IPv4 subnets.

__```GET http://127.0.0.1/api/oci```__


### Authentication
No authentication required.

### Body
All Oracle Cloud (OCI) subnets returned as a JSON payload

## Google Parameter
Returns all Google Cloud IPv4 subnets.

__```GET http://127.0.0.1/api/google```__


### Authentication
No authentication required.

### Body
All Google Cloud subnets returned as a JSON payload

## Akamai Parameter
Returns all Akamai IPv4 subnets.

__```GET http://127.0.0.1/api/akamai```__


### Authentication
No authentication required.

### Body
All Akamai subnets returned as a JSON payload

## CloudFlare Parameter
Returns all CloudFlare IPv4 subnets.

__```GET http://127.0.0.1/api/cloudflare```__


### Authentication
No authentication required.

### Body
All CloudFlare subnets returned as a JSON payload

<br>
<br>

## Notes

>URL examples assume API is running on localhost (127.0.0.1). Replace with the URL of the container / node app this solution is deployed to.

IP ranges and region details for each cloud provider are sourced from:
* https://ip-ranges.amazonaws.com/ip-ranges.json
* https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519
* https://www.gstatic.com/ipranges/cloud.json
* https://www.cloudflare.com/ips-v4/#
* https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json
* https://ipinfo.io/widget/demo/akamai.com?dataset=ranges

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
