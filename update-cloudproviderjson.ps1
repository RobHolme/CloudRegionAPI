<#
Download JSON files detailing subnets for each cloud provider / CDN

05/03/2025
#>



# timeout to retrieve the IP ranges from source sites (in seconds)
$timeout = 5

# source URLs for each cloud provider
$awsSource = "https://ip-ranges.amazonaws.com/ip-ranges.json"
$azureSource = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"
$googleCloudSource = "https://www.gstatic.com/ipranges/cloud.json"
$cloudFlareSource = "https://www.cloudflare.com/ips-v4/#"
$ociSource = "https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json"
$akamaiSource = "https://ipinfo.io/widget/demo/akamai.com?dataset=ranges"

# cache file names for each cloud provider

$azureCache =  Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "Azure.json"
$awsCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "AWS.json"
$googleCloudCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "GoogleCloud.json"
$cloudFlareCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "CloudFlare.json"
$ociCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "OCI.json"
$akamaiCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "Akamai.json"
    

#--------------------------
# Function:     TestIPv4Address
# Description:  Returns $true if the given string is a valid IPv4 address.
#--------------------------
function TestIPv4Address {
    [OutputType([bool])]
    param (
        [string]$IPAddress
    )
    
    if ($IPAddress -match '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
        return $true
    }
    else {
        return $false
    }
}

#--------------------------
# Function:     TestIPv4Subnet
# Description:  Returns $true if the given string is a valid IPv4 subnet (CIDR notation).
#--------------------------
function TestIPv4Subnet {
    [OutputType([bool])]
    param (
        [string]$IPSubnet
    )
    
    if ($IPSubnet -match '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/[0-9]{1,2}$') {
        return $true
    }
    else {
        return $false
    }
}

#--------------------------
# Function:     Invoke-WebRequestEx
# Description:  Wrapper for Invoke-WebRequest with optional proxy support. 
#               If $null values provided for the proxy server and credentials, a direct connection is used.
#--------------------------
function Invoke-WebRequestEx {
    param (
        [Parameter(Mandatory = $true)]
        [uri] $Uri,
            
        [parameter(Mandatory = $false)]
        [uri] $ProxyServer,

        [parameter(Mandatory = $false)]
        [Pscredential] $ProxyCredential
    )

    try {
        # if a proxy server is specified, use it with the provided credentials, otherwise use direct connection
        if (($ProxyServer) -and ($ProxyCredential)) {
            Write-Verbose "Using proxy server $ProxyServer"
            return Invoke-WebRequest -Uri $Uri -TimeoutSec $timeout -Proxy $ProxyServer -ProxyCredential $ProxyCredential
        }
        else {
            return Invoke-WebRequest -Uri $Uri -TimeoutSec $timeout
        }
    }
    catch {
        Write-Debug $_.Exception
        return $null
    }
        
}

#--------------------------
# Function:     IsPrivateAddress
# Description:  Returns true if the IPv4 address is within any of the RFC1918 private address ranges.
#--------------------------
function IsPrivateAddress {
    param (
        # IPv4 Address
        [Parameter(Mandatory = $true)]
        [string] $IpAddress
    )

    $rfc1918 = "172.16.0.0/12", "10.0.0.0/8", "192.168.0.0/16"
    foreach ($addressRange in $rfc1918) {
        if (TestIpInSubnet -IPAddress $IpAddress -Subnet $addressRange) {
            return $true
        }
    }
    return $false
}

