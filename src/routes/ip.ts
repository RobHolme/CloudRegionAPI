import { Router, Request, Response } from "express";
import { TestIPv4Address, TestPrivateAddress, TestIpInSubnet } from '../util/ip-utils';
import { SearchAllCloudProviders, cloudProviderJSON, cloudProviderSearchResult } from '../util/cloudprovider-utils'
const router = Router();

// -----------------------------
// Get IP address router (/:ip)
// Use a path parameter to retrieve the IP address to query. e.g.  http://server/ip/20.340.54.4
// Returns result as JSON. Empty array if no match found.
// -----------------------------
router.get("/:ip", (req: Request, res: Response) => {
  const ipAddress = req.params.ip;
  var jsonResult: Object[] = [];
  res.setHeader('content-type', 'application/json');

  // only process 'ip' parameters that are valid IPv4 addresses
  if (TestIPv4Address(ipAddress)) {
    // return an error for private addresses - likely to be private endpoints
    if (TestPrivateAddress(ipAddress) == true) {
      res.status(404).json({ message: "IPv4 Address is a reserved address" });
      return;
    }
    var CloudProviderDetails: cloudProviderSearchResult[] = SearchAllCloudProviders(ipAddress);
    // return the JSON result
    res.send(JSON.stringify(CloudProviderDetails, null, 2));
  } else {
    // return a 404 error if the IP address is not valid
    res.status(404).json({ message: "IPv4 Address failed validation" });
  }
});

export default router;