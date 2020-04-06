$global:log = ""

function Custom-Log($string){
    $log += ([string](Get-Date) + ": $string")
    return $string
}

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

if($operation -eq "approvalcreationpreview" -or $operation -eq "approvalcreation" -and $UserIsAdmin){
    
    $requestorMachine = (Get-PodeState -Name "cache_Machines").$requestorMachineName
    $existingApprovals = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "Select * From SMS_UserApplicationRequest WHERE RequestedMachine='$requestorMachineName' AND ModelName = '$requestorApplication'"
    
    if(
        $requestorUser -and
        $requestorApplication -and
        ($requestorMachineGuid = $requestorMachine.SMSUniqueIdentifier)
    ){
        if($operation -eq "approvalcreationpreview" -and $existingApprovals){
            "This approval already exists."
        }
        <#
        $existingApprovals | ForEach-Object {
                  
            #Check for the action
            if($operation -eq "approvalcreationpreview"){
                #Only show approved approval requests
                if($_.CurrentState -eq 4){
                    "$($_.User): $($_.Application)</br>"
                }
            }else{
                $doubleBackslashUsername = $oldApproval.User.Replace("\","\\")
                $oldApprovalUser = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select * from sms_r_user where UniqueUserName='$doubleBackslashUsername'"
                
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
                       # Invoke-CimMethod -Path "SMS_UserApplicationRequest" -Namespace $SCCMNameSpace -computer $SCCMServer -Name CreateApprovedRequest -ArgumentList @($oldApproval.ModelName, $false, $newComputerGUID, $initialComment, $oldApproval.User) | Out-Null
                        Invoke-CimMethod -Namespace $SCCMNameSpace -ComputerName $SCCMServer -ClassName "SMS_UserApplicationRequest" -MethodName "CreateApprovedRequest" -Arguments @{ 
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
                        $existingApproval = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$newComputerName'" | Where-Object { $_.ModelName -eq $oldApproval.ModelName -and $_.User -eq $oldApproval.User }
                        $existingApproval = [wmi]"\\$SCCMServer\$($SCCMNameSpace):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                        $existingApproval.Deny("System: Initial deny after migration") | Out-Null
                    }
                                
                    #Request was approved before, approve it
                    $existingApproval = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$newComputerName'" | Where-Object { $_.ModelName -eq $oldApproval.ModelName -and $_.User -eq $oldApproval.User }   
                    if($existingApproval){
                        $existingApproval = [wmi]"\\$SCCMServer\$($SCCMNameSpace):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
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
                    $existingApproval = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$newComputerName'" | Where-Object { $_.ModelName -eq $oldApproval.ModelName -and $_.User -eq $oldApproval.User }
                    if($existingApproval){
                        $existingApproval = [wmi]"\\$SCCMServer\$($SCCMNameSpace):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
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
        }#>
    }
}