#--------------------------
# Function:     GetAWSRegions
# Description:  Retrieves all AWS regions and associated IP ranges. Uses a cached JSON file if it exists, otherwise retrieve from AWS.
#--------------------------
function GetAWSRegions {
    param(
        [parameter(Mandatory = $false)]
        [string] $OctetFilter
    )

    # download the regions from source if the cached file does not exist or if the ForceDownload switch is used.
    if (!(Test-Path (Join-Path -Path $PSScriptRoot -ChildPath $awsCache)) -or $ForceDownload) {
        Write-Verbose "Retrieving AWS regions from $awsSource"
        $awsNetRanges = Invoke-WebRequestEx -Uri $awsSource -ProxyServer $ProxyServer -ProxyCredential $ProxyCredential
        if ($null -eq $awsNetRanges) {
            Write-Warning "Failed to retrieve AWS IP ranges. Falling back to cached file. Use -Debug for more information."
        }
        else {
            $awsNetRangesJson = ConvertFrom-Json $awsNetRanges.Content 
            $awsRegions = $awsNetRangesJson.prefixes | Select-Object ip_prefix, Region, Service, @{E = { $_.ip_prefix.split("/")[1] }; L = "SubnetSize" }, @{E = { "AWS" }; L = "CloudProvider" }
            
            # if not subnets found, return $null and do not update the cache file
            if ($awsRegions.Count -eq 0) {
                Write-Error "No AWS IP ranges found. Source may have changed? Using cached file instead."
            }
            else {
                # cache the JSON file for future use in the same directory as the script, return the IP ranges and regions
                $awsRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $awsCache)
                # return regions
                if ($OctetFilter) {
                    return $awsRegions | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
                }
                else {
                    return $awsRegions
                }
            }
        }
    }

    # return the cached JSON file if it exists. Assume online checks failed (or not requested) if this code is reached.
    Write-Verbose "Using cached AWS regions from $(Join-Path -Path $PSScriptRoot -ChildPath $awsCache). Use -ForceDownload to refresh."
    try {
        if ($OctetFilter) {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $awsCache)) | ConvertFrom-Json | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
        }
        else {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $awsCache)) | ConvertFrom-Json
        }
    }
    catch {
        Write-Error "Failed to read cached AWS IP ranges. Check the file exists and try again. Use -Debug for more information."
        Write-Debug $_.Exception
        return $null
    }
}


#--------------------------
# Function:     GetAzureRegions
# Description:  Retrieves all Azure regions and associated IP ranges. Uses a cached JSON file if it exists, otherwise retrieve from Azure.
#--------------------------
function GetAzureRegions {
    param(
        [parameter(Mandatory = $false)]
        [string] $OctetFilter
    )

    if (!(Test-Path (Join-Path -Path $PSScriptRoot -ChildPath $azureCache)) -or $ForceDownload) {
        $azureRegions = @()
        $azureRegionHashTable = @{}
            
        # Get the download URL for the Azure IP ranges JSON file    
        Write-Verbose "Retrieving Azure regions from $azureSource"
        $azureNetDownload = Invoke-WebRequestEx -Uri $azureSource -ProxyServer $ProxyServer -ProxyCredential $ProxyCredential
        if ($null -eq $azureNetDownload) {
            Write-Warning "Failed to retrieve download location for Azure IP ranges. Falling back to cached file. Use -Debug for more information."
        }
        else {
            $azureNetDownload = ($azureNetDownload.RawContent | Select-string -Pattern 'https:\/\/download\.microsoft\.com\/download.+\.json",').Matches[0].Value            
            $azureNetDownload = $azureNetDownload.Substring(0, $azureNetDownload.Length - 2)
            $azureNetDownloadRaw = (Invoke-WebRequestEx -Uri $azureNetDownload -ProxyServer $ProxyServer -ProxyCredential $ProxyCredential)
            if ($null -eq $azureNetDownloadRaw) {
                Write-Warning "Failed to retrieve Azure IP ranges. Falling back to cached file. Use -Debug for more information."
            }
            else {
                $azureNetDownloadRaw = $azureNetDownloadRaw.RawContent
                $azureRegionJson = ($azureNetDownloadRaw.Substring($azureNetDownloadRaw.IndexOf('{'), ($azureNetDownloadRaw.LastIndexOf('}') - $azureNetDownloadRaw.IndexOf('{')) + 1) | ConvertFrom-Json).values.properties
                # sort the IP ranges so that those without a region, then service, are last
                foreach ($region in $azureRegionJson | Sort-Object -Property region, systemService  -Descending) {
                    write-progress -activity "Processing Azure regions" -status "Processing region: $($region.region)" -percentcomplete (($azureRegionJson.IndexOf($region) / $azureRegionJson.Count) * 100)
                    foreach ($addressPrefix in $region.addressPrefixes) {
                        if (TestIPv4Subnet -IPSubnet $addressPrefix) {
                            if ($azureRegionHashTable.Contains($addressPrefix)) {
                                # ignore duplicate IP range if it does not include region or service details. Attempt to remove duplicates with less details than already discovered.
                                if (($region.region -ne "") -and ($region.systemService -ne "")) {
                                    $azureRegions += [PSCustomObject]@{
                                        ip_prefix     = $addressPrefix
                                        Region        = $region.region
                                        Service       = $region.systemService
                                        SubnetSize    = $addressPrefix.split("/")[1]
                                        CloudProvider = "Azure"
                                    }
                                }
                            }
                            else {
                                $azureRegionHashTable.Add($addressPrefix, $null)
                                $azureRegions += [PSCustomObject]@{
                                    ip_prefix     = $addressPrefix
                                    Region        = $region.region
                                    Service       = $region.systemService
                                    SubnetSize    = $addressPrefix.split("/")[1]
                                    CloudProvider = "Azure"
                                }
                            }
                        }
                    }
                }
                write-progress -activity "Processing Azure regions" -status "Processing complete" -completed

                # if no subnets found, return $null and do not update the cache file
                if ($azureRegions.Count -eq 0) {
                    Write-Error "No Azure IP ranges found. Source may have changed? Using Cached file instead."
                }
                else {
                    # cache the JSON file for future use in the same directory as the script
                    $azureRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $azureCache)
                        
                    # return all IP ranges and regions
                    if ($OctetFilter) {
                        return $azureRegions | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
                    }
                    else {
                        return $azureRegions
                    }
                }
            }
        }
    }
    
    # return the cached JSON file if it exists. Assume online checks failed if this code is reached.
    Write-Verbose "Using cached Azure regions from $(Join-Path -Path $PSScriptRoot -ChildPath $azureCache). Use -ForceDownload to refresh."
    try {
        if ($OctetFilter) {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $azureCache)) | ConvertFrom-Json | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
        }
        else {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $azureCache)) | ConvertFrom-Json
        }
    }
    catch {
        Write-Error "Failed to read cached Azure IP ranges. Check the file exists and try again. Use -Debug for more information."
        Write-Debug $_.Exception
        return $null
    }
}
 

