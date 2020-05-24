if(
    ($operation -eq "AppRequestTable-Data") -or ($operation -eq "AppRequestTable-Headers")
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
    $AppReqQuery = (Get-PodeState -Name "sqlQueries").GetAppRequest
    #Count Query
    $AppReqCountQuery = (Get-PodeState -Name "sqlQueries").GetAppRequestCount
    #Build an array for additional filters we need to apply
    $additionalClauses = @()
    if(
        $Data.authenticatedUser -and
        (Get-scupPSManagedCostCenters($Data))
    ){ 
        #Filter for history if required
        $ShowApprovals = $Data.Query['ShowApprovals']        
        if($ShowApprovals -ne "history"){
            $additionalClauses += "requests.CurrentState = '1' and requests.CurrentState !='2'"
        }else{ 
            $additionalClauses += "requests.CurrentState != '1' and requests.CurrentState !='2'"
        }

        #If not Admin, add a filter for the managed costcenters
        if(!($isAdmin = Test-scupPSRole -Name "helpdesk" -User $Data.authenticatedUser)){
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
        }

        if($search = $Data.Query.'search[value]'){
            $additionalClauses += "
                LOWER(apps.app_description) LIKE LOWER(@Search) OR
                LOWER(apps.app_manufacturer) LIKE LOWER(@Search) OR
                LOWER(users.full_user_name0) LIKE LOWER(@Search) OR
                LOWER(requests.comments) LIKE LOWER(@Search)
            "
        }

        $additionalClauses | Foreach-Object {
            $AppReqQuery        = Add-SqlWhereClause -Query $AppReqQuery -Clause $_
            $AppReqCountQuery   = Add-SqlWhereClause -Query $AppReqCountQuery -Clause $_
        }

        #Add a filter for the Range
        $AppReqQuery += "
            ORDER BY requests.Id
            OFFSET @StartRow ROWS
            FETCH NEXT @LengthRow ROWS ONLY
        "

        #Retrieve Table Headers only once and cache them in Pode afterwards
        if(
            ($operation -eq "AppRequestTable-Headers") -and
            ($headerCache = Get-PodeState -Name "CacheApprvlTableHeader")
        ){
            #Strip it down to one row, thats enough
            $managedRequests = $headerCache | Select-Object -First 1
        }else{
            #This is either not a table preview or our cache is empty, process as usual and return results
            $managedRequests = Invoke-scupCCMSqlQuery -Query $AppReqQuery -Parameters @{
                StartRow = [int]$start
                LengthRow = [int]$length
                Search = "%$search%"
            }
            $TotalCount = (Invoke-scupCCMSqlQuery -Query $AppReqCountQuery -Parameters @{
                StartRow = [int]$start
                LengthRow = [int]$length
                Search = "%$search%"
            })[0]

            #Write our result to the Pode Cache so we can reuse it
            if($operation -eq "AppRequestTable-Headers"){
                Set-PodeState -Name "CacheApprvlTableHeader" -Value ($managedRequests | Select-Object -First 1) | Out-Null
            }
        }
        Get-DataTablesResponse -Operation $operation -Start $Start -Length $length -RecordsTotal $TotalCount -Draw $Data.Query.'draw' -Data (
            $managedRequests | ForEach-Object {
                    [ordered]@{
                        "User" = "<a href='mailto:$($_.user_mail)'>$(Get-HTMLString($_.user_displayname))</a>"
                        "Costcenter" = $_.user_costcenter
                        "Application" = Get-HTMLString($_.app_title)
                        "Machine" = $_.request_machinename
                        "Price" = Get-HTMLString($_.app_description)
                        "Comment" = Get-HTMLString($_.request_comments)
                        "Actions" = $(                                                             
                                if($ShowApprovals -ne "history"){
                                    #Pending Buttons
                                    
                                    "<button id='btn_approve_$($_.request_guid)' name='btn_approve' class='btn btn-primary' onclick='handleRequest(`"approverequest`",`"$($_.request_guid)`"`)'>Approve</button>"
                                    "<button id='btn_deny_$($_.request_guid)' name='btn_deny' class='btn btn-primary' onclick='handleRequest(`"denyrequest`",`"$($_.request_guid)`")'>Deny</button> "           
                                    
                                }else{
                                    #History Buttons                                    
                                    "<button id='btn_approve_$($_.request_guid)' name='btn_approve' class='btn btn-primary' onclick='handleRequest(`"approverequest`",`"$($_.request_guid)`"`)'>Approve</button>"
                                    
                                    #Check if this request is already approved
                                    if($_.request_state -eq 4){
                                        #Switch to revoke
                                        $btnAction = "revokerequest"
                                        $btnDescription = "Revoke"
                                        #Disable approve button
                                        "<script type='text/javascript'>document.getElementById('btn_approve_$($_.request_guid)').disabled = true;</script>"
                                    }else{
                                        $btnAction = "denyrequest"
                                        $btnDescription = "Deny"
                                    }
                                    
                                    "<button id='btn_deny_$($_.request_guid)' name='btn_deny' class='btn btn-primary' onclick='handleRequest(`"$btnAction`",`"$($_.request_guid)`")'>$btnDescription</button>"
                                    
                                    #Set Deny button to disabled if request is not approved
                                    if($_.request_state -ne 4){
                                        "<script type='text/javascript'>document.getElementById('btn_deny_$($_.request_guid)').disabled = true;</script>"
                                    }
                                     
                                }
                            )                         
                    }
            }
        )
       
    }else{
        #Get approval requests
        $AppReqQuery = $AppReqQuery + "AND users.SID0 = '$($Data.authenticatedUser.SID)'"
        $openRequests = Invoke-scupCCMSqlQuery -Query $AppReqQuery
        #Build request table
        '
        <table class="table table-responsive">
            <tr>
            <th>Software</th>
            <th>Current Machine</th>
            <th>Price/Alternatives</th>
            <th>Comment</th>
            </tr>
        '

        $openRequests | ForEach-Object {
            "<tr>
                <td scope='col'>$($_.app_title)</td>
                <td scope='col'>$($_.request_machinename)</td>
                <td scope='col'>$(Get-HTMLString($_.app_description))</td>
                <td scope='col'>$(Get-HTMLString($_.request_comments))</td>
            </tr>
            "
        }        
    }
    
}