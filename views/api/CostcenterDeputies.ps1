if(
    ($operation -eq "CostcenterDeputies_Data") -or ($operation -eq "CostcenterDeputies_Headers")
){    
    if(
        !($start = $WebEvent.Query.start) -or
        !($length = $WebEvent.Query.length)
    ){
        $start = 0
        $length = 10
    }


    $attrCostCenter = Get-scupPSValue -Name "Attribute_costCenter"
    $attrManagedCostCenters = Get-scupPSValue -Name "Attribute_managedcostCenters"

    #App Query
    $qMain = (Get-PodeState -Name "sqlQueries").GetManagedCostcenters
    #Count Query
    $qMainCount = (Get-PodeState -Name "sqlQueries").GetManagedCostcentersCount

    #Build an array for additional filters we need to apply
    $additionalClauses = @()
    if(
        $WebEvent.authenticatedUser
    ){ 
        $managedCostCenters = Get-scupPSManagedCostCenters
        
        #Case 1: User is costcenter manager but not admin -> filter for his users' requests
        if(
            !($isAdmin = Test-scupPSRole -Name "helpdesk" -User $WebEvent.authenticatedUser) -and
            $managedCostCenters
        ){
            $additionalClauses += 
            "
                users.$attrManagedCostCenters IN (
                    $(
                        ($managedCostcenters | ForEach-Object {
                            "'$_'"
                        }) -Join ","
                    )
                )
            "
        #Case 2: User is not costcenter manager and not admin -> filter for his requests
        }elseif(            
            !($isAdmin = Test-scupPSRole -Name "helpdesk" -User $WebEvent.authenticatedUser) -and
            !$managedCostCenters
        ){
        #Case 3: User has nothing to view
            return;
        }
        #Case 3: User is admin -> add no further filter

        $additionalClauses += "value != '#'"
        $additionalClauses += "value != 'admin'"
        $additionalClauses += "value != 'cleared'"

        #If datatablesJS sends a search value, add it to the SQL Query
        if($search = $WebEvent.Query.'search[value]'){
            $additionalClauses += "
                LOWER([users].Full_User_Name0) LIKE LOWER(@Search) OR
                LOWER(value) LIKE LOWER(@Search)
            "
        }
        #Add our query clauses to the existing statements
        $additionalClauses | Foreach-Object {
            $qMain        = Add-SqlWhereClause -Query $qMain -Clause $_
            $qMainCount   = Add-SqlWhereClause -Query $qMainCount -Clause $_
        }
        
        #Add a filter for the Range
        $qMain += "
            ORDER BY value
            OFFSET @StartRow ROWS
            FETCH NEXT @LengthRow ROWS ONLY
        "

        #Retrieve Table Headers only once and cache them in Pode afterwards
        if(
            ($operation -eq "CostcenterDeputies_Headers") -and
            ($headerCache = Get-PodeState -Name "CacheDeputyTableHeader")
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
            if($operation -eq "CostcenterDeputies_Headers"){
                Set-PodeState -Name "CacheDeputyTableHeader" -Value ($res | Select-Object -First 1) | Out-Null
            }
        }

        #Finally build our JSON Array
        Get-DataTablesResponse -Operation $operation -Start $Start -Length $length -RecordsTotal $TotalCount -Draw $WebEvent.Query.'draw' -AdditionalValues @{ calledIsAdmin = $isAdmin } -Data (
            $res | ForEach-Object {
                    [ordered]@{
                        "Costcenter" = $_.user_managedCostcenter
                        "Manager" = "<a href='mailto:$($_.user_mail)'>$(Get-HTMLString($_.user_displayname))</a>"
                    }
            }
        )
       
    }
}