#--------------------------
# Function:     GetGoogleCloudRegions
# Description:  Retrieves all Google Cloud regions and associated IP ranges. Uses a cached JSON file if it exists, otherwise retrieve from Google Cloud.
#               Use OctetFilter parameter to limit values returned to those where first octet of subnet matches the value of this parameter.
#--------------------------
function GetGoogleCloudRegions {
    param(
        [parameter(Mandatory = $false)]
        [string] $OctetFilter
    )
        
    if (!(Test-Path (Join-Path -Path $PSScriptRoot -ChildPath $googleCloudCache)) -or $ForceDownload) {
        Write-Verbose "Retrieving Google Cloud regions from $googleCloudSource"
        $gcpNetRanges = Invoke-WebRequestEx -Uri $googleCloudSource -ProxyServer $ProxyServer -ProxyCredential $ProxyCredential
        if ($null -eq $gcpNetRanges) {
            Write-Warning "Failed to retrieve Google Cloud IP ranges. Falling back to cache file. Use -Debug for more information."
        }
        else {
            $gcpNetRangesJson = ConvertFrom-Json $gcpNetRanges.Content 
            $gcpRegions = ($gcpNetRangesJson.prefixes) | Where-Object { $null -ne $_.ipv4Prefix } | Select-Object @{E = { $_.ipv4Prefix }; L = "ip_prefix" }, @{E = { $_.scope }; L = "Region" }, service, @{E = { (($_.ipv4Prefix).split("/"))[1] }; L = "SubnetSize" }, @{E = { "Google Cloud" }; L = "CloudProvider" }
                
            # if no subnets found, return $null and do not update the cache file
            if ($gcpRegions.Count -eq 0) {
                Write-Error "No Google Cloud IP ranges found. Source may have changed? Using cached file instead."
            }
            else {
                # cache the JSON file for future use in the same directory as the script
                $gcpRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $googleCloudCache)
                    
                # speed up the search by only returning subnets where the first octet matches the parameter value for $OctetFilter 
                if ($OctetFilter) {
                    return $gcpRegions | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
                }
                else {
                    # return the IP ranges and regions
                    return $gcpRegions
                }
            }
        }
    }
        
    # return the cached JSON file if it exists. Assume online checks failed (or not requested) if this code is reached.
    Write-Verbose "Using cached Google Cloud regions from $(Join-Path -Path $PSScriptRoot -ChildPath $googleCloudCache). Use -ForceDownload to refresh."
    try {
        if ($OctetFilter) {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $googleCloudCache)) | ConvertFrom-Json | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
        }
        else {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $googleCloudCache)) | ConvertFrom-Json
        }
    }
    catch {
        Write-Error "Failed to read cached Google Cloud IP ranges. Check the file exists and try again. Use -Debug for more information."
        Write-Debug $_.Exception
        return $null
    }
}


