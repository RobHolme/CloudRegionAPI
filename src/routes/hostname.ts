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
    console.log(`Resolving ${hostname}`);
    var jsonResult: Object[] = [];

    console.log(JSON.stringify(req.headers));

    dns.resolve4(hostname, (err, addresses) => {
        if (err) throw err;

        // get the cloud provider subnets (and region/service) for each IP address
        addresses.forEach((address) => {

            console.log(`Querying ${address}`);
// RELATIVE PATH NOT SUPPORTED !!!           
            fetch(`/ip/${address}`)
                .then((response) => {
                        jsonResult.push(response.json());
                })
                .catch((err) => {
                    console.log(`Unable to fetch /ip/${address} -`, err);
                });
            //       const response = await fetch('/ip/${address}');
            //       const jsonData = await response.json();
            //      if (jsonData.length > 0) {
            //        jsonResult.push(jsonData);
            //    }
        });
    });
    // return the JSON result
    res.send(JSON.stringify(jsonResult, null, 2));
});

export default router;