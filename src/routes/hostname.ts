import dns from 'node:dns';
import { Router, Request, Response } from "express";
import { cloudProviderSearchResult, SearchAllCloudProviders } from '../util/cloudprovider-utils';
import { TestPrivateAddress } from '../util/ip-utils';

const router = Router();

// -----------------------------
// Hostname name router (/:hostname)
// Use a path parameter to resolve a DNS name to IPv4 Address(s). e.g.  http://server/hostname/www.example.com
// Also accepts IPv4 Addresses.
// Returns result as string[]. 404 response code returned if no results found.
// -----------------------------
router.get("/:hostname", (req: Request, res: Response) => {
    const hostname = req.params.hostname.trim();
    res.setHeader('content-type', 'application/json');

    // regex to validate input, detect IP Address or Hostname
    const invalidCharacterRegEx: RegExp = new RegExp("\/|\\\\|\"|'|;");
    const hostnameRegex: RegExp = new RegExp("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$");
    const ip4SubnetRegEx: RegExp = new RegExp('^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

    // reject hostnames containing the following characters / \ " ' ;
    if (invalidCharacterRegEx.test(hostname)) {
        res.status(404).json({ message: "DNS name or IP Address not valid" });
        return;
    }
    // detect IPv4 Addresses
    if (ip4SubnetRegEx.test(hostname)) {
        // return an error for private addresses - likely to be private endpoints
        if (TestPrivateAddress(hostname) == true) {
            res.status(404).json({ message: `IPv4 Address (${hostname}) is a reserved address` });
            return;
        }
        var ipSearchResults: cloudProviderSearchResult[] = SearchAllCloudProviders(hostname);
        // return the JSON result
        if (ipSearchResults.length > 0) {
            res.send(JSON.stringify(ipSearchResults, null, 2));
            return;
        }
        // return 404 if no results found
        else {
            res.status(404).json({ message: "No results found" });
            return;
        }
    }
    // detect DNS name
    else if (hostnameRegex.test(hostname)) {
        // resolve the hostname to an IPv4 address(s) - could be multiple A records. IPv6 not supported by this API.
        dns.resolve4(hostname, (err, addresses) => {
            var hostnameSearchResults: cloudProviderSearchResult[] = [];
            if (err) {
                res.status(404).json({ message: "DNS lookup failed" });
                return;
            }
            // get the cloud provider subnets (and region/service) for each IP address resolved from the hostname
            for (var i = 0; i < addresses.length; i++) {   
                // test for private addresses. Return 404 if private range detected (ignore other IPs - assume they all will be private for a single host record - such as private endpoints / internal load balancers)               
                if (TestPrivateAddress(addresses[i]) == true) {
                        res.status(404).json({ message: `IPv4 Address (${addresses[i]}) is a reserved address` });
                        return;
                }  
                else {
                    var cloudProviderResults: cloudProviderSearchResult[] = SearchAllCloudProviders(addresses[i]);
                    hostnameSearchResults.push(...cloudProviderResults);
                }   
            }
            // return the JSON result
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
    }
    else {    
        // if reaching this code block assume input failed to match any either IP or hostname Regex
        res.status(404).json({ message: "DNS name or IPv4 address not valid" });
        return;
    }
});

export default router;