#--------------------------
# Function:     GetAkamaiRegions
# Description:  Retrieves all Akamai IP ranges. Regions not available. 
#               Sources IPs from a demo widget for ipinfo.io. May not be a reliable long term source.
#--------------------------
function GetAkamaiRegions {
    param(
        [parameter(Mandatory = $false)]
        [string] $OctetFilter
    )

    $AkamaiRegions = @()
    if (!(Test-Path (Join-Path -Path $PSScriptRoot -ChildPath $akamaiCache)) -or $ForceDownload) {
        Write-Verbose "Retrieving Akamai IP ranges from $akamaiSource"
        $AkamaiNetRanges = Invoke-WebRequestEx -Uri $akamaiSource -ProxyServer $ProxyServer -ProxyCredential $ProxyCredential
        if ($null -eq $AkamaiNetRanges) {
            Write-Warning "Failed to retrieve Akamai IP ranges. Falling back to cache file. Use -Debug for more information."
        }
        else {
            $AkamaiNetRangesObject = $AkamaiNetRanges.Content | ConvertFrom-Json
            foreach ($subnet in $AkamaiNetRangesObject.ranges) {
                # ipv4 ranges only
                if (TestIPv4Subnet -IPSubnet $subnet) {
                    $AkamaiRegions += [PSCustomObject]@{
                        ip_prefix     = $subnet
                        Region        = "Unknown"
                        Service       = ""
                        SubnetSize    = $subnet.split("/")[1]
                        CloudProvider = "Akamai"
                    }
                }
            }
    
            # if no subnets found, return $null and do not update the cache file
            if ($AkamaiRegions.Count -eq 0) {
                Write-Error "No Akamai IP ranges found. Source may have changed?. Using cached file instead."
            }
            else {
                # cache the JSON file for future use in the same directory as the script
                $AkamaiRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $akamaiCache)
                # return the IP ranges and regions
                if ($OctetFilter) {
                    return $AkamaiRegions | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
                }
                else {
                    return $AkamaiRegions
                }
            }
        }
    }

    # return the cached JSON file if it exists. Assume online checks failed (or not requested) if this code is reached.
    Write-Verbose "Using cached Akamai IP ranges from $(Join-Path -Path $PSScriptRoot -ChildPath $akamaiCache). Use -ForceDownload to refresh."
    try {
        if ($OctetFilter) {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $akamaiCache)) | ConvertFrom-Json | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
        }
        else {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $akamaiCache)) | ConvertFrom-Json
        }
    }
    catch {
        Write-Error "Failed to read cached Akamai IP ranges. Check the file exists and try again. Use -Debug for more information."
        Write-Debug $_.Exception
        return $null
    }
}


