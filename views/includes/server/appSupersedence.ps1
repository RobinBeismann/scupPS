# Cache Users
Write-Host("Adding Scheduled Job to migrate superseded Approvals..")
Add-PodeSchedule -Name 'migrateSupersededApprovals' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 30

    #Loading config.ps1
    Write-Host("Server: Loading 'config.ps1'..")
    . ".\views\includes\core\config.ps1"
    . ".\views\includes\lib\logging.ps1"

    function Get-CMAppApprovalHistory($requestObject){
        ($requestObject | Get-CimInstance).RequestHistory | ForEach-Object {
        
            [PSCustomObject]@{
                Comments = $_.Comments
                Date = $_.ModifiedDate
                State = $_.State
            }
        } | Sort-Object -Property Date
    }
    #Build a list of superseeding apps
    $SuperseedingApps = @{}
    Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "
        SELECT 
            * 
        FROM 
            SMS_Application
        
        WHERE
            SMS_Application.IsLatest = 1 AND
            SMS_Application.IsSuperseded = 0
    " | ForEach-Object {
        $app = $_ | Get-CimInstance
        [xml]$SDMPackage = $app | Select-Object -ExpandProperty "SDMPackageXML"
        $superseededModelName = $SDMPackage.AppMgmtDigest.DeploymentType.Supersedes.DeploymentTypeRule.DeploymentTypeIntentExpression.DeploymentTypeApplicationReference.AuthoringScopeId + "/" + $SDMPackage.AppMgmtDigest.DeploymentType.Supersedes.DeploymentTypeRule.DeploymentTypeIntentExpression.DeploymentTypeApplicationReference.LogicalName
    
        $SuperseedingApps[$superseededModelName] = $app.ModelName
    }
    
    #Get all superseded apps with approvals and loop through them
    $supersededApprovals = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "
        SELECT 
            * 
        FROM 
            SMS_UserApplicationRequest
        JOIN 
            SMS_Application 
        ON 
            SMS_Application.ModelName = SMS_UserApplicationRequest.ModelName
        WHERE
            SMS_Application.IsLatest = 1 AND
            SMS_Application.IsSuperseded = 1
    "
    
    $supersededApprovals | ForEach-Object {
        
        try{
            #Save old Approval for usage in pipes
            $oldApproval = $_.SMS_UserApplicationRequest | Get-CimInstance
            $computerName = $oldApproval.RequestedMachine
            $computer = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_R_SYSTEM where Name='$computerName'"
            $computerGUID = $computer.SMSUniqueIdentifier
            $doubleBackslashUsername = $oldApproval.User.Replace("\","\\")
            $oldApprovalUser = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "select * from sms_r_user where UniqueUserName='$doubleBackslashUsername'"

            #Check if there is already and approval for this machine
            $newAppModelName = $superseedingApps[$oldApproval.ModelName]
            $migratedApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "
                SELECT 
                    * 
                FROM 
                    SMS_UserApplicationRequest
                WHERE
                    User = '$doubleBackslashUsername' AND
                    ModelName = '$newAppModelName' AND
                    RequestedMachine = '$computerName'
            "

            $approvalHistory = Get-CMAppApprovalHistory -requestObject $oldApproval
            
            if(
                $approvalHistory -and
                $oldApproval -and
                $computerName -and
                $computer -and
                $computerGUID -and
                $doubleBackslashUsername -and
                $oldApprovalUser -and
                $newAppModelName -and
                !$migratedApproval
            ){
                $step = 1
                $approvalHistory | ForEach-Object {
                    
                    #Request does not yet exist, create it but set auto install to false
                    if(
                        $_.State -eq 1
                    ){
                        $initialComment = "[$(Get-Date)] Migrated Request from $($oldApprovalUser.FullUserName): $($_.Comments)"
                        Write-Host("$($computerName): Creating Approval for $($oldApproval.Application) from $($_.Date)")                    
                        "[Step $step] $($oldApproval.Application): Creating initial approval (Old comment: $initialComment)<br/>"
                        $step++

                        $cimArgs = @{ 
                            ApplicationID = $newAppModelName
                            AutoInstall = $false
                            ClientGUID = $computerGUID
                            Comments = $initialComment
                            Username = $oldApproval.User
                        }
                        Invoke-CimMethod -Namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -ComputerName $(Get-scupPSValue -Name "SCCM_SiteServer") -ClassName "SMS_UserApplicationRequest" -MethodName "CreateApprovedRequest" -Arguments $cimArgs
                    
                        #Get approval and deny it for state migration
                        Write-Host("$($computerName): Initial deny $($oldApproval.Application) from $($_.Date)")                    
                        "[Step $step] $($oldApproval.Application): Creating initial denial (Old comment: $initialComment)<br/>"
                        $step++
                        $existingApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "
                            SELECT 
                                * 
                            FROM 
                                SMS_UserApplicationRequest 
                            WHERE
                                User = '$doubleBackslashUsername' AND
                                ModelName = '$newAppModelName' AND
                                RequestedMachine = '$($oldApproval.RequestedMachine)'
                        "
                        $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$($(Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                        $existingApproval.Deny("System: This has been upgraded. If your previous request was not approved, please re-request it.") | Out-Null
                    }
                                
                    #Request was approved before, approve it
                    $existingApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "
                        SELECT 
                            * 
                        FROM 
                            SMS_UserApplicationRequest 
                        WHERE
                            User = '$doubleBackslashUsername' AND
                            ModelName = '$newAppModelName' AND
                            RequestedMachine = '$($oldApproval.RequestedMachine)'
                    "
                    if($existingApproval){
                        $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$($(Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                    }
                    if(
                        $_.State -eq 4 -and
                        $existingApproval
                    ){
                        "[Step $step] $($oldApproval.Application): Approving application (Old comment: $($_.Comments))<br/>"
                        $step++
                        Write-Host("$($computerName): Taking over Approval Action $($_.State) for $($oldApproval.Application) from $($_.Date)")
                        $existingApproval.Approve("[Migrated] $($_.Comments)") | Out-Null
                    }

                    #Request was denied before, deny it        
                    $existingApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "
                        SELECT 
                            * 
                        FROM 
                            SMS_UserApplicationRequest 
                        WHERE
                            User = '$doubleBackslashUsername' AND
                            ModelName = '$newAppModelName' AND
                            RequestedMachine = '$($oldApproval.RequestedMachine)'
                    "
                    if($existingApproval){
                        $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$($(Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                    }
                    
                    if(
                        ($_.State -eq 3) -and
                        $existingApproval
                    ){
                        "[Step $step] $($oldApproval.Application): Deny application (Old comment: $($_.Comments))<br/>"
                        $step++
                        Write-Host("$($computerName): Taking over Approval Action $($_.State) for $($oldApproval.Application) from $($_.Date)")
                                
                        if($existingApproval.CurrentState -ne 3){
                            $existingApproval.Deny("[Migrated] $($_.Comments)") | Out-Null
                        }
                    }
                }
            }
        }catch{
            Write-scupPSLog("Error during superseedence Migration: $_")
        }
    }

}
