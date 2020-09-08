# Add Job
Write-Host("Adding Scheduled Job to migrate superseded Approvals..")
Add-PodeSchedule -Name 'migrateSupersededApprovals' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 30

    #Loading config.ps1
    Write-Host("Server: Executing Approval Migration Job run..")

    #Build a list of superseeding apps
    try{
        Write-Host("Server: Approval Migration Job: Collecting superseeding apps..")

        $SuperseedingApps = @{}
        $appSupersedes = Invoke-scupCCMSqlQuery -Query "
                SELECT 
                    SourceCI.ModelName AS SuperseedingApp_ModelName,
                    SourceCI.DisplayName AS SuperseedingApp_ModelName_DisplayName,
                    SourceCI.IsSuperseded AS SuperseedingApp_IsSuperseded,
                    DestCI.ModelName AS SuperseededApp_ModelName,
                    DestCI.DisplayName AS SuperseededApp_DisplayName,
                    DestCI.IsSuperseded AS SuperseededApp_IsSuperseded
                FROM
                    vSMS_AppRelation_Flat as rel
                LEFT JOIN fn_ListLatestApplicationCIs(1033) AS SourceCI
                    ON SourceCI.CI_ID = rel.FromApplicationCIID
                LEFT JOIN fn_ListLatestApplicationCIs(1033) AS DestCI
                    ON DestCI.CI_ID = rel.ToApplicationCIID
                WHERE 
                    rel.RelationType=15 AND
                    SourceCI.ModelName IS NOT NULL AND
                    DestCI.ModelName IS NOT NULL AND
                    SourceCI.IsSuperseded = 0
        "
    }catch{
        Write-Host("Server: Approval Migration Job: Unable to collect superseeding apps: $_")
    }
    $appSupersedes | ForEach-Object {
        Write-Host("Server: Approval Migration Job: '$($_.SuperseedingApp_ModelName_DisplayName)' with '$($_.SuperseedingApp_ModelName)' superseedes '$($_.SuperseededApp_DisplayName)' with '$($_.SuperseededApp_ModelName)'")
        $SuperseedingApps.$($_.SuperseededApp_ModelName) = $_.SuperseedingApp_ModelName
    }
    Write-Host("Server: Approval Migration Job: Found $($SuperseedingApps.Count) Superseeding Apps: $($superseedingApps.Values -join ", ")).")
    #Get all superseded apps with approvals and loop through them
    try{
        Write-Host("Server: Approval Migration Job: Collecting superseded approvals..")
        $supersededApprovals = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "
            SELECT 
                SMS_UserApplicationRequest.*
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
    }catch{
        Write-Host("Server: Approval Migration Job: Unable to collect superseded approvals: $_")
    }

    Write-Host("Server: Approval Migration Job: Found $($supersededApprovals.Count) Superseeded Approvals $($supersededApprovals.ModelName -join ", ").")
    $supersededApprovals | ForEach-Object {
        $request = $_
        try{
            #Save old Approval for usage in pipes
            $oldApproval = $_ | Get-CimInstance
            $computerName = $oldApproval.RequestedMachine
            $computer = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_R_SYSTEM where Name='$computerName' ORDER BY LastLogonTimestamp DESC" | Select-Object -First 1
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
            if($migratedApproval){
                $migratedApprovalHistory = Get-CMAppApprovalHistory -requestObject ($migratedApproval | Get-CimInstance)
            }

            $initialDenyText = "System: This request was migrated and this is the initial denial - please ignore this line."
            Write-Host("Server: Approval Migration Job: Checking Approval for $computerGuid for $doubleBackslashUsername with old App Name ModelName '$($oldApproval.ModelName)' and new App Name ModelName: '$newAppModelName' for App '$($oldApproval.Application)'.")
            if(!$oldApproval){
                Write-Host("Server: Approval Migration Job: Checking Approval for $computerGuid for $($doubleBackslashUsername) (Old ID: $($oldApproval.ModelName)): Old approval not found.")
                return;                
            }
            if(!$newAppModelName){
                Write-Host("Server: Approval Migration Job: Checking Approval for $computerGuid for $($doubleBackslashUsername) (Old ID: $($oldApproval.ModelName)): New App Modelname not found, skipping.")
                return;                
            }
            if(!$approvalHistory){
                Write-Host("Server: Approval Migration Job: Checking Approval for $computerGuid for $($doubleBackslashUsername) (Old ID: $($oldApproval.ModelName)): History not found, skipping.")
                return;                
            }
            if(!$doubleBackslashUsername){
                Write-Host("Server: Approval Migration Job: Checking Approval for $computerGuid for $($doubleBackslashUsername) (Old ID: $($oldApproval.ModelName)): Username not found, skipping.")
                return;                
            }
            if(!$oldApprovalUser){
                Write-Host("Server: Approval Migration Job: Checking Approval for $computerGuid for $($doubleBackslashUsername) (Old ID: $($oldApproval.ModelName)): Username of old approval not found, skipping.")
                return;                
            }
            if(!$computerGUID){
                Write-Host("Server: Approval Migration Job: Checking Approval for $computerGuid for $($doubleBackslashUsername) (Old ID: $($oldApproval.ModelName)): Computer GUID not found, skipping.")
                return;                
            }
            if($migratedApproval){
                Write-Host("Server: Approval Migration Job: Approval already exists, checking latest comment.")
                if($migratedApprovalHistory[-1].Comment -eq $initialDenyText){
                    Write-Host("Server: Approval Migration Job: Approval already exists, however it was not completely migrated.")
                }else{                    
                    Write-Host("Server: Approval Migration Job: Approval already exists, skipping..")
                    return;  
                }              
            }
            

            if(
                $approvalHistory -and
                $oldApproval -and
                $computerName -and
                $computer -and
                $computerGUID -and
                $doubleBackslashUsername -and
                $oldApprovalUser -and
                $newAppModelName
            ){
                Write-Host("Server: Approval Migration Job: Migrating Approval for $computerGuid for $doubleBackslashUsername with old App Name ModelName '$($oldApproval.ModelName)' and new App Name ModelName: '$newAppModelName'.")
                $step = 1
                Write-Host("Server: Approval Migration Job: Migrating Approval for $computerGuid for $($doubleBackslashUsername): Approval History Entries: $($approvalHistory.Count).")
                $existingApprovalQuery = "                            
                SELECT 
                    * 
                FROM 
                    SMS_UserApplicationRequest 
                WHERE
                    User = '$doubleBackslashUsername' AND
                    ModelName = '$newAppModelName' AND
                    RequestedMachine = '$($oldApproval.RequestedMachine)'
                "
                
                $approvalHistory | ForEach-Object {
                    Write-Host("Server: Approval Migration Job: Migrating Approval for $computerGuid for $($doubleBackslashUsername): Step '$step', current state '$($_.State)'.")
                    
                    #Request does not yet exist, create it but set auto install to false
                           
                    # Check if approval exists, if not create it
                    $existingApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query $existingApprovalQuery
                    if(!$existingApproval){
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
                        Write-Host("$($computerName): Creating Approval for $($oldApproval.Application) from $($_.Date) - Args: $($cimArgs.GetEnumerator() | Foreach-Object { "`n" + $_.Name + " - " + $_.Value }) ")
                        Invoke-CimMethod -Namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -ComputerName $(Get-scupPSValue -Name "SCCM_SiteServer") -ClassName "SMS_UserApplicationRequest" -MethodName "CreateApprovedRequest" -Arguments $cimArgs
                        Write-Host("$($computerName): Created Approval for $($oldApproval.Application) from $($_.Date) - sleeping 5 Seconds..")        
                        Start-Sleep -Seconds 5
                        $existingApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query $existingApprovalQuery

                        if($existingApproval -and $existingApproval.RequestGuid){
                            Write-Host("$($computerName): Retrieving Approval Object from WMI (Initial Denial)")       
                            $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$($(Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                            $existingApproval.Deny($initialDenyText) | Out-Null
                        }          
                    }

                    if(
                        $_.State -eq 1
                    ){
                        #Get approval and deny it for state migration
                        Write-Host("$($computerName): Initial deny $($oldApproval.Application) from $($_.Date)")                    
                        "[Step $step] $($oldApproval.Application): Creating initial denial (Old comment: $initialComment)<br/>"
                        $step++
                        $existingApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query $existingApprovalQuery
                        Write-Host("$($computerName): Retrieving Approval Object from WMI (State 1)")
                        Write-Host("Query: $existingApprovalQuery")
                        if($existingApproval.CurrentState -ne 3){
                            $existingApproval = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$($(Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`"" #Object for object oriented calls
                            $existingApproval.Deny("System: This Application has been updated. If your previous request was not yet approved, please re-request it. Existing approvals were migrated.") | Out-Null
                        }
                    }
                                
                    # Previous Request was approved, approve this one
                    $existingApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query $existingApprovalQuery
                    if($existingApproval){
                        $wmiEntry = "\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$($(Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`""
                        Write-Host("Retrieving WMI Entry for: $wmiEntry")
                        Write-Host("$($computerName): Retrieving Approval Object from WMI (State 4)")
                        $existingApproval = [wmi]$wmiEntry #Object for object oriented calls
                    }else{
                        Write-Host("Server: Approval Migration Job: No existing approval found for App '$newAppModelName' and Username '$doubleBackslashUsername' and Machine '$($oldApproval.RequestedMachine)'.")
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

                    # Previous Request was denied, deny this one
                    $existingApproval = Get-CimInstance -namespace $(Get-scupPSValue -Name "SCCM_SiteNamespace") -computer $(Get-scupPSValue -Name "SCCM_SiteServer") -query $existingApprovalQuery
                    if($existingApproval){
                        $wmiEntry = "\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$($(Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$($existingApproval.RequestGuid)`""
                        Write-Host("Retrieving WMI Entry for: $wmiEntry")
                        Write-Host("$($computerName): Retrieving Approval Object from WMI (State 3)")
                        $existingApproval = [wmi]$wmiEntry #Object for object oriented calls
                    }else{
                        Write-Host("Server: Approval Migration Job: No existing approval found for App '$newAppModelName' and Username '$doubleBackslashUsername' and Machine '$($oldApproval.RequestedMachine)'.")
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
            Write-scupPSLog("Request $($request.RequestGuid): Error during superseedence Migration: $_ at Line $($_.InvocationInfo.ScriptLineNumber)")
        }
    }

}
