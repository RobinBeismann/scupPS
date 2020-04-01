$global:log = ""

function Custom-Log($string){
    $log += ([string](Get-Date) + ": $string")
    return $string
}


#Request Information
$requestorMachine = $Data.Query.submitrequestmachine
$reason = $Data.Query.submitdeletereason

if($operation -eq "approvalclearpreview" -or $operation -eq "approvalclear" -and $UserIsAdmin){
    Write-Host("Receiving application approvals for $requestorMachine")
    $oldApprovals = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$requestorMachine'"
    

    if(
        $oldApprovals     
    ){
        $step = 1
        Write-Host("Found old Applications ($($oldApprovals.Application -join ", "))")
        $oldApprovals | ForEach-Object {
            #Check for the action
            if($operation -eq "approvalclearpreview"){
                #Only show approved approval requests
                "$($_.User): $($_.Application)</br>"
                
            }elseif($operation -eq "approvalclear" -and $reason){
                $reqObjOO = [wmi]"\\$SCCMServer\$($SCCMNameSpace):SMS_UserApplicationRequest.RequestGuid=`"$($_.RequestGuid)`"" #Object for object oriented calls
                Write-Host("Deleting Approval: $($_.User): $($_.Application)")
                "Deleting Approval: $($_.User): $($_.Application)</br>"
                Send-AdminNotification -subject "[Approval Deletion] $($_.RequestedMachine)/$($_.User): $($_.Application) Approval deleted by $($authenticatedUser.FullUserName)" -body "Reason was `"$reason`""
                $reqObjOO.Delete()
            }
        }
    }
}

