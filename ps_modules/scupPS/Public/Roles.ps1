function Test-ApproveCompetence($Manager,$User){
    $isAdmin = Test-scupPSRole -Name "helpdesk" -User $Manager
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

function Get-scupPSRole($Name){
    $roles = Get-scupPSValue -Name "scupPSRoles" | ConvertFrom-Json

    if(!$Name){
        return $roles
    }elseif($roles.$Name){
        return $roles.$Name
    }
        
    return $false    
}

function Set-scupPSRole($Name,$Value){
    $roles = Get-scupPSValue -Name "scupPSRoles" | ConvertFrom-Json

    if(
        !($roles.$Name) -or
        ($roles | Get-Member -Name $Name -ErrorAction SilentlyContinue) -ne $Value
    ){
        Write-Host("Set-scupPSRole: Updating Role Val '$Name' to '$Value'")
        $roles.$Name = $Value
        Set-scupPSValue -Name "scupPSRoles" -Value ($roles | ConvertTo-Json)
    }
}

function Test-scupPSRole($Name,$User){
    if($Name){
        if(
            !$Name -or
            !$User -or 
            !($role = Get-scupPSRole -Name $Name)
        ){
            return $false
        }   
        return ($role -in $user.UserGroupName)
    }else{
        if(Get-ServerReadyness){
            (Get-scupPSRole).PSObject.Properties | ForEach-Object {
                if(Test-scupPSRole -User $User -Name $_.Name){
                    $_.Name
                }
            }
        }
    }    
}