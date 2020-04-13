function Get-CMAppApprovalHistory($requestObject){
    ($requestObject | Get-CimInstance).RequestHistory | ForEach-Object {
    
        [PSCustomObject]@{
            Comments = $_.Comments
            Date = $_.ModifiedDate
            State = $_.State
        }
    } | Sort-Object -Property Date
}


#Request Information
$requestorMachineName = $Data.Query.submitrequestmachine
$requestorUser = $Data.Query.submitrequestuser
$requestorApplication = $Data.Query.submitrequestapplication

if($operation -eq "approvalcreationpreview" -or $operation -eq "approvalcreation" -and $(Test-scupPSRole -Name "helpdesk" -User $authenticatedUser)){
    
    $requestorMachine = (Get-scupPSMachines).$requestorMachineName
    $existingApproval = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest WHERE RequestedMachine='$requestorMachineName' AND ModelName = '$requestorApplication'" | Get-CimInstance
    $existingApproval = $existingApproval | Where-Object { $_.UserSid -eq $requestorUser }

    if(
        $requestorUser -and
        $requestorApplication -and
        ($requestorMachineGuid = $requestorMachine.SMSUniqueIdentifier)
    ){
        if(
            ($operation -eq "approvalcreationpreview") -and 
            ($existingApproval | Where-Object { $_.State -eq 4 }) 
        ){
            "This approval already exists."
        }
        
        if($operation -eq "approvalcreation"){
            $approverFirstname = $authenticatedUser.givenName
            $approverLastname = $authenticatedUser.sn
            $approverDisplayNameV1 = "$approverLastname, $approverFirstname" 
            $comment = "Pre-approved by $($approverDisplayNameV1)."
            
            if($existingApproval){
                "Approval already exists, force approving it as admin"
                $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$((Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                $existingApproval.Approve($comment) | Out-Null
            }else{
                "Approval does not exists, created new approval as admin"
                $args = @{ 
                    ApplicationID = $requestorApplication
                    AutoInstall = $true
                    ClientGUID = $requestorMachineGuid
                    Comments = $comment
                    Username = (Get-scupPSUsers).$requestorUser.UniqueUserName
                };
                Invoke-CimMethod -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -ComputerName (Get-scupPSValue -Name "SCCM_SiteServer") -ClassName "SMS_UserApplicationRequest" -MethodName "CreateApprovedRequest" -Arguments $args
            }           
        }
    }
}

