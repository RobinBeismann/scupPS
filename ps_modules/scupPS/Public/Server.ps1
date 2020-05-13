function Get-ServerReadyness(){
    if(
        ($ready = Get-scupPSValue -Name "scupPSServerReady") -and
        $ready -eq $true
    ){
        return $true
    }

    $ready = $true
    $ConfigVals.GetEnumerator() | Where-Object { $_.Value.Type -and $_.Value.Type -le 3 } | ForEach-Object {
        if(
            !($val = (Get-scupPSValue -Name $_.Name)) -or
            $val.StartsWith("<") -or
            $val.EndsWith(">")
        ){
            Write-Host("[$(Get-Date)] Required Value for $($_.Name) is not yet set - server not ready.")
            $ready = $false
        }       
    }
    Set-scupPSValue -Name "scupPSServerReady" -Value $ready
    Write-Host("Ready State: $ready")
    return $ready
}