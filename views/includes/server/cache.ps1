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
    Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
    SELECT 
        * 
    FROM 
        SMS_R_USER 
    WHERE 
            givenName IS NOT NULL 
        AND
            sn IS NOT NULL  
    " |  ForEach-Object {    
        $users.($_.SID) += ConvertTo-Hashtable -InputObject $_
        $usersDNtoSID.$($_.DistinguishedName) = $_.SID
    }
    

    Write-Host("Caching $($users.Count) Users..")
    Set-PodeState -Name "cache_Users" -Value $users
    Set-PodeState -Name "cache_UsersDNtoSID" -Value $usersDNtoSID
    Invoke-PodeSchedule -Name 'saveStates'
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
    Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "SELECT * FROM SMS_Application WHERE IsLatest = 1" |  ForEach-Object {    
        $applications.($_.Modelname) += ConvertTo-Hashtable -InputObject $_
    }

    Write-Host("Caching $($applications.Count) Applications..")
    Set-PodeState -Name "cache_Applications" -Value $applications
    Invoke-PodeSchedule -Name 'saveStates'
}

# Cache Machines
Write-Host("Adding Scheduled Job to cache machines..")
Add-PodeSchedule -Name 'CacheMachines' -Cron '@hourly' -OnStart -ScriptBlock {  
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
    
    $machines = @{}
    Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "SELECT * FROM SMS_R_SYSTEM" |  ForEach-Object {    
        $machines.($_.Name) += ConvertTo-Hashtable -InputObject $_
    }

    Write-Host("Caching $($machines.Count) Machines..")
    Set-PodeState -Name "cache_Machines" -Value $machines
    Invoke-PodeSchedule -Name 'saveStates'
}

# Cache Navigation Bar
Write-Host("Adding Scheduled Job to rebuild the Navigation Bar once per hour and initially at the start..")
Add-PodeSchedule -Name 'CacheNavbar' -Cron '@hourly' -OnStart -ScriptBlock { 

    $obj = [ordered]@{}
    $regex = "(?m)<!--.*Item Name: '(?'itemname'[^']*)' .*-->.*", "(?m)<!--.*Item Suburl: '(?'suburl'[^']*)' .*-->.*", "(?m)<!--.*Item Role: '(?'role'[^']*)' .*-->.*"
    Get-ChildItem -Path ".\views\pages" -Filter "*.pode" | ForEach-Object {
        $baseName = $_.BaseName
        $_ | Get-Content | Select-Object -First 10 | ForEach-Object {
            $string = $_
            
            $matches = @{}
            $regex.GetEnumerator() | Foreach-Object {
                if(
                    ($match = [regex]::Match($string,$_)) -and
                    ($match.Success -eq $true) -and
                    ($match.Groups.Count -gt 1)    
                ){
                    $match.Groups | Where-Object { $_.Name.Length -gt 3 } | ForEach-Object {
                        $matches.($_.Name) = $_.Value
                    }
                }
            }
        
            if(
                ($itemName = $matches['itemname'])
            ){
                $obj.$itemName = @{}
                $obj.$itemName.baseName = $baseName
                $url = $baseName
                if(
                    ($suburl = $matches['suburl'])
                ){
                    $url = $url + $suburl
                }
                if(
                    ($role = $matches['role'])
                ){
                    $obj.$itemname.role = $role
                }
                $obj.$itemName.url = $url
            }
        }
    }
    Set-PodeState -Name "navItems" -Value $obj | Out-Null
    Invoke-PodeSchedule -Name 'saveStates'
}

# Regulary save states
Write-Host("Adding Scheduled Job to save states every minute..")
Add-PodeSchedule -Name 'saveStates' -Cron '@minutely' -ScriptBlock { 
    #param($e)        
    #Lock-PodeObject -Object $e.Lockable -ScriptBlock {
        Save-PodeState -Path ".\states.json"
    #}
}