import fs from 'fs';
import { TestIpInSubnet } from './ip-utils';

// define the structure of the JSON files containing the cloud provider details
export interface cloudProviderJSON {
    Subnet: string;
    Region: string;
    Service: string;
    SubnetSize: string;
};

export interface cloudProviderSearchResult {
    IPAddress: string;
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

    var azureSubnets: cloudProviderJSON[] = JSON.parse(fs.readFileSync(Filename, 'utf-8'));

    // filter the results on first digits of Subnet property (if set)
    if (Filter != "") {
        const filteredAzureSubnets: cloudProviderJSON[] = azureSubnets.filter((item: cloudProviderJSON) => item.Subnet.indexOf(Filter) == 0);
        return filteredAzureSubnets;
    }
    return azureSubnets;
}


//-----------------------------
// Function:    SearchAllCloudProviders
// Description: Search all cloud providers for subnets that container the IP address
//-----------------------------
export function SearchAllCloudProviders(ipAddress: string): cloudProviderSearchResult[] {
    var cloudProviderResults: cloudProviderSearchResult[] = [];
    // get the cloud provider subnets (and region/service), filtered on the first octet of the IP Address matching the start of the subnet network address 
    var CloudProviderDetails: cloudProviderJSON[] = [];
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/Azure.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/AWS.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/GoogleCloud.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/OCI.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/Akamai.json', ipAddress.split(".")[0]));
    CloudProviderDetails.push(...GetCloudProviderSubnets('./release/cloudproviders/CloudFlare.json', ipAddress.split(".")[0]));

    // filter the cloud provider subnets to find the subnet that the IP address belongs to
    CloudProviderDetails.forEach((currentSubnet: cloudProviderJSON) => {
        if (TestIpInSubnet(ipAddress, currentSubnet.Subnet)) {
            var tempResult: cloudProviderSearchResult;
            // merge the IPAddress and cloud provider JSON into a new object
            tempResult = Object.assign({}, {IPAddress:ipAddress}, currentSubnet)
            cloudProviderResults.push(tempResult);
        }
    });
    return cloudProviderResults;
}