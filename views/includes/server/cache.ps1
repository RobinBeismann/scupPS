# Cache Applications
Write-Host("Adding Scheduled Job to cache applications..")
Add-PodeSchedule -Name 'CacheApplications' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 10
    #Loading config.ps1
    Write-Host("Server: Loading 'config.ps1'..")
    . ".\views\includes\core\config.ps1"
    while(
        (Get-ServerReadyness) -eq $false
    ){
        Start-Sleep -Seconds 10
    }
    $applications = @{}
    Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
        SELECT 
            ModelName,CI_ID 
        FROM 
            SMS_Application 
        WHERE 
            IsLatest = 1
    " | Get-CimInstance | ForEach-Object {    
        $data = $null
        [xml]$xml = $_ | Select-Object -ExpandProperty SDMPackageXML
        if($xml.AppMgmtDigest.Application.DisplayInfo.Info.Count -gt 1){
            $data = $xml.AppMgmtDigest.Application.DisplayInfo.Info | Where-Object {
                $_.Language.ToLower() -eq "en-US" -or
                $_.Language.ToLower() -eq "en"
            }
        }else{
            $data = $xml.AppMgmtDigest.Application.DisplayInfo.Info
        }
        
        $applications.($_.Modelname) = @{
            Publisher =$data.Publisher
            Title = $data.Title
            Description = $data.Description
        }
    }

    Write-Host("Caching $($applications.Count) Applications..")
    Set-PodeState -Name "cache_Applications" -Value $applications
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

# Regulary transfer values
Write-Host("Adding Scheduled Job to save states every minute..")
Add-PodeSchedule -Name 'saveValues' -Cron '@hourly' -OnStart -ScriptBlock { 
    #Update the role with the group set under general settings
    Set-scupPSRole -Name "admin" -Value (Get-scupPSValue -Name "scupPSAdminGroup")
}