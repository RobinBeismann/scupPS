#Get authenticated user
$AuthenticatedUserSID = (Get-PodeState -Name "cache_UsersDNtoSID").($Data.Auth.User.DistinguishedName)
$AuthenticatedUser = (Get-PodeState -Name "cache_Users").$AuthenticatedUserSID
#$AuthenticatedUser = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -Query "select * from sms_r_user where DistinguishedName='$($Data.Auth.User.DistinguishedName)'"

#Check if the user is admin and if so set the variable, other pages may rely on this
$userIsAdmin = $null
$userIsCostcenterManager = $null

if(
    $AuthenticatedUser -and 
    $AuthenticatedUser.UserGroupName -and 
    ($Group_PortalAdmins -in $AuthenticatedUser.UserGroupName)
){
    $userIsAdmin = $true
}

#Build up managed costcenter tables
$managedCostCenters = $null
if(
    ($managedCostCenters = $authenticatedUser.$Attribute_managedcostCenters) -and
    ($managedCostCenters -ne "") -and
    ($managedCostCenters -ne "#")    
){
    $managedCostCenters = $managedCostCenters.Split(";")
    $userIsCostCenterManager = $true
}else{
    $managedCostCenters = $null
}

function Test-ApproveCompetence($Manager,$User){
    $isAdmin = $Group_PortalAdmins -in $Manager.UserGroupName
    $managerCostcenters = $Manager.$Attribute_managedcostCenters

    if(
        ($userCostcenter = $User.$Attribute_costCenter) -and 
        (
            $managerCostcenters -or $isAdmin
        )
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