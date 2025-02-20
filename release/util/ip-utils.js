"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TestIpInSubnet = exports.TestPrivateAddress = exports.TestIPv4Subnet = exports.TestIPv4Address = void 0;
//-----------------------------
// Function:    TestIPv4Address
// Description: Return true if the parameter matches the pattern of an IPv4 Address  
//-----------------------------
function TestIPv4Address(IpAddress) {
    var ip4RegEx = new RegExp('^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    if (ip4RegEx.test(IpAddress)) {
        return true;
    }
    return false;
}
exports.TestIPv4Address = TestIPv4Address;
//-----------------------------
// Function:    TestIPv4Subnet
// Description: Return true if the parameter matches the pattern of an IPv4 subnet (CIDR notation)  
//-----------------------------
function TestIPv4Subnet(IpSubnet) {
    var ip4SubnetRegEx = new RegExp('^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/[0-9]{1,2}$');
    if (ip4SubnetRegEx.test(IpSubnet)) {
        return true;
    }
    return false;
}
exports.TestIPv4Subnet = TestIPv4Subnet;
//-----------------------------
// Function:    TestPrivateAddress
// Description: Return true if IpAddress is within the rfc1918 private address range
//-----------------------------
function TestPrivateAddress(IpAddress) {
    var reservedAddressRanges = [
        "172.16.0.0/12",
        "10.0.0.0/8",
        "192.168.0.0/16",
        "172.16.0.0/12",
    ];
    for (var i = 0; i < reservedAddressRanges.length; i++) {
        if (TestIpInSubnet(IpAddress, reservedAddressRanges[i])) {
            return true;
        }
    }
    return false;
}
exports.TestPrivateAddress = TestPrivateAddress;
//-----------------------------
// Function:    TestIpInSubnet
// Description: Return true if the IP address falls within the Subnet
//-----------------------------
function TestIpInSubnet(IpAddress, Subnet) {
    const [subnetAddress, subnetMaskLength] = Subnet.split('/');
    const subnetMask = ~((1 << (32 - parseInt(subnetMaskLength, 10))) - 1) >>> 0;
    const ipLong = IpToLong(IpAddress);
    const subnetLong = IpToLong(subnetAddress);
    return (ipLong & subnetMask) === (subnetLong & subnetMask);
}
exports.TestIpInSubnet = TestIpInSubnet;
//-----------------------------
// Function:    IpToLong
// Description: Convert a tring based IPv4 address to a Long Int
function IpToLong(ip) {
    return ip.split('.').reduce((acc, octet) => (acc << 8) + parseInt(octet, 10), 0) >>> 0;
}
