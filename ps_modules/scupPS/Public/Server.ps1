function Get-ServerReadyness(){
    
    if(Test-PodeState -Name "scupPSServerReady"){
        $ready = Get-PodeState -Name "scupPSServerReady"
    }    

    $ready = $true
    (Get-scupPSDefaultValues).GetEnumerator() | Where-Object { 
        (
            $_.Value.Type -or
            $_.Value.Type -eq 0
        ) -and
        $_.Value.Type -le 3 
    } | ForEach-Object {
        if(
            !($val = (Get-scupPSValue -Name $_.Name)) -or
            $val.StartsWith("<") -or
            $val.EndsWith(">")
        ){
            $ready = $false
        }       
    }
    $null = Set-PodeState -Name "scupPSServerReady" -Value $ready
    return $ready
}