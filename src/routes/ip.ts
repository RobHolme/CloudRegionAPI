import { Router, Request, Response } from "express";
import { TestIPv4Address, TestPrivateAddress, TestIpInSubnet } from '../util/ip-utils';
import { GetCloudProviderSubnets, cloudProviderJSON } from '../util/cloudprovider-utils'
const router = Router();

// -----------------------------
// Get IP address router
// Use a path parameter to retrieve the IP address to query. e.g.  http://server/ip/20.340.54.4
// -----------------------------
router.get("/:ip", (req: Request, res: Response) => {
  const ipAddress = req.params.ip;
  var jsonResult : Object[] = [];
  res.setHeader('content-type', 'application/json');

  // return error if the string does not match the format of an IPv4 address
  if (TestIPv4Address(ipAddress)) {
    // return an error for private addresses - likely to be private endpoints
    if (TestPrivateAddress(ipAddress) == true) {
      res.status(404).json({ message: "IPv4 Address is a reserved address" });
      return;
    }
    // get the cloud provider subnets (and region/service), filtered on the first octet of the IP Address matching the start of the subnet network address 
    var CloudProviderDetails: cloudProviderJSON[] = GetCloudProviderSubnets('./src/cloudproviders/Azure.json', ipAddress.split(".")[0]);
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/AWS.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/AWS.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/Azure.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/GoogleCloud.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/OCI.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/Akamai.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/CloudFlare.json', ipAddress.split(".")[0]));

    CloudProviderDetails.forEach((currentSubnet: cloudProviderJSON) => {
      if (TestIpInSubnet(ipAddress, currentSubnet.ip_prefix)) {
        jsonResult.push(currentSubnet);
      }
    });

    res.send(JSON.stringify(jsonResult, null, 2));
    //res.send(TestIpInSubnet(ipAddress, "20.0.0.0/24"));
  } else {
    res.status(404).json({ message: "IPv4 Address failed validation" });
  }
});

export default router;