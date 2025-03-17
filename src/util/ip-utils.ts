//-----------------------------
// Function:    TestIPv4Address
// Description: Return true if the parameter matches the pattern of an IPv4 Address  
//-----------------------------
export function TestIPv4Address(IpAddress: string) : boolean {
    var ip4RegEx: RegExp = new RegExp('^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')
	
    if (ip4RegEx.test(IpAddress)) {
        return true;
    }
    return false;
}

//-----------------------------
// Function:    TestIPv4Subnet
// Description: Return true if the parameter matches the pattern of an IPv4 subnet (CIDR notation)  
//-----------------------------
export function TestIPv4Subnet(IpSubnet: string) : boolean {
    var ip4SubnetRegEx: RegExp = new RegExp('^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/[0-9]{1,2}$')
	
    if (ip4SubnetRegEx.test(IpSubnet)) {
        return true;
    }
    return false;
}

//-----------------------------
// Function:    TestPrivateAddress
// Description: Return true if IpAddress is within the rfc1918 private address range
//-----------------------------
export function TestPrivateAddress (IpAddress: string) : boolean {

    var reservedAddressRanges : string[] = [
        "172.16.0.0/12", 
        "10.0.0.0/8", 
        "192.168.0.0/16",
        "100.64.0.0/10",
        "127.0.0.0/8",
        "169.254.0.0/16"
    ]
    
    for (var i = 0; i < reservedAddressRanges.length; i++) {
        if (TestIpInSubnet(IpAddress, reservedAddressRanges[i])) {
            return true;
        }
    }
    return false;
}


//-----------------------------
// Function:    TestIpInSubnet
// Description: Return true if the IP address falls within the Subnet
//-----------------------------
export function TestIpInSubnet (IpAddress: string, Subnet: string) : boolean {
    
    const [subnetAddress, subnetMaskLength] = Subnet.split('/');
    const subnetMask = ~((1 << (32 - parseInt(subnetMaskLength, 10))) - 1) >>> 0;
    const ipLong = IpToLong(IpAddress);
    const subnetLong = IpToLong(subnetAddress);

    return (ipLong & subnetMask) === (subnetLong & subnetMask); 

}

//-----------------------------
// Function:    IpToLong
// Description: Convert a tring based IPv4 address to a Long Int
function IpToLong(ip: string): number {
    return ip.split('.').reduce((acc, octet) => (acc << 8) + parseInt(octet, 10), 0) >>> 0;
}

