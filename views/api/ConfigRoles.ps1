if(
    ($operation -eq "ConfigRoles_submit") -and
    (
        ((Get-ServerReadyness) -eq $true) -and
        (
            (Test-scupPSRole -Name "admin" -User $Data.authenticatedUser)
        )
    )
){
    $requestInfo = $Data.Query
    $res = $true
    if(
        ((Get-scupPSDefaultValues).$($requestInfo.FieldName).Type -ne 5) -and
        (
            !$requestInfo.FieldValue -or 
            (
                $requestInfo.FieldValue.StartsWith("<") -or
                $requestInfo.FieldValue.EndsWith(">")
            )
        )
    ){
        $res = $false
    }
    
    if($res -eq $true){
        Write-Host("scupPSSetup API: Instructing Config Management to update Role '$($requestInfo.fieldName)' to '$($requestInfo.FieldValue)'")
        Set-scupPSRole -Name $requestInfo.fieldName -Value $requestInfo.FieldValue
    }
    return $res
}