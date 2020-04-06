# Cache Users
Write-Host("Adding Scheduled Job to cache users..")
Add-PodeSchedule -Name 'CacheUsers' -Cron '@hourly' -OnStart -ScriptBlock {  
    #Loading config.ps1
    Write-Host("Server: Loading 'config.ps1'..")
    . ".\views\includes\core\config.ps1"

    function ConvertTo-Hashtable
    {
        param (
            [Parameter(ValueFromPipeline)]
            $InputObject
        )
    
        process
        {
            if ($null -eq $InputObject) { return $null }
    
            if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
            {
                $collection = @(
                    foreach ($object in $InputObject) { ConvertTo-Hashtable $object }
                )
    
                Write-Output -NoEnumerate $collection
            }
            elseif ($InputObject -is [psobject])
            {
                $hash = @{}
    
                foreach ($property in $InputObject.PSObject.Properties)
                {
                    if(!($property.Name.StartsWith("Cim"))){
                        $hash[$property.Name] = ConvertTo-Hashtable $property.Value
                    }
                }
    
                $hash
            }
            else
            {
                $InputObject
            }
        }
    }
    
    $users = @{}
    $usersDNtoSID = @{}
    Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "SELECT * FROM SMS_R_USER WHERE displayName IS NOT NULL" |  ForEach-Object {    
        $users.($_.SID) += ConvertTo-Hashtable -InputObject $_
        $usersDNtoSID.$($_.DistinguishedName) = $_.SID
    }
    

    Write-Host("Caching $($users.Count) Users..")
    Set-PodeState -Name "cache_Users" -Value $users
    Set-PodeState -Name "cache_UsersDNtoSID" -Value $usersDNtoSID
    
    Save-PodeState -Path ".\states.json"
}

# Cache Applications
Write-Host("Adding Scheduled Job to cache applications..")
Add-PodeSchedule -Name 'CacheApplications' -Cron '@hourly' -OnStart -ScriptBlock {  
    #Loading config.ps1
    Write-Host("Server: Loading 'config.ps1'..")
    . ".\views\includes\core\config.ps1"

    function ConvertTo-Hashtable
    {
        param (
            [Parameter(ValueFromPipeline)]
            $InputObject
        )
    
        process
        {
            if ($null -eq $InputObject) { return $null }
    
            if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
            {
                $collection = @(
                    foreach ($object in $InputObject) { ConvertTo-Hashtable $object }
                )
    
                Write-Output -NoEnumerate $collection
            }
            elseif ($InputObject -is [psobject])
            {
                $hash = @{}
    
                foreach ($property in $InputObject.PSObject.Properties)
                {
                    if(!($property.Name.StartsWith("Cim"))){
                        $hash[$property.Name] = ConvertTo-Hashtable $property.Value
                    }
                }
    
                $hash
            }
            else
            {
                $InputObject
            }
        }
    }
    
    $applications = @{}
    Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "SELECT * FROM SMS_Application WHERE IsLatest = 1" |  ForEach-Object {    
        $applications.($_.Modelname) += ConvertTo-Hashtable -InputObject $_
    }

    Write-Host("Caching $($applications.Count) Applications..")
    Set-PodeState -Name "cache_Applications" -Value $applications
    Save-PodeState -Path ".\states.json"
}

# Cache Navigation Bar
Write-Host("Adding Scheduled Job to rebuild the Navigation Bar once per hour and initially at the start..")
Add-PodeSchedule -Name 'CacheNavbar' -Cron '@hourly' -OnStart -ScriptBlock { 

    $obj = [ordered]@{}
    $regex = "(?m)<!-- Item Name: '(?'itemname'[^']*)'(( -->.*)|( Item Suburl: '(?'suburl'[^']*)' -->.*))"
    Get-ChildItem -Path ".\views\pages" -Filter "*.pode" | ForEach-Object {
        $baseName = $_.BaseName
            $_ | Get-Content | Select-Object -First 10 | ForEach-Object {
            if( 
                ($match = [regex]::Match( $_, $regex)) -and
                ($match.Success -eq $true) -and
                ($match.Groups['itemname'].Success) -and
                ($itemName = $match.Groups['itemname'].Value)
            ){
                $url = $baseName
                if(
                    ($match.Groups['suburl'].Success) -and
                    ($suburl = $match.Groups['suburl'].Value)
                ){
                    $url = $url + $suburl
                }
                $obj.$itemName = $url
            }
        }
    }
    Set-PodeState -Name "navItems" -Value $obj | Out-Null
    Save-PodeState -Path ".\states.json"
}