Write-Host("Adding Scheduled Job to rebuild the Navigation Bar once per hour and initially at the start..")
Add-PodeSchedule -Name 'LoadNavbar' -Cron '@hourly' -OnStart -ScriptBlock { 

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