$(
    #Include Config
    . ".\views\includes\core\config.ps1"
    . ".\views\includes\core\userLib.ps1"
)

if(
    ($operation -eq "setup") -and
    (
        ((Get-ServerReadyness) -eq $false) -or
        (
            ($user = Get-CimInstance -Computer (Get-scupPSValue -Name "SCCM_SiteServer") -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -Query "select * from sms_r_user where DistinguishedName='$($Data.Auth.User.DistinguishedName)'") -and
            ((Get-scupPSValue -Name "scupPSAdminGroup") -in $user.UserGroupName)
        )
    )
){
    $requestInfo = $Data.Query
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
        return $false
    }
    switch($requestInfo.fieldName){
        "SCCM_SiteServer" {
            if($res = Get-CimInstance -ComputerName $requestInfo.FieldValue -ClassName "SMS_ProviderLocation" -Namespace "ROOT\SMS"){
                $res = $true
            }
        }
        
        "SCCM_SiteName" {
            if($res = Get-CimInstance -ComputerName (Get-scupPSValue -Name "SCCM_SiteServer") -ClassName "SMS_Site" -Namespace "ROOT\SMS\site_$($requestInfo.FieldValue)"){
                Set-scupPSValue -Name "SCCM_SiteNamespace" -Value "ROOT\SMS\site_$($requestInfo.FieldValue)"
                $res = $true
            }
        }
        "scupPSAdminGroup" {
            if(
                ($user = Get-CimInstance -Computer (Get-scupPSValue -Name "SCCM_SiteServer") -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -Query "select * from sms_r_user where DistinguishedName='$($Data.Auth.User.DistinguishedName)'") -and
                ($requestInfo.FieldValue -in $user.UserGroupName)
            ){
                $res = $true
            }
        }
        default {
            $res = $true
        }
    }

    if($res -eq $true){
        Write-Host("scupPSSetup API: Instructing Config Management to update '$($requestInfo.fieldName)' to '$($requestInfo.FieldValue)'")
        Set-scupPSValue -Name $requestInfo.fieldName -Value $requestInfo.FieldValue
    }
    return $res
}