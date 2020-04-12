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
$requestorMachine = $Data.Query.submitrequestmachine
$newMachine = $Data.Query.submitnewmachine

if($operation -eq "approvaltakeoverpreview" -or $operation -eq "approvaltakeover" -and $UserIsAdmin){

    $oldComputerName = $requestorMachine
    $newComputerName = $newMachine

    $oldApprovals = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$oldComputerName'"
    $newApprovals = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$newComputerName'"
    $newComputer = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_R_SYSTEM where Name='$newComputerName'"

    if(
        $oldApprovals -and
        $newComputer -and
        ($newComputerGUID = $newComputer.SMSUniqueIdentifier)
    ){
        $step = 1
        Write-Host("Found old Applications ($($oldApprovals.Application -join ", ")) and the new computer $newComputerName ($newComputerGUID)")
        $oldApprovals | ForEach-Object {
                  
            #Save old Approval for usage in pipes
            $oldApproval = $_

            #Check if there is already and approval for this machine
            $existingApproval = $newApprovals | Where-Object { $_.ModelName -eq $oldApproval.ModelName -and $_.User -eq $oldApproval.User }
            
            #Check for the action
            if($operation -eq "approvaltakeoverpreview"){
                #Only show approved approval requests
                if($oldApproval.CurrentState -eq 4){
                    "$($OldApproval.User): $($oldApproval.Application)</br>"
                }
            }else{
                $doubleBackslashUsername = $oldApproval.User.Replace("\","\\")
                $oldApprovalUser = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "select * from sms_r_user where UniqueUserName='$doubleBackslashUsername'"
                
                $approvalHistory = Get-CMAppApprovalHistory -requestObject $oldApproval

                Send-AdminNotification -subject "[Approval Takeover] $($_.RequestedMachine)/$($_.User): $($_.Application) Approval taken over from $oldComputerName to $newComputerName by $($authenticatedUser.FullUserName)" -body "History: $($approvalHistory | ForEach-Object { "<br/>$($_.Date): $($_.Comments)" } )"
                $approvalHistory | ForEach-Object {
                    
                    #Request does not yet exist, create it but set auto install to false
                    if(
                        $_.State -eq 1 -and
                        !$existingApproval
                    ){
                        $initialComment = "[$(Get-Date)] $($oldApprovalUser.FullUserName): $($_.Comments)"
                        Write-Host("$($newComputerName): Creating Approval for $($oldApproval.Application) from $($_.Date)")                    
                        "[Step $step] $($oldApproval.Application): Creating initial approval (Old comment: $initialComment)<br/>"
                        $step++
                       # Invoke-CimMethod -Path "SMS_UserApplicationRequest" -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -Name CreateApprovedRequest -ArgumentList @($oldApproval.ModelName, $false, $newComputerGUID, $initialComment, $oldApproval.User) | Out-Null
                        Invoke-CimMethod -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -ComputerName (Get-scupPSValue -Name "SCCM_SiteServer") -ClassName "SMS_UserApplicationRequest" -MethodName "CreateApprovedRequest" -Arguments @{ 
                            ApplicationID = $oldApproval.ModelName
                            AutoInstall = $false
                            ClientGUID = $newComputerGUID
                            Comments = $initialComment
                            Username = $oldApproval.User
                        };
                    
                        #Get approval and deny it for state migration
                        Write-Host("$($newComputerName): Initial deny $($oldApproval.Application) from $($_.Date)")                    
                        "[Step $step] $($oldApproval.Application): Creating initial denial (Old comment: $initialComment)<br/>"
                        $step++
                        $existingApproval = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$newComputerName'" | Where-Object { $_.ModelName -eq $oldApproval.ModelName -and $_.User -eq $oldApproval.User }
                        $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$((Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                        $existingApproval.Deny("System: Initial deny after migration") | Out-Null
                    }
                                
                    #Request was approved before, approve it
                    $existingApproval = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$newComputerName'" | Where-Object { $_.ModelName -eq $oldApproval.ModelName -and $_.User -eq $oldApproval.User }   
                    if($existingApproval){
                        $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$((Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                    }
                    if(
                        $_.State -eq 4 -and
                        $existingApproval
                    ){
                        "[Step $step] $($oldApproval.Application): Approving application (Old comment: $($_.Comments))<br/>"
                        $step++
                        Write-Host("$($newComputerName): Taking over Approval Action $($_.State) for $($oldApproval.Application) from $($_.Date)")
                        $existingApproval.Approve($_.Comments) | Out-Null
                    }
            
                    #Request was denied before, deny it
                    $existingApproval = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$newComputerName'" | Where-Object { $_.ModelName -eq $oldApproval.ModelName -and $_.User -eq $oldApproval.User }
                    if($existingApproval){
                        $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$((Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                    }
                    
                    if(
                        ($_.State -eq 3) -and
                        $existingApproval
                    ){
                        "[Step $step] $($oldApproval.Application): Deny application (Old comment: $($_.Comments))<br/>"
                        $step++
                        Write-Host("$($newComputerName): Taking over Approval Action $($_.State) for $($oldApproval.Application) from $($_.Date)")
                                
                        if($existingApproval.CurrentState -ne 3){
                            $existingApproval.Deny($_.Comments) | Out-Null
                        }
                    }
                }
            }
        }
    }
}

