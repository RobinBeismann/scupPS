function Get-scupPSAuthUser($Data){
    if(
        !($Data.Auth.User.DistinguishedName) -or
        !($AuthenticatedUser = Get-CimInstance -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -Computer (Get-scupPSValue -Name "SCCM_SiteServer") -Query "select * from sms_r_user where DistinguishedName='$($Data.Auth.User.DistinguishedName.Replace("\","\\"))'") -or
        !($doubleBackslashUsername = $authenticatedUser.UniqueUserName.Replace("\","\\"))
    ){
        $AuthenticatedUser = $null
    }
    return $AuthenticatedUser
}

function Get-scupPSManagedCostCenters($Data){
    $authenticatedUser = Get-scupPSAuthUser($Data)
    $managedCostCenters = $null
    if(
        ($managedCostCenters = $authenticatedUser.$(Get-scupPSValue -Name "Attribute_managedcostCenters")) -and
        ($managedCostCenters -ne "") -and
        ($managedCostCenters -ne "#")    
    ){
        $managedCostCenters = $managedCostCenters.Split(";")
    }else{
        $managedCostCenters = $null
    }

    return $managedCostCenters
}