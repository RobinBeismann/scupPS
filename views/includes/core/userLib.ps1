#Get authenticated user
if(
    !($AuthenticatedUserSID = (Get-PodeState -Name "cache_UsersDNtoSID").($Data.Auth.User.DistinguishedName)) -or
    !($AuthenticatedUser = (Get-scupPSUsers).$AuthenticatedUserSID) -or
    !($doubleBackslashUsername = $authenticatedUser.UniqueUserName.Replace("\","\\"))
){
    $AuthenticatedUser = $null
}###################################################### HANDLE PROPERLY!

    #$AuthenticatedUser = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -Query "select * from sms_r_user where DistinguishedName='$($Data.Auth.User.DistinguishedName)'"

#Check if the user is admin and if so set the variable, other pages may rely on this
$userIsAdmin = $null
$userIsCostcenterManager = $null

if(
    $AuthenticatedUser -and 
    $AuthenticatedUser.UserGroupName -and 
    ($(Get-scupPSValue -Name "scupPSAdminGroup") -in $AuthenticatedUser.UserGroupName)
){
    $userIsAdmin = $true
}

#Build up managed costcenter tables
$managedCostCenters = $null
if(
    ($managedCostCenters = $authenticatedUser.$(Get-scupPSValue -Name "Attribute_managedcostCenters")) -and
    ($managedCostCenters -ne "") -and
    ($managedCostCenters -ne "#")    
){
    $managedCostCenters = $managedCostCenters.Split(";")
    $userIsCostCenterManager = $true
}else{
    $managedCostCenters = $null
}

function Test-ApproveCompetence($Manager,$User){
    $isAdmin = $(Get-scupPSValue -Name "scupPSAdminGroup") -in $Manager.UserGroupName
    $managerCostcenters = $Manager.$(Get-scupPSValue -Name "Attribute_managedcostCenters")
    $userCostcenter = $User.$(Get-scupPSValue -Name "Attribute_costCenter")

    if(
        ($userCostcenter -and $managerCostcenters) -or $isAdmin
    ){
        $managerCostcenters = $managerCostcenters.Split(";")
        if(
            $isAdmin -or 
            ($userCostcenter -in $managerCostcenters)             
        ){
            return $true
        }
    }
    return $false
}