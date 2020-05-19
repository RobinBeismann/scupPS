if(
    ($operation -eq "generateApprvlTable") -or ($operation -eq "generateApprvlTableHeader")
){    
    if(
        !($start = $Data.Query.start) -or
        !($length = $Data.Query.length)
    ){
        $start = 0
        $length = 10
    }

    function Build-Response($Operation,$Data,$Start,$Length,$RecordsTotal,$Draw){
        $tbl = [ordered]@{
            draw = $Draw
            recordsTotal = $RecordsTotal
            recordsFiltered = $RecordsTotal
        }

        $tbl.data = $Data
        return $tbl | ConvertTo-Json
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
                apps.app_description LIKE @Search OR
                apps.app_manufacturer LIKE @Search OR
                users.full_user_name0 LIKE @Search OR
                requests.comments LIKE @Search
            "
            $Data.Query.'draw' = 1
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
        #Get approval requests
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
        
        #Build request table
        if(!$ShowApprovals -or $ShowApprovals -ne "history"){
            
            Build-Response -Operation $operation -Start $Start -Length $length -RecordsTotal $TotalCount -Draw $Data.Query.'draw' -Data (
                $managedRequests | ForEach-Object {
                        [ordered]@{
                            "User" = "<a href='mailto:$($_.user_mail)'>$($_.user_displayname)</a>"
                            "Costcenter" = $($_.user_costcenter)
                            "Application" = $_.app_title
                            "Machine" = $_.request_machinename
                            "Price" = $_.app_description
                            "Comment" = $_.request_comments
                        }
                }
            )
        }else{
            Build-Response -Operation $operation -Start $Start -Length $length -RecordsTotal $TotalCount -Draw $Data.Query.'draw' -Data (
                $managedRequests | ForEach-Object {
                    [ordered]@{
                            "User" = "<a href='mailto:$($_.user_mail)'>$($_.user_displayname)</a>"
                            "Costcenter" = $($_.user_costcenter)
                            "Application" = $_.app_title
                            "Machine" = $_.request_machinename
                            "Price" = $_.app_description
                            "Comment" = $_.request_comments
                        }
                }
            )
        }
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