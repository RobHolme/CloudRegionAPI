<#
Download JSON files detailing subnets for each cloud provider / CDN

05/03/2025
#>
[CmdletBinding()]

# Optional parameter to limit the script execution to a single cloud provider. If not specified, all providers are processed.
param (
    [parameter(Mandatory = $false)]
    [ValidateSet("AWS", "Azure", "GoogleCloud", "CloudFlare", "OCI", "Akamai", "DigitalOcean", "All")]
    [string] $CloudProvider = "All"
)

begin {

    # timeout to retrieve the IP ranges from source sites (in seconds)
    $timeout = 10

    # source URLs for each cloud provider
    $awsSource = "https://ip-ranges.amazonaws.com/ip-ranges.json"
    $azurePublicSource = "https://www.microsoft.com/download/details.aspx?id=56519"
    $azureGovernmentSource = "https://www.microsoft.com/download/details.aspx?id=57063"
    $azureChinaSource = "https://www.microsoft.com/download/details.aspx?id=57062"
    $azureGermanySource = "https://www.microsoft.com/download/details.aspx?id=57064"
    $googleCloudSource = "https://www.gstatic.com/ipranges/cloud.json"
    $ociSource = "https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json"
    $digitalOceanSource = "https://digitalocean.com/geo/google.csv"
    # source URLs for CDNs
    $cloudFlareSource = "https://www.cloudflare.com/ips-v4/#"
    $akamaiSource = "https://ipinfo.io/widget/demo/akamai.com?dataset=ranges"

    # cache file names for each cloud provider
    $azurePublicCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "Azure.json"
    $azureGovernmentCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "AzureGovernment.json"
    $azureChinaCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "AzureChina.json"
    $azureGermanyCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "AzureGermany.json"
    $awsCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "AWS.json"
    $googleCloudCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "GoogleCloud.json"
    $ociCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "OCI.json"
    $digitalOceanCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "DigitalOcean.json"
    $cloudFlareCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "CloudFlare.json"
    $akamaiCache = Join-Path -Path "src" -ChildPath "cloudproviders" -AdditionalChildPath "Akamai.json"
    

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
    #               Failed connections are retried 3 times
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

        $retry = 0
        while ($retry++ -lt 3) {
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
                if ($retry -lt 3) {
                    Write-Warning "Failed to connect to $Uri. $(3-$retry) attempts remaining."
                }
                else {
                    Write-error $_.Exception
                    return $null
                }
            }
        }
        return $null
    }

    #--------------------------
    # Function:     GetAWSRegions
    # Description:  Retrieves all AWS regions and associated IP ranges. 
    #--------------------------
    function GetAWSRegions {
        # download the regions from source if the cached file does not exist or if the ForceDownload switch is used.
        Write-Verbose "Retrieving AWS regions from $awsSource"
        $awsNetRanges = Invoke-WebRequestEx -Uri $awsSource
        if ($null -eq $awsNetRanges) {
            Write-Warning "Failed to retrieve AWS IP ranges."
            # return error code to indicate no subnets found (should trigger github action to fail)
            exit 1
        }
        else {
            $awsNetRangesJson = ConvertFrom-Json $awsNetRanges.Content 
            $awsRegions = $awsNetRangesJson.prefixes | Select-Object  @{E = { $_.ip_prefix }; L = "Subnet" }, @{E = { $_.region }; L = "Region" }, @{E = { $_.service }; L = "Service" }, @{E = { $_.ip_prefix.split("/")[1] }; L = "SubnetSize" }, @{E = { "AWS" }; L = "CloudProvider" }
            # if not subnets found, return $null and do not update the cache file
            if ($awsRegions.Count -eq 0) {
                Write-Error "No AWS IP ranges found. Source may have changed? No updates saved."
                # return error code to indicate no subnets found (should trigger github action to fail)
                exit 1
            }
            else {
                write-verbose "AWS subnets found: $($awsRegions.Count)"
                # cache the JSON file for future use in the same directory as the script, return the IP ranges and regions
                $awsRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $awsCache)
            }
        } 
    }


    #--------------------------
    # Function:     GetAzureRegions
    # Description:  Retrieves all Azure regions and associated IP ranges. 
    #--------------------------
    function GetAzureRegions {
        param (
        # Azure cloud source to download the IP ranges from.
        [Parameter(Mandatory=$true)]
        [string] $azureSource,

        # cache file to store the Azure IP ranges in.
        [Parameter(Mandatory=$true)]
        [string] $azureCache,

        # The cloud provider name to use in results
        [Parameter(Mandatory=$true)]
        [string] $cloudProvider
        )


        $azureRegions = @()
        $azureRegionHashTable = @{}
            
        # Get the download URL for the Azure IP ranges JSON file    
        Write-Verbose "Retrieving Azure regions from $azureSource"
        $azureNetDownload = Invoke-WebRequestEx -Uri $azureSource
        if ($null -eq $azureNetDownload) {
            Write-Warning "Failed to retrieve download location for Azure IP ranges."
            # return error code to indicate no subnets found (should trigger github action to fail)
            exit 1
        }
        else {
            $azureNetDownload = ($azureNetDownload.RawContent | Select-string -Pattern 'https:\/\/download\.microsoft\.com\/download.+\.json",').Matches[0].Value            
            $azureNetDownload = $azureNetDownload.Substring(0, $azureNetDownload.Length - 2)
            $azureNetDownloadRaw = (Invoke-WebRequestEx -Uri $azureNetDownload)
            if ($null -eq $azureNetDownloadRaw) {
                Write-Warning "Failed to retrieve Azure IP ranges."
                # return error code to indicate no subnets found (should trigger github action to fail)
                exit 1
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
                                        Subnet        = $addressPrefix
                                        Region        = $region.region
                                        Service       = $region.systemService
                                        SubnetSize    = $addressPrefix.split("/")[1]
                                        CloudProvider = $cloudProvider
                                    }
                                }
                            }
                            else {
                                $azureRegionHashTable.Add($addressPrefix, $null)
                                $azureRegions += [PSCustomObject]@{
                                    Subnet        = $addressPrefix
                                    Region        = $region.region
                                    Service       = $region.systemService
                                    SubnetSize    = $addressPrefix.split("/")[1]
                                    CloudProvider = $cloudProvider
                                }
                            }
                        }
                    }
                }
                write-progress -activity "Processing $cloudProvider regions" -status "Processing complete" -completed
                # if no subnets found, return $null and do not update the cache file
                if ($azureRegions.Count -eq 0) {
                    Write-Error "No $cloudProvider IP ranges found. Source may have changed? No updates saved."
                    # return error code to indicate no subnets found (should trigger github action to fail)
                    exit 1
                }
                # cache the JSON file for future use in the same directory as the script
                else {
                    write-verbose "$cloudProvider subnets found: $($azureRegions.Count)"
                    $azureRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $azureCache)                 
                }
            }
        }
    }
 

    #--------------------------
    # Function:     GetGoogleCloudRegions
    # Description:  Retrieves all Google Cloud regions and associated IP ranges. 
    #--------------------------
    function GetGoogleCloudRegions {   
        Write-Verbose "Retrieving Google Cloud regions from $googleCloudSource"
        $gcpNetRanges = Invoke-WebRequestEx -Uri $googleCloudSource
        if ($null -eq $gcpNetRanges) {
            Write-Warning "Failed to retrieve Google Cloud IP ranges."
            # return error code to indicate no subnets found (should trigger github action to fail)
            exit 1
        }
        else {
            $gcpNetRangesJson = ConvertFrom-Json $gcpNetRanges.Content 
            $gcpRegions = ($gcpNetRangesJson.prefixes) | Where-Object { $null -ne $_.ipv4Prefix } | Select-Object @{E = { $_.ipv4Prefix }; L = "Subnet" }, @{E = { $_.scope }; L = "Region" }, service, @{E = { (($_.ipv4Prefix).split("/"))[1] }; L = "SubnetSize" }, @{E = { "Google Cloud" }; L = "CloudProvider" }
                
            # if no subnets found, return $null and do not update the cache file
            if ($gcpRegions.Count -eq 0) {
                Write-Error "No Google Cloud IP ranges found. Source may have changed? Using cached file instead."
                # return error code to indicate no subnets found (should trigger github action to fail)
                exit 1
            }
            else {
                write-verbose "Google Cloud subnets found: $($gcpRegions.Count)"
                # cache the JSON file for future use in the same directory as the script
                $gcpRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $googleCloudCache)
            }
        }
    }


    #--------------------------
    # Function:     GetAkamaiRegions
    # Description:  Retrieves all Akamai IP ranges. Regions not available. 
    #               Sources IPs from a demo widget for ipinfo.io. May not be a reliable long term source.
    #--------------------------
    function GetAkamaiRegions {
        $AkamaiRegions = @()
        Write-Verbose "Retrieving Akamai IP ranges from $akamaiSource"
        $AkamaiNetRanges = Invoke-WebRequestEx -Uri $akamaiSource
        if ($null -eq $AkamaiNetRanges) {
            Write-Warning "Failed to retrieve Akamai IP ranges."
            # return error code to indicate no subnets found (should trigger github action to fail)
            exit 1
        }
        else {
            $AkamaiNetRangesObject = $AkamaiNetRanges.Content | ConvertFrom-Json
            foreach ($subnet in $AkamaiNetRangesObject.ranges) {
                # ipv4 ranges only
                if (TestIPv4Subnet -IPSubnet $subnet) {
                    $AkamaiRegions += [PSCustomObject]@{
                        Subnet        = $subnet
                        Region        = "Unknown"
                        Service       = ""
                        SubnetSize    = $subnet.split("/")[1]
                        CloudProvider = "Akamai"
                    }
                }
            }
    
            # if no subnets found, return $null and do not update the cache file
            if ($AkamaiRegions.Count -eq 0) {
                Write-Error "No Akamai IP ranges found. Source may have changed?."
                # return error code to indicate no subnets found (should trigger github action to fail)
                exit 1
            }
            else {
                write-verbose "Akamai subnets found: $($AkamaiRegions.Count)"
                # cache the JSON file for future use in the same directory as the script
                $AkamaiRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $akamaiCache)
            }
        }
    }


    #--------------------------
    # Function:     GetCloudFlareRegions
    # Description:  Retrieves all CloudFlare IP ranges. Regions not available.
    function GetCloudFlareRegions {
        $cloudFlareRegions = @()
        Write-Verbose "Retrieving CloudFlare IP ranges from $cloudFlareSource"
        $cloudFlareNetRanges = Invoke-WebRequestEx -Uri $cloudFlareSource
        if ($null -eq $cloudFlareNetRanges) {
            Write-Warning "Failed to retrieve CloudFlare IP ranges."
            # return error code to indicate no subnets found (should trigger github action to fail)
            exit 1    
        }
        else {
            foreach ($subnet in ($cloudFlareNetRanges.Content | Select-String -Pattern '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}' -AllMatches).Matches.Value) {
                $cloudFlareRegions += [PSCustomObject]@{
                    Subnet        = $subnet
                    Region        = "Unknown"
                    Service       = ""
                    SubnetSize    = $subnet.split("/")[1]
                    CloudProvider = "CloudFlare"
                }
            }

            # if no subnets found, return $null and do not update the cache file
            if ($cloudFlareRegions.Count -eq 0) {
                Write-Error "No CloudFlare IP ranges found. Source may have changed? No updates saved."
                # return error code to indicate no subnets found (should trigger github action to fail)
                exit 1
            }
            # cache the JSON file for future use in the same directory as the script
            else {
                write-verbose "CloudFlare subnets found: $($cloudFlareRegions.Count)"
                $cloudFlareRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $cloudFlareCache)
            }
        }   
    }


    #--------------------------
    # Function:     GetOCIRegions
    # Description:  Retrieves all OCI regions and associated IP ranges. 
    #--------------------------
    function GetOCIRegions {
        $ociRegions = @()
        Write-Verbose "Retrieving Oracle Cloud regions from $ocisource"
        $ociNetRanges = Invoke-WebRequestEx -Uri $ociSource
        if ($null -eq $ociNetRanges) {
            Write-Warning "Failed to retrieve CloudFlare IP ranges."
            # return error code to indicate no subnets found (should trigger github action to fail)
            exit 1
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
                                    Subnet        = $addressPrefix.cidr
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
                Write-Error "No OCI IP ranges found. Source may have changed?. No updates saved."
                # return error code to indicate no subnets found (should trigger github action to fail)
                exit 1
            }
            # cache the JSON file for future use in the same directory as the script
            else {
                write-verbose "OCI subnets found: $($ociRegions.Count)"
                $ociRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $ociCache)
            }
        }   
    }

        #--------------------------
    # Function:     GetDigitalOceanRegions
    # Description:  Retrieves all Digital Ocean regions and associated IP ranges.
    #--------------------------
    function GetDigitalOceanRegions {
        $digitalOceanRegions = @()
        Write-Verbose "Retrieving Digital Ocean regions from $digitalOceanSource"
        $digitalOceanNetRangesCsv = Invoke-WebRequestEx -Uri $digitalOceanSource
        if ($null -eq $digitalOceanNetRangesCsv) {
            Write-Warning "Failed to retrieve Digital Ocean IP ranges."
            # return error code to indicate no subnets found (should trigger github action to fail)
            exit 1
        }
        else {
            $digitalOceanNetRanges = ConvertFrom-csv -InputObject $digitalOceanNetRangesCsv.Content  -Header "Subnet","CountryCode","RegionCode","Region","NetworkID"
            foreach ($subnet in $digitalOceanNetRanges) {
                write-progress -activity "Processing Digital Ocean regions" -status "Processing region: $($Subnet.Region)" -percentcomplete (($digitalOceanNetRanges.IndexOf($subnet) / $digitalOceanNetRanges.Count) * 100)
                if (TestIPv4Subnet -IPSubnet $subnet.Subnet) {
                    $digitalOceanRegions += [PSCustomObject]@{
                        Subnet        = $subnet.Subnet
                        Region        = $subnet.Region
                        Service       = ""
                        SubnetSize    = $subnet.Subnet.split("/")[1]
                        CloudProvider = "Digital Ocean"
                    }
                }
            }
            write-progress -activity "Processing Digital Ocean regions" -status "Completed" -completed
            # if no subnets found, return $null and do not update the cache file
            if ($digitalOceanRegions.Count -eq 0) {
                Write-Error "No Digital Ocean IP ranges found. Source may have changed?. No updates saved."
                # return error code to indicate no subnets found (should trigger github action to fail)
                exit 1
            }
            # cache the JSON file for future use in the same directory as the script
            else {
                write-verbose "Digital Ocean subnets found: $($digitalOceanRegions.Count)"
                $digitalOceanRegions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath $digitalOceanCache)
            }
        }   
    }
}

