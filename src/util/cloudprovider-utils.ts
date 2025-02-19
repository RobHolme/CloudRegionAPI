import fs from 'fs'

// define the structure of the JSON files containing the cloud provider details
interface cloudProviderJSON {
    ip_prefix: string;
    Region: string;
    Service: string;
    SubnetSize: string;
}


//-----------------------------
// Function:    GetCloudProviderSubnets
// Description: Retrieve the cloud provider details from JSON files
//-----------------------------
export function GetCloudProviderSubnets(Filename: string, Filter: string = ""): JSON {

    var azureSubnets = JSON.parse(fs.readFileSync(Filename, 'utf-8'))

    // filter the results on first digits if ip_prefix property (if set)
    if (Filter != "") {
        const filteredAzureSubnets = azureSubnets.filter((item : cloudProviderJSON) => item.ip_prefix.indexOf(Filter) == 0);
        return JSON.parse(filteredAzureSubnets);
    }
    return azureSubnets;
}