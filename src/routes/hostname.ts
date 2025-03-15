import dns from 'node:dns';
import { Router, Request, Response } from "express";
import { cloudProviderJSON, SearchAllCloudProviders } from '../util/cloudprovider-utils';

const router = Router();

// -----------------------------
// Resolve DNS name router (/:hostname)
// Use a path parameter to resolve a DNS name to IPv4 Address(s). e.g.  http://server/hostname/www.example.com
// Returns result as string[]. Empty array if no match found.
// -----------------------------
router.get("/:hostname", (req: Request, res: Response) => {
    const hostname = req.params.hostname;
    // resolve the hostname to an IPv4 address(s) - could be multiple A records. IPv6 not supported by this API.
    dns.resolve4(hostname, (err, addresses) => {
        var matchingRegions: cloudProviderJSON[] = [];
        if (err) {
            res.status(404).json({ message: "DNS lookup failed" });
            return
        }

        // get the cloud provider subnets (and region/service) for each IP address resolved from the hostname
        for (var i = 0; i < addresses.length; i++) {
            var cloudProviderResults: cloudProviderJSON[] = SearchAllCloudProviders(addresses[i]);
            matchingRegions.push(...cloudProviderResults);
        }
        // return the JSON result
        res.send(JSON.stringify(matchingRegions, null, 2));

    });
});

export default router;