process {
    # load the subnets for each cloud provider, or single provider if specified in -Cloudprovider parameter
    # AWS
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "AWS")) {
        write-progress -activity "Loading subnet ranges" -status "AWS" -percentcomplete 0                       
        GetAWSRegions
    }
    # Azure - Public
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "Azure")) {
        write-progress -activity "Loading subnet ranges" -status "Azure" -percentcomplete 10 
        GetAzureRegions -azureSource $azurePublicSource -azureCache $azurePublicCache -cloudProvider "Azure"
    }
    # Azure - Government
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "Azure")) {
        write-progress -activity "Loading subnet ranges" -status "Azure Government" -percentcomplete 20
        GetAzureRegions -azureSource $azureGovernmentSource -azureCache $azureGovernmentCache -cloudProvider "Azure Government"
    }
    # Azure - China
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "Azure")) {
        write-progress -activity "Loading subnet ranges" -status "Azure China" -percentcomplete 30
        GetAzureRegions -azureSource $azureChinaSource -azureCache $azureChinaCache -cloudProvider "Azure China"
    }
    # Azure - Germany
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "Azure")) {
        write-progress -activity "Loading subnet ranges" -status "Azure Germany" -percentcomplete 40
        GetAzureRegions -azureSource $azureGermanySource -azureCache $azureGermanyCache -cloudProvider "Azure Germany"
    }
    # Google Cloud
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "GoogleCloud")) {
        write-progress -activity "Loading subnet ranges" -status "Google Cloud" -percentcomplete 50
        GetGoogleCloudRegions
    }
    # CloudFlare
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "CloudFlare")) {
        write-progress -activity "Loading subnet ranges" -status "CloudFlare" -percentcomplete 60
        GetCloudFlareRegions
    }
    # Oracle Cloud (OCI)
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "OCI")) {
        write-progress -activity "Loading subnet ranges" -status "Oracle Cloud (OCI)" -percentcomplete 70
        GetOCIRegions
    }
    # Akamai
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "Akamai")) {
        write-progress -activity "Loading subnet ranges" -status "Akamai" -percentcomplete 80
        GetAkamaiRegions
    }
    # Digital Ocean
    if (($CloudProvider -eq "All") -or ($CloudProvider -eq "DigitalOcean")) {
        write-progress -activity "Loading subnet ranges" -status "Digital Ocean" -percentcomplete 90
        GetDigitalOceanRegions
    }
    
    write-progress -activity "Loading subnet ranges" -status "Completed" -completed
}

end {
}

