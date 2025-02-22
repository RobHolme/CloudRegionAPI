"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const ip_utils_1 = require("../util/ip-utils");
const cloudprovider_utils_1 = require("../util/cloudprovider-utils");
const router = (0, express_1.Router)();
// -----------------------------
// Get IP address router
// Use a path parameter to retrieve the IP address to query. e.g.  http://server/ip/20.340.54.4
// -----------------------------
router.get("/:ip", (req, res) => {
    const ipAddress = req.params.ip;
    var jsonResult = [];
    res.setHeader('content-type', 'application/json');
    // return error if the string does not match the format of an IPv4 address
    if ((0, ip_utils_1.TestIPv4Address)(ipAddress)) {
        // return an error for private addresses - likely to be private endpoints
        if ((0, ip_utils_1.TestPrivateAddress)(ipAddress) == true) {
            res.status(404).json({ message: "IPv4 Address is a reserved address" });
            return;
        }
        // get the cloud provider subnets (and region/service), filtered on the first octet of the IP Address matching the start of the subnet network address 
        var CloudProviderDetails = (0, cloudprovider_utils_1.GetCloudProviderSubnets)('./src/cloudproviders/Azure.json', ipAddress.split(".")[0]);
        CloudProviderDetails.push(...(0, cloudprovider_utils_1.GetCloudProviderSubnets)('./cloudproviders/AWS.json', ipAddress.split(".")[0]));
        CloudProviderDetails.push(...(0, cloudprovider_utils_1.GetCloudProviderSubnets)('./cloudproviders/AWS.json', ipAddress.split(".")[0]));
        CloudProviderDetails.push(...(0, cloudprovider_utils_1.GetCloudProviderSubnets)('./cloudproviders/Azure.json', ipAddress.split(".")[0]));
        CloudProviderDetails.push(...(0, cloudprovider_utils_1.GetCloudProviderSubnets)('./cloudproviders/GoogleCloud.json', ipAddress.split(".")[0]));
        CloudProviderDetails.push(...(0, cloudprovider_utils_1.GetCloudProviderSubnets)('./cloudproviders/OCI.json', ipAddress.split(".")[0]));
        CloudProviderDetails.push(...(0, cloudprovider_utils_1.GetCloudProviderSubnets)('./cloudproviders/Akamai.json', ipAddress.split(".")[0]));
        CloudProviderDetails.push(...(0, cloudprovider_utils_1.GetCloudProviderSubnets)('./cloudproviders/CloudFlare.json', ipAddress.split(".")[0]));
        CloudProviderDetails.forEach((currentSubnet) => {
            if ((0, ip_utils_1.TestIpInSubnet)(ipAddress, currentSubnet.ip_prefix)) {
                jsonResult.push(currentSubnet);
            }
        });
        res.send(JSON.stringify(jsonResult, null, 2));
        //res.send(TestIpInSubnet(ipAddress, "20.0.0.0/24"));
    }
    else {
        res.status(404).json({ message: "IPv4 Address failed validation" });
    }
});
exports.default = router;
