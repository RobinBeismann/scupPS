if($operation -eq "ApprovalCreation_Preview" -or $operation -eq "ApprovalCreation_Create" -and $(Test-scupPSRole -Name "helpdesk" -User $WebEvent.authenticatedUser)){
    #Request Information
    $requestorMachineName = $WebEvent.Query.submitrequestmachine
    $requestorUser = $WebEvent.Query.submitrequestuser
    $requestorApplication = $WebEvent.Query.submitrequestapplication
    
    $requestorMachine = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_R_SYSTEM WHERE Name='$requestorMachineName'" | Get-CimInstance
    $existingApproval = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest WHERE RequestedMachine='$requestorMachineName' AND ModelName = '$requestorApplication'" | Get-CimInstance
    $existingApproval = $existingApproval | Where-Object { $_.UserSid -eq $requestorUser }

    if(
        $requestorUser -and
        $requestorApplication -and
		($requestorUserObj = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "SELECT * FROM SMS_R_User WHERE SID = '$requestorUser'") -and
        ($requestorMachineGuid = $requestorMachine.SMSUniqueIdentifier)
    ){
        if(
            ($operation -eq "ApprovalCreation_Preview") -and 
            ($existingApproval | Where-Object { $_.CurrentState -eq 4 }) 
        ){
            "This approval already exists."
        }
        
        if($operation -eq "ApprovalCreation_Create"){
            $approverFirstname = $WebEvent.authenticatedUser.givenName
            $approverLastname = $WebEvent.authenticatedUser.sn
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
                    ClientGUID = [string]$requestorMachine.SMSUniqueIdentifier
                    Comments = $comment
                    Username = $requestorUserObj.UniqueUserName
                };
                Invoke-CimMethod -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -ComputerName (Get-scupPSValue -Name "SCCM_SiteServer") -ClassName "SMS_UserApplicationRequest" -MethodName "CreateApprovedRequest" -Arguments $args
            }           
        }
    }
}

