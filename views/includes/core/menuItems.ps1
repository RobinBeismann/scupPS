$Data.menuItems = [ordered]@{}
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
            $Data.menuItems.$itemName = $url
        }
    }
}