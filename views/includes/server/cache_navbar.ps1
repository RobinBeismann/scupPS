# Cache Navigation Bar
Write-Host("Adding Scheduled Job to rebuild the Navigation Bar once per hour and initially at the start..")
Add-PodeSchedule -Name 'CacheNavbar' -Cron '@hourly' -OnStart -ScriptBlock { 

    $obj = [ordered]@{}
    $regex = "(?m)<!--.*Item Name: '(?'itemname'[^']*)' .*-->.*", "(?m)<!--.*Item Suburl: '(?'suburl'[^']*)' .*-->.*", "(?m)<!--.*Item Role: '(?'role'[^']*)' .*-->.*"
    Get-ChildItem -Path "$(Get-PodeState -Name "PSScriptRoot")\views\pages\" -Filter "*.pode" | ForEach-Object {
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
}
