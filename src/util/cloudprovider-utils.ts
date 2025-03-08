import fs from 'fs';

// define the structure of the JSON files containing the cloud provider details
export interface cloudProviderJSON {
    Subnet: string;
    Region: string;
    Service: string;
    SubnetSize: string;
};


//-----------------------------
// Function:    GetCloudProviderSubnets
// Description: Retrieve the cloud provider details from JSON files
//-----------------------------
export function GetCloudProviderSubnets(Filename: string, Filter: string = ""): cloudProviderJSON[] {

    var azureSubnets : cloudProviderJSON[] = JSON.parse(fs.readFileSync(Filename, 'utf-8'));

    // filter the results on first digits of Subnet property (if set)
    if (Filter != "") {
        const filteredAzureSubnets : cloudProviderJSON[] = azureSubnets.filter((item : cloudProviderJSON) => item.Subnet.indexOf(Filter) == 0);
        return filteredAzureSubnets;
    }
    return azureSubnets;
}