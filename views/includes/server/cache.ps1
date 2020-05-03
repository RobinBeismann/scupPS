# Cache Applications
Write-Host("Adding Scheduled Job to cache applications..")
Add-PodeSchedule -Name 'CacheApplications' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 10
    
    #Include Config
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\core\config.ps1"

    if(Test-scupPSJobMaster){
        Write-Host("Caching Applications..")
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
            
            Execute-SQLiteQuery -Query @"
            INSERT OR REPLACE INTO 
                "main"."applications" 
                (
                    "app_modelname", 
                    "app_publisher", 
                    "app_title", 
                    "app_description"
                ) VALUES (
                    "$($_.Modelname)", 
                    "$($data.Publisher)", 
                    "$($data.Title)", 
                    "$($data.Description)"
                )
"@
        }
        Write-Host("Cached $((Execute-SQLiteQuery -Query "SELECT COUNT(app_modelname) FROM applications;").'COUNT(app_modelname)') Applications..")
    }
}

# Cache Navigation Bar
Write-Host("Adding Scheduled Job to rebuild the Navigation Bar once per hour and initially at the start..")
Add-PodeSchedule -Name 'CacheNavbar' -Cron '@hourly' -OnStart -ScriptBlock { 
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\core\config.ps1"

    if(Test-scupPSJobMaster){
        Write-Host("Caching Nav Items..")
        $regex = "(?m)<!--.*Item Name: '(?'itemname'[^']*)' .*-->.*", "(?m)<!--.*Item Suburl: '(?'suburl'[^']*)' .*-->.*", "(?m)<!--.*Item Role: '(?'role'[^']*)' .*-->.*"
        Get-ChildItem -Path "$(Get-PodeState -Name "PSScriptRoot")\views\pages" -Filter "*.pode" | ForEach-Object {
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
                    $url = $baseName
                    if(
                        ($suburl = $matches['suburl'])
                    ){
                        $url = $url + $suburl
                    }
                    $role = $matches['role']

                    Execute-SQLiteQuery -Query @"
                    INSERT OR REPLACE INTO 
                        "main"."nav" 
                        (
                            "nav_name", 
                            "nav_baseName", 
                            "nav_role", 
                            "nav_url"
                        ) VALUES (
                            "$itemName", 
                            "$baseName", 
                            "$role", 
                            "$url"
                        )
"@
                }
            }
        }
        Write-Host("Cached $((Execute-SQLiteQuery -Query "SELECT COUNT(nav_name) FROM nav;").'COUNT(nav_name)') Nav Items..")
    }
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
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\core\config.ps1"
    Set-scupPSRole -Name "admin" -Value (Get-scupPSValue -Name "scupPSAdminGroup")
}
