import { Router, Request, Response } from "express";
import { cloudProviderSearchResult, SearchAllCloudProviders } from '../util/cloudprovider-utils';
import { TestPrivateAddress, resolveIPv4Addresses } from '../util/ip-utils';

const router = Router();

// -----------------------------
// Hostname name router (/:hostname)
// Use a path parameter to resolve a DNS name to IPv4 Address(s). e.g.  http://server/hostname/www.example.com
// Also accepts IPv4 Addresses.
// Returns result as string[]. 404 response code returned if no results found.
// -----------------------------
router.get("/:hostname", async (req: Request, res: Response) => {
    const hostname = req.params.hostname.trim();
    res.setHeader('content-type', 'application/json');

    // regex to validate input, detect IP Address or Hostname
    const invalidCharacterRegEx: RegExp = new RegExp("\/|\\\\|\"|'|;|(\\.){2,}");
    const hostnameRegex: RegExp = new RegExp("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$");
    const ip4SubnetRegEx: RegExp = new RegExp('^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    var resolvedIPAddresses: string[] | null = [];
    var hostnameSearchResults: cloudProviderSearchResult[] = [];

    // reject hostnames containing the following characters / \ " ' ;
    if (invalidCharacterRegEx.test(hostname)) {
        res.status(404).json({ message: "DNS name or IP Address not valid" });
        return;
    }
    // detect IPv4 Address
    if (ip4SubnetRegEx.test(hostname)) {
        resolvedIPAddresses.push(hostname);
    }
    // detect DNS name
    else if (hostnameRegex.test(hostname)) {
        resolvedIPAddresses = await resolveIPv4Addresses(hostname);
    }

    // get the cloud provider subnets (and region/service) for each IP address resolved from the hostname
    if (resolvedIPAddresses == null) {
        res.status(404).json({ message: "DNS lookup failed" });
        return;
    }
    else {
        for (var i = 0; i < resolvedIPAddresses.length; i++) {
            // test for private addresses. Return 404 if private range detected (ignore other IPs - assume they all will be private for a single host record - such as private endpoints / internal load balancers)               
            if (TestPrivateAddress(resolvedIPAddresses[i]) == true) {
                res.status(404).json({ message: `IPv4 Address (${resolvedIPAddresses[i]}) is a reserved address` });
                return;
            }
            else {
                var cloudProviderResults: cloudProviderSearchResult[] = SearchAllCloudProviders(resolvedIPAddresses[i]);
                hostnameSearchResults.push(...cloudProviderResults);
            }
        }
    }
    // return the JSON 
    if (hostnameSearchResults.length > 0) {
        res.send(JSON.stringify(hostnameSearchResults, null, 2));
        return;
    }
    // return 404 if no results found
    else {
        res.status(404).json({ message: "No results found" });
        return;
    }
});

export default router;