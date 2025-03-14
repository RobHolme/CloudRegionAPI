import dns from 'node:dns';

import { Router, Request, Response } from "express";

const router = Router();

// -----------------------------
// Resolve DNS name router (/:hostname)
// Use a path parameter to resolve a DNS name to IPv4 Address(s). e.g.  http://server/hostname/www.example.com
// Returns result as string[]. Empty array if no match found.
// -----------------------------
router.get("/:hostname", (req: Request, res: Response) => {
    const hostname = req.params.hostname;
    var jsonResult: Object[] = [];

    dns.resolve4(hostname, (err, addresses) => {
        if (err) throw err;

        // get the cloud provider subnets (and region/service) for each IP address
        addresses.forEach(async (a) => {
            const response = await fetch(`/ip/${addresses}`);
            const jsonData = await response.json();
            if (jsonData.length > 0) {
                jsonResult.push(jsonData);
            }
        });
    });
    // return the JSON result
    res.send(JSON.stringify(jsonResult, null, 2));
});

export default router;