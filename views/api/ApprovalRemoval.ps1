if($operation -eq "ApprovalRemoval_preview" -or $operation -eq "ApprovalRemoval_submit" -and $(Test-scupPSRole -Name "helpdesk" -User $WebEvent.authenticatedUser)){
    $requestorMachine = $WebEvent.Query.submitrequestmachine
    $reason = $WebEvent.Query.submitdeletereason
    Write-Host("Receiving application approvals for $requestorMachine")
    $oldApprovals = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest where RequestedMachine='$requestorMachine'"

    if(
        $oldApprovals     
    ){
        Write-Host("Found old Applications ($($oldApprovals.Application -join ", "))")
        $oldApprovals | ForEach-Object {
            #Check for the action
            if($operation -eq "ApprovalRemoval_preview"){
                #Only show approved approval requests
                "$($_.User): $($_.Application)</br>"
                
            }elseif($operation -eq "ApprovalRemoval_submit" -and $reason){
                $reqObjOO = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$((Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($_.RequestGuid)`"" #Object for object oriented calls
                Write-Host("Deleting Approval: $($_.User): $($_.Application)")
                "Deleting Approval: $($_.User): $($_.Application)</br>"
                Send-AdminNotification -subject "[Approval Deletion] $($_.RequestedMachine)/$($_.User): $($_.Application) Approval deleted by $($WebEvent.authenticatedUser.FullUserName)" -body "Reason was `"$reason`""
                $reqObjOO.Delete()
            }
        }
    }
}

