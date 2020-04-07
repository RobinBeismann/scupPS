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
    $existingApproval = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "Select * From SMS_UserApplicationRequest WHERE RequestedMachine='$requestorMachineName' AND ModelName = '$requestorApplication'" | Get-CimInstance
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
                $existingApproval = [wmi]"\\$SCCMServer\$($SCCMNameSpace):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                $existingApproval.Approve($comment) | Out-Null
            }else{
                "Approval does not exists, created new approval as admin"
                $args = @{ 
                    ApplicationID = $requestorApplication
                    AutoInstall = $true
                    ClientGUID = $requestorMachineGuid
                    Comments = $comment
                    Username = (Get-PodeState -Name "cache_Users").$requestorUser.UniqueUserName
                };
                Invoke-CimMethod -Namespace $SCCMNameSpace -ComputerName $SCCMServer -ClassName "SMS_UserApplicationRequest" -MethodName "CreateApprovedRequest" -Arguments $args
            }           
        }
    }
}

