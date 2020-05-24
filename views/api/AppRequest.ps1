if(
    ($operation -eq "AppRequest-approve") -or
    ($operation -eq "AppRequest-deny") -or
    ($operation -eq "AppRequest-revoke")
){
    #Request Information
    $requestID = $Data.Query.submitrequestid
    $denyreason = $Data.Query.submitdenyreason

    $currentDate = [string](Get-Date -Format "yyyy\/MM\/dd hh:MM")

    $localSender = $(Get-scupPSValue -Name "smtpSender").Replace("%SenderDisplayName%","$approverDisplayNameV1 (Approval Portal)")

    $reqObj = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_UserApplicationRequest where RequestGUID='$requestID'" | Get-CimInstance
    $reqObjRequestor = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "Select * From SMS_R_USER where Sid='$($reqObj.UserSid)'"
    $reqObjApprover = $Data.authenticatedUser
    $reqObjOO = [wmi]"\\$(Get-scupPSValue -Name "SCCM_SiteServer")\$((Get-scupPSValue -Name "SCCM_SiteNamespace")):SMS_UserApplicationRequest.RequestGuid=`"$requestId`"" #Object for object oriented calls
    
    #Check if requestor has the competence to approve requests for this costcenter
    if(!(Test-ApproveCompetence -User $reqObjRequestor -Manager $reqObjApprover)){
        "You're not allowed to approve this request!"
        #Remove the operation so we're not continuing
        $operation = $null
    }

    #Requestor Information
    $requestorFirstname = $reqObjRequestor.givenName
    $requestorLastname = $reqObjRequestor.sn
    $requestorMail = $reqObjRequestor.Mail
    $requestorDisplayNameV1 = "$requestorLastname, $requestorFirstname" 
    $requestorDisplayNameV2 = "$requestorFirstname $requestorLastname"

    #Approver Information
    $approverFirstname = $reqObjApprover.givenName
    $approverLastname = $reqObjApprover.sn
    $approverMail = $reqObjApprover.Mail
    $approverDisplayNameV1 = "$approverLastname, $approverFirstname" 
    $approverDisplayNameV2 = "$approverFirstname $approverLastname"

    $softwareTitle = $reqObj.Application
    $requestorMachine = $reqObj.RequestedMachine
    $mailTemplate = $null

    if($operation -eq "AppRequest-approve"){

        if($requestID -and $softwareTitle -and $requestorMachine){
            "Approved $softwareTitle for $requestorDisplayNameV1, starting installation on $requestorMachine"
            try{
                $result = $reqObjOO.Approve("Approved by $approverDisplayNameV1")
                Invoke-scupPSAppRequestCaching -RequestGuid $requestID
            }catch{
                $_
            }
            
            $mailTemplate = "approval.mailtemplate.html"    
            $mailSubject = "Application Approval granted"   
        }else{
            "An error occured while receiving request data."
        }
    }elseif($operation -eq "AppRequest-deny"){

        if($requestID -and $softwareTitle -and $requestorMail -and $requestorMachine){
            "Denied $softwareTitle for $requestorDisplayNameV1."

            try{
                $result = $reqObjOO.Deny("Denied by $approverDisplayNameV1 with the Reason `"$denyreason`"")
                Invoke-scupPSAppRequestCaching -RequestGuid $requestID
            }catch{
                $_
            }

            $mailTemplate = "denied.mailtemplate.html"
            $mailSubject = "Application Approval denied" 
        }else{
            "An error occured while receiving request data."
        }
    }elseif($operation -eq "AppRequest-revoke"){

        if($requestID -and $softwareTitle -and $requestorMachine){
            "Revoked $softwareTitle for $requestorDisplayNameV1, starting uninstallation on $requestorMachine"

            try{
                $result = $reqObjOO.Deny("Revoked by $approverDisplayNameV1 with the Reason `"$denyreason`"")
                Invoke-scupPSAppRequestCaching -RequestGuid $requestID
            }catch{
                $_
            }
            $mailTemplate = "revoke.mailtemplate.html"
            $mailSubject = "Application Approval revoked"   
        }else{
            "An error occured while receiving request data."
        }
    }

    if($mailSubject -and $mailTemplate -and $mailTemplate -ne ""){
        
        $userText = Get-Content -Path ".\public\Assets\templates\$mailTemplate" -Raw
        $userText = $userText.Replace("%requestorDisplayNameV1%",$requestorDisplayNameV1)
        $userText = $userText.Replace("%requestorDisplayNameV2%",$requestorDisplayNameV2)
        $userText = $userText.Replace("%requestorFirstname%",$requestorFirstname)
        $userText = $userText.Replace("%requestorLastname%",$requestorLastname)
        $userText = $userText.Replace("%requestorMail%",$requestorMail)
        $userText = $userText.Replace("%approverDisplayNameV1%",$approverDisplayNameV1)
        $userText = $userText.Replace("%approverDisplayNameV2%",$approverDisplayNameV2)
        $userText = $userText.Replace("%approverFirstname%",$approverFirstname)
        $userText = $userText.Replace("%approverLastname%",$approverLastname)
        $userText = $userText.Replace("%approverMail%",$approverMail)
        $userText = $userText.Replace("%softwareTitle%",$softwareTitle)
        $userText = $userText.Replace("%requestorMachine%",$requestorMachine)
        $userText = $userText.Replace("%denyreason%",$denyreason)
        $userText = $userText.Replace("%mailSignature%",$(Get-scupPSValue -Name "smtpSignature"))
        $userText = Get-HTMLString -Value $userText

        if($requestorMail){
            Send-CustomMailMessage -SmtpServer $(Get-scupPSValue -Name "smtpServer") -from $localSender -ReplyTo $(Get-scupPSValue -Name "smtpReplyTo") -subject $mailSubject -to ($requestorMail,$approverMail) -CC $(Get-scupPSValue -Name "smtpAdditionalRecipient") -body $userText -BodyAsHtml
        }
    }

}



if(
    ($operation -eq "AppRequest_Data") -or ($operation -eq "AppRequest_Headers")
){    
    if(
        !($start = $Data.Query.start) -or
        !($length = $Data.Query.length)
    ){
        $start = 0
        $length = 10
    }


    $attrCostCenter = Get-scupPSValue -Name "Attribute_costCenter"
    $attrManagedCostCenters = Get-scupPSValue -Name "Attribute_managedcostCenters"

    #App Query
    $qMain = (Get-PodeState -Name "sqlQueries").GetAppRequest
    #Count Query
    $qMainCount = (Get-PodeState -Name "sqlQueries").GetAppRequestCount
    #Build an array for additional filters we need to apply
    $additionalClauses = @()
    if(
        $Data.authenticatedUser
    ){ 
        $managedCostCenters = Get-scupPSManagedCostCenters($Data)
        #Filter for history if required
        $ShowApprovals = $Data.Query['ShowApprovals']        
        if($ShowApprovals -ne "history"){
            $additionalClauses += "requests.CurrentState = '1' and requests.CurrentState !='2'"
        }else{ 
            $additionalClauses += "requests.CurrentState != '1' and requests.CurrentState !='2'"
        }

        #Case 1: User is costcenter manager but not admin -> filter for his users' requests
        if(
            !($isAdmin = Test-scupPSRole -Name "helpdesk" -User $Data.authenticatedUser) -and
            $managedCostCenters
        ){
            $additionalClauses += 
            "
                users.$attrCostCenter IN (
                    $(
                        ($managedCostcenters | ForEach-Object {
                            "$_"
                        }) -Join ","
                    )
                )
            "
        #Case 2: User is not costcenter manager and not admin -> filter for his requests
        }elseif(            
            !($isAdmin = Test-scupPSRole -Name "helpdesk" -User $Data.authenticatedUser) -and
            !$managedCostCenters
        ){
            $additionalClauses += 
            "
                users.SID0 = '$($Data.authenticatedUser.SID)'
            "
        }
        #Case 3: User is admin -> add no further filter

        #If datatablesJS sends a search value, add it to the SQL Query
        if($search = $Data.Query.'search[value]'){
            $additionalClauses += "
                LOWER(apps.app_description) LIKE LOWER(@Search) OR
                LOWER(apps.app_manufacturer) LIKE LOWER(@Search) OR
                LOWER(users.full_user_name0) LIKE LOWER(@Search) OR
                LOWER(requests.comments) LIKE LOWER(@Search)
            "
        }

        #Add our query clauses to the existing statements
        $additionalClauses | Foreach-Object {
            $qMain        = Add-SqlWhereClause -Query $qMain -Clause $_
            $qMainCount   = Add-SqlWhereClause -Query $qMainCount -Clause $_
        }

        #Add a filter for the Range
        $qMain += "
            ORDER BY requests.Id
            OFFSET @StartRow ROWS
            FETCH NEXT @LengthRow ROWS ONLY
        "

        #Retrieve Table Headers only once and cache them in Pode afterwards
        if(
            ($operation -eq "AppRequest_Headers") -and
            ($headerCache = Get-PodeState -Name "CacheApprvlTableHeader")
        ){
            #Strip it down to one row, thats enough
            $res = $headerCache | Select-Object -First 1
        }else{
            #This is either not a table preview or our cache is empty, process as usual and return results
            $res = Invoke-scupCCMSqlQuery -Query $qMain -Parameters @{
                StartRow = [int]$start
                LengthRow = [int]$length
                Search = "%$search%"
            }
            $TotalCount = (Invoke-scupCCMSqlQuery -Query $qMainCount -Parameters @{
                StartRow = [int]$start
                LengthRow = [int]$length
                Search = "%$search%"
            })[0]

            #Write our result to the Pode Cache so we can reuse it
            if($operation -eq "AppRequest_Headers"){
                Set-PodeState -Name "CacheApprvlTableHeader" -Value ($res | Select-Object -First 1) | Out-Null
            }
        }

        #Finally build our JSON Array
        Get-DataTablesResponse -Operation $operation -Start $Start -Length $length -RecordsTotal $TotalCount -Draw $Data.Query.'draw' -AdditionalValues @{ calledIsAdmin = $isAdmin } -Data (
            $res | ForEach-Object {
                    [ordered]@{
                        "User" = "<a href='mailto:$($_.user_mail)'>$(Get-HTMLString($_.user_displayname))</a>"
                        "Costcenter" = $_.user_costcenter
                        "Application" = "$(if($url = Get-IconUrl -CI_ID $_.app_CI_ID -Hash $_.app_icon_hash){ "<img src='$url' style='height: 1.5em;' />   "} )$(Get-HTMLString($_.app_title))"
                        "Machine" = $_.request_machinename
                        "Price" = Get-HTMLString($_.app_description)
                        "Comment" = Get-HTMLString($_.request_comments)
                        "Actions" = $(                                                             
                                if($ShowApprovals -ne "history"){
                                    #Pending Buttons                                    
                                    "<button id='btn_approve_$($_.request_guid)' name='btn_approve' class='btn btn-primary' onclick='handleApprovalRequest(`"AppRequest_approve`",`"$($_.request_guid)`"`)'>Approve</button>"
                                    "<button id='btn_deny_$($_.request_guid)' name='btn_deny' class='btn btn-primary' onclick='handleApprovalRequest(`"AppRequest_deny`",`"$($_.request_guid)`")'>Deny</button>"
                                }else{
                                    #History Buttons                                    
                                    "<button id='btn_approve_$($_.request_guid)' name='btn_approve' class='btn btn-primary' onclick='handleApprovalRequest(`"AppRequest_approve`",`"$($_.request_guid)`"`)'>Approve</button>"
                                    
                                    #Check if this request is already approved
                                    if($_.request_state -eq 4){
                                        #Switch to revoke
                                        $btnAction = "AppRequest-revoke"
                                        $btnDescription = "Revoke"
                                        #Disable approve button
                                        "<script type='text/javascript'>document.getElementById('btn_approve_$($_.request_guid)').disabled = true;</script>"
                                    }else{
                                        $btnAction = "AppRequest-deny"
                                        $btnDescription = "Deny"
                                    }
                                    
                                    "<button id='btn_deny_$($_.request_guid)' name='btn_deny' class='btn btn-primary' onclick='handleApprovalRequest(`"$btnAction`",`"$($_.request_guid)`")'>$btnDescription</button>"
                                    
                                    #Set Deny button to disabled if request is not approved
                                    if($_.request_state -ne 4){
                                        "<script type='text/javascript'>document.getElementById('btn_deny_$($_.request_guid)').disabled = true;</script>"
                                    }
                                     
                                }
                            )                         
                    }
            }
        )
       
    }
}