#--------------------------
# Function:     GetCloudFlareRegions
# Description:  Retrieves all CloudFlare IP ranges. Regions not available. Uses a cached JSON file if it exists, otherwise retrieve from CloudFlare.
function GetCloudFlareRegions {
    param(
        [parameter(Mandatory = $false)]
        [string] $OctetFilter
    )

    $cloudFlareRegions = @()
    if (!(Test-Path (Join-Path -Path $PSScriptRoot -ChildPath $cloudFlareCache)) -or $ForceDownload) {
        Write-Verbose "Retrieving CloudFlare IP ranges from $cloudFlareSource"
        $cloudFlareNetRanges = Invoke-WebRequestEx -Uri $cloudFlareSource -ProxyServer $ProxyServer -ProxyCredential $ProxyCredential
        if ($null -eq $cloudFlareNetRanges) {
            Write-Warning "Failed to retrieve CloudFlare IP ranges. Falling back to cache file. Use -Debug for more information."
        }
        else {
            foreach ($subnet in ($cloudFlareNetRanges.Content | Select-String -Pattern '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}' -AllMatches).Matches.Value) {
                $cloudFlareRegions += [PSCustomObject]@{
                    ip_prefix     = $subnet
                    Region        = "Unknown"
                    Service       = ""
                    SubnetSize    = $subnet.split("/")[1]
                    CloudProvider = "CloudFlare"
                }
            }

            # if no subnets found, return $null and do not update the cache file
            if ($cloudFlareRegions.Count -eq 0) {
                Write-Error "No CloudFlare IP ranges found. Source may have changed? Using cached file instead."
            }
            else {
                # cache the JSON file for future use in the same directory as the script
                $cloudFlareRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $cloudFlareCache)
                # return the IP ranges
                if ($OctetFilter) {
                    return $cloudFlareRegions | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
                }
                else {
                    return $cloudFlareRegions   
                } 
            }
        }   
    }
        
    # return the cached JSON file if it exists. Assume online checks failed if this code is reached.
    Write-Verbose "Using cached CloudFlare IP ranges from $(Join-Path -Path $PSScriptRoot -ChildPath $cloudFlareCache). Use -ForceDownload to refresh."
    try {
        if ($OctetFilter) {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $cloudFlareCache)) | ConvertFrom-Json | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
        }
        else {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $cloudFlareCache)) | ConvertFrom-Json
        }
    }
    catch {
        Write-Error "Failed to read cached CloudFlare IP ranges. Check the file exists and try again. Use -Debug for more information."
        Write-Debug $_.Exception
        return $null
    }
}


#--------------------------
# Function:     GetOCIRegions
# Description:  Retrieves all OCI regions and associated IP ranges. Uses a cached JSON file if it exists, otherwise retrieve from OCI.
#--------------------------
function GetOCIRegions {
    param(
        [parameter(Mandatory = $false)]
        [string] $OctetFilter
    )

    $ociRegions = @()
    if (!(Test-Path (Join-Path -Path $PSScriptRoot -ChildPath $ociCache)) -or $ForceDownload) {
        Write-Verbose "Retrieving Oracle Cloud regions from $ocisource"
        $ociNetRanges = Invoke-WebRequestEx -Uri $ociSource -ProxyServer $ProxyServer -ProxyCredential $ProxyCredential
        if ($null -eq $ociNetRanges) {
            Write-Warning "Failed to retrieve CloudFlare IP ranges. Falling back to cache file. Use -Debug for more information."
        }
        else {
            $ociNetRangesJson = ConvertFrom-Json $ociNetRanges.Content 
            foreach ($region in $ociNetRangesJson.regions) {
                write-progress -activity "Processing OCI regions" -status "Processing region: $($region.region)" -percentcomplete (($ociNetRangesJson.regions.IndexOf($region) / $ociNetRangesJson.regions.Count) * 100)
                foreach ($addressPrefix in $region.cidrs) {
                    if ($region.region -ne "") {
                        if (TestIPv4Subnet -IPSubnet $addressPrefix.cidr) {
                            foreach ($tag in $addressPrefix.tags) {
                                $ociRegions += [PSCustomObject]@{
                                    ip_prefix     = $addressPrefix.cidr
                                    Region        = $region.region
                                    Service       = $tag
                                    SubnetSize    = $($addressPrefix.cidr).split("/")[1]
                                    CloudProvider = "Oracle Cloud (OCI)"
                                }
                            }
                        }
                    }
                }
            }
            write-progress -activity "Processing OCI regions" -status "Completed" -completed
            # if no subnets found, return $null and do not update the cache file
            if ($ociRegions.Count -eq 0) {
                Write-Error "No OCI IP ranges found. Source may have changed?. Using cached file instead."
            }
            else {
                # cache the JSON file for future use in the same directory as the script
                $ociRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $ociCache)
                # return the IP ranges and regions
                if ($OctetFilter) {
                    return $ociRegions | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
                }
                else {
                    return $ociRegions
                }
            }
        }
    }
        
    # return the cached JSON file if it exists. Assume online checks failed if this code is reached.
    Write-Verbose "Using cached OCI regions from $(Join-Path -Path $PSScriptRoot -ChildPath $ociCache). Use -ForceDownload to refresh."
    try {
        if ($OctetFilter) {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $ociCache)) | ConvertFrom-Json | Where-Object { $_.ip_prefix -match "^$($OctetFilter)\." }
        }
        else {
            return (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath $ociCache)) | ConvertFrom-Json
        }
    }
    catch {
        Write-Error "Failed to read cached OCI IP ranges. Check the file exists and try again. Use -Debug for more information."
        Write-Debug $_.Exception
        return $null
    }
            
}


