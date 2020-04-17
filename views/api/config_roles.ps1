$(
    #Include Config
    . ".\views\includes\core\config.ps1"
    . ".\views\includes\core\userLib.ps1"
)

if(
    ($operation -eq "roles") -and
    (
        ((Get-ServerReadyness) -eq $true) -and
        (
            ($user = Get-CimInstance -Computer (Get-scupPSValue -Name "SCCM_SiteServer") -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -Query "select * from sms_r_user where DistinguishedName='$($Data.Auth.User.DistinguishedName.Replace("\","\\"))'") -and
            ((Get-scupPSValue -Name "scupPSAdminGroup") -in $user.UserGroupName)
        )
    )
){
    $requestInfo = $Data.Query
    $res = $true
    if(
        ($ConfigVals.$($requestInfo.FieldName).Type -ne 5) -and
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