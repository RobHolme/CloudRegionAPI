import { Router, Request, Response } from "express";
import fs from 'fs';
import { cloudProviderJSON } from '../util/cloudprovider-utils'

const router = Router();

// -----------------------------
// Return the full list of subnets for a specific cloud provider
// -----------------------------
router.get("/:cloudprovider", async (req: Request, res: Response) => {
    const cloudProvider: string = req.params.cloudprovider.toLowerCase().trim();
    res.setHeader('content-type', 'application/json');
    const xClientIp: string | undefined = req.headers['x-client-ip'] as string;
    console.log(`Subnets: client ${req.ip} (${xClientIp}) submitted: ${cloudProvider}`);

    // list of supported cloud providers and their JSON files
    const providerDetails: { [key: string]: string } = {
        "azure": "./release/cloudproviders/Azure.json", 
        "azuregovernment": "./release/cloudproviders/AzureGovernment.json", 
        "azurechina": "./release/cloudproviders/AzureChina.json", 
        "azuregermany": "./release/cloudproviders/AzureGermany.json", 
        "aws": "./release/cloudproviders/AWS.json",
        "google": "./release/cloudproviders/GoogleCloud.json",
        "oci": "./release/cloudproviders/OCI.json", 
        "cloudflare": "./release/cloudproviders/CloudFlare.json",
        "akamai": "./release/cloudproviders/Akamai.json",
        "digitalocean": "./release/cloudproviders/DigitalOcean.json"
    };

    if (Object.keys(providerDetails).includes(cloudProvider)) {
        const cloudProviderFile: string = providerDetails[cloudProvider];
        try{
            var allSubnets: cloudProviderJSON[] = JSON.parse(fs.readFileSync(cloudProviderFile, 'utf-8'));
            res.send(JSON.stringify(allSubnets, null, 2));
        }
        catch {
            res.status(404).json({ message: `Error reading subnet details for ${cloudProvider}` });
        }
    }
    // return error if specific cloud provider isn't supported
    else {
        res.status(404).json({ message: `Cloud Provider ${cloudProvider} not found` });
        return;
    }

});

export default router;