#--------------------------
# Function:     TestIpInSubnet
# Description:  Returns $true if the IP address is within the given subnet.
#--------------------------
function TestIpInSubnet {
    param (
        [string]$IPAddress,
        [string]$Subnet
    )
      
    function ConvertTo-UInt32 {
        param (
            [byte[]]$IPAddressBytes
        )
        [Array]::Reverse($IPAddressBytes)
        return [BitConverter]::ToInt32($IPAddressBytes, 0)
    }
    
    function Get-NetworkAddress {
        param (
            [int32]$IPAddress,
            [int32]$SubnetMask
        )
        return $IPAddress -band $SubnetMask
    }
    
    function Get-BroadcastAddress {
        param (
            [int32]$NetworkAddress,
            [int32]$SubnetMask
        )
        return $NetworkAddress -bor (-bnot $SubnetMask)
    }
    
    # Split the subnet into address and prefix length
    $subnetParts = $Subnet.Split('/')
    $subnetAddress = $subnetParts[0]
    $prefixLength = [int]$subnetParts[1]
    
    # Convert IP addresses to byte arrays
    try {
        $ipBytes = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()
        $subnetBytes = [System.Net.IPAddress]::Parse($subnetAddress).GetAddressBytes()
    }
    catch {
        Write-Warning "Invalid IP address or subnet. IP: $IPAddress, Subnet: $Subnet"
    }
    
    # Convert byte arrays to UInt32
    $ipUInt32 = ConvertTo-UInt32 -IPAddressBytes $ipBytes
    $subnetUInt32 = ConvertTo-UInt32 -IPAddressBytes $subnetBytes
    
    # Calculate the subnet mask
    $subnetMask = [int32](-bnot ([math]::Pow(2, 32 - $prefixLength) - 1))
    
    # Calculate network and broadcast addresses
    $networkAddress = Get-NetworkAddress -IPAddress $subnetUInt32 -SubnetMask $subnetMask
    $broadcastAddress = Get-BroadcastAddress -NetworkAddress $networkAddress -SubnetMask $subnetMask
    
    # Check if the IP address is within the subnet
    return ($ipUInt32 -ge $networkAddress -and $ipUInt32 -le $broadcastAddress)
}


write-progress -activity "Loading subnet ranges" -status "AWS" -percentcomplete 0                       
$AWSRegions = GetAWSRegions
Write-Verbose "$($AWSRegions.Count) AWS subnets loaded"

write-progress -activity "Loading subnet ranges" -status "Azure" -percentcomplete 16 
$AzureRegions = GetAzureRegions
Write-Verbose "$($AzureRegions.Count) Azure subnets loaded"
    
write-progress -activity "Loading subnet ranges" -status "Google Cloud" -percentcomplete 33
$GoogleCloudRegions = GetGoogleCloudRegions
Write-Verbose "$($GoogleCloudRegions.Count) Google Cloud subnets loaded"
    
write-progress -activity "Loading subnet ranges" -status "CloudFlare" -percentcomplete 50
$CloudFlareRegions = GetCloudFlareRegions
Write-Verbose "$($CloudFlareRegions.Count) CloudFlare subnets loaded"
    
write-progress -activity "Loading subnet ranges" -status "Oracle Cloud (OCI)" -percentcomplete 66
$OCIRegions = GetOCIRegions
Write-Verbose "$($OCIRegions.Count) OCI subnets loaded"
    
write-progress -activity "Loading subnet ranges" -status "Akamai" -percentcomplete 83
$AkamaiRegions = GetAkamaiRegions
Write-Verbose "$($AkamaiRegions.Count) Akamai subnets loaded"
    
write-progress -activity "Loading subnet ranges" -status "Completed" -completed




