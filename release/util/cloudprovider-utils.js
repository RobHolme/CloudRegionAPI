"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GetCloudProviderSubnets = GetCloudProviderSubnets;
const fs_1 = __importDefault(require("fs"));
;
//-----------------------------
// Function:    GetCloudProviderSubnets
// Description: Retrieve the cloud provider details from JSON files
//-----------------------------
function GetCloudProviderSubnets(Filename, Filter = "") {
    var azureSubnets = JSON.parse(fs_1.default.readFileSync(Filename, 'utf-8'));
    // filter the results on first digits if ip_prefix property (if set)
    if (Filter != "") {
        const filteredAzureSubnets = azureSubnets.filter((item) => item.ip_prefix.indexOf(Filter) == 0);
        return filteredAzureSubnets;
    }
    return azureSubnets;
}
