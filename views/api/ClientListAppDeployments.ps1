if(
    ($operation -eq "ClientListAppDeployments_Data") -or ($operation -eq "ClientListAppDeployments_Headers") -and ($isAdmin = Test-scupPSRole -Name "helpdesk" -User $WebEvent.authenticatedUser)
){    
    if(
        !($start = $WebEvent.Query.start) -or
        !($length = $WebEvent.Query.length)
    ){
        $start = 0
        $length = 10
    }

    #App Query
    $qMain = (Get-PodeState -Name "sqlQueries").GetClientListAppDeployments
    #Count Query
    $qMainCount = (Get-PodeState -Name "sqlQueries").GetClientListAppDeploymentsCount

    #Build an array for additional filters we need to apply
    $additionalClauses = @()
    if(
        $WebEvent.authenticatedUser
    ){ 
        #If datatablesJS sends a search value, add it to the SQL Query
        if($search = $WebEvent.Query.'search[value]'){
            $additionalClauses += "
                LOWER(Descript) LIKE LOWER(@Search)
            "
        }
        #Add our query clauses to the existing statements
        $additionalClauses | Foreach-Object {
            $qMain        = Add-SqlWhereClause -Query $qMain -Clause $_
            $qMainCount   = Add-SqlWhereClause -Query $qMainCount -Clause $_
        }
        
        #Add a filter for the Range
        $qMain += "
            ORDER BY [CI_ID]
            OFFSET @StartRow ROWS
            FETCH NEXT @LengthRow ROWS ONLY
        "
        #Retrieve Table Headers only once and cache them in Pode afterwards
        if(
            ($operation -eq "ClientListAppDeployments_Headers") -and
            ($headerCache = Get-PodeState -Name "CacheClientListAppDeployments_Headers")
        ){
            #Strip it down to one row, thats enough
            $res = $headerCache | Select-Object -First 1
        }else{
            #This is either not a table preview or our cache is empty, process as usual and return results
            $res = Invoke-scupCCMSqlQuery -Query $qMain -Parameters @{
                StartRow = [int]$start
                LengthRow = [int]$length
                Search = "%$search%"
                ClientName = $WebEvent.Query.ClientName
            }
            $TotalCount = (Invoke-scupCCMSqlQuery -Query $qMainCount -Parameters @{
                StartRow = [int]$start
                LengthRow = [int]$length
                Search = "%$search%"
                ClientName = $WebEvent.Query.ClientName
            })[0]
            
            #Write our result to the Pode Cache so we can reuse it
            if($operation -eq "ClientListAppDeployments_Headers"){
                Set-PodeState -Name "CacheClientListAppDeployments_Headers" -Value ($res | Select-Object -First 1) | Out-Null
            }
        }

        #Finally build our JSON Array
        Get-DataTablesResponse -Operation $operation -Start $Start -Length $length -RecordsTotal $TotalCount -Draw $WebEvent.Query.'draw' -AdditionalValues @{ calledIsAdmin = $isAdmin; ClientName = $WebEvent.Query.ClientName } -Data (
            $res | ForEach-Object {
                [ordered]@{
                    CI_ID = $_.CI_ID
                    TargetCollectionID = $_.TargetCollectionID
                    TargetCollectionName = $_.TargetCollectionName
                    Descript = $_.Descript
                    Status = $_.status
                    StartTime = $_.StartTime
                    LastModificationTime = $_.LastModificationTime
                }
            }
        )
       
    }
}