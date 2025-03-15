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
    var matchingRegions: cloudProviderJSON[] = [];
    // resolve the hostname to an IPv4 address(s) - could be multiple A records. IPv6 not supported by this API.
    dns.resolve4(hostname, (err, addresses) => {

// MOVE THIS TO AN EXCEPTION HANDLER ?
        if (err) throw err;

        // get the cloud provider subnets (and region/service) for each IP address resolved from the hostname
        addresses.forEach((address) => {
        matchingRegions.push(...SearchAllCloudProviders(address));

        });
    });
    // return the JSON result
    res.send(JSON.stringify(matchingRegions, null, 2));
});

export default router;