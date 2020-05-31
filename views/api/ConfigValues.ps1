if(
    ($operation -eq "ConfigValues_submit") -and
    (
        ((Get-ServerReadyness) -eq $false) -or
        (
            (Test-scupPSRole -Name "admin" -User $Data.authenticatedUser)
        )
    )
){
    $requestInfo = $Data.Query
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

        "SCCM_SiteDatabaseInstance" {
            if(Invoke-Sqlcmd2 -ServerInstance $requestInfo.FieldValue -Query "SELECT 1" -ConnectionTimeout 2 -ErrorAction SilentlyContinue){
                $res = $true
            }
        }

        "SCCM_SiteDatabaseName" {
            if(Invoke-Sqlcmd2 -ServerInstance (Get-scupPSValue -Name "SCCM_SiteDatabaseInstance") -Database $requestInfo.FieldValue -Query "SELECT 1" -ConnectionTimeout 2 -ErrorAction SilentlyContinue){
                $res = $true
            }
        }

        "scupPSAdminGroup" {
            if(
                ($user = Get-CimInstance -Computer (Get-scupPSValue -Name "SCCM_SiteServer") -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -Query "select * from sms_r_user where DistinguishedName='$($Data.Auth.User.DistinguishedName.Replace("\","\\"))'") -and
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