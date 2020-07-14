function Invoke-scupPSSqlQuery($Query,$Parameters,[Switch]$ParseGo){    
    if(!$Parameters){
        $Parameters = @{}
    }
    $additionalParam = @{}
    if($ParseGo){
        $additionalParam['ParseGo'] = $true
    }

    try{
        $res = Invoke-Sqlcmd2 -ServerInstance (Get-PodeState -Name "sqlInstance") -Database (Get-PodeState -Name "sqlDB") -SqlParameters $Parameters -ErrorAction Stop -Query $Query @additionalParam
        return $res
    }catch{
        Write-scupPSLog -Message `
        "Error in SQL Query:
        Query: 
            $Query
        Parameters:
            $(
                if($Parameters){
                    $Parameters.GetEnumerator() | ForEach-Object { "$($_.Name): $($_.Value)" }
                }
            )
        Error:
            $_
        "
        Throw($_)
    }
}

function Invoke-scupCCMSqlQuery($Query,$Parameters){    
    if(!$Parameters){
        $Parameters = @{}
    }
    try{
        $res = Invoke-Sqlcmd2 -ServerInstance (Get-scupPSValue -Name "SCCM_SiteDatabaseInstance") -Database (Get-scupPSValue -Name "SCCM_SiteDatabaseName") -SqlParameters $Parameters -ErrorAction Stop -Query $Query
        return $res
    }catch{
        Write-scupPSLog -Message `
        "Error in SQL Query:
        Query: 
            $Query
        Parameters:
            $(
                if($Parameters){
                    $Parameters.GetEnumerator() | ForEach-Object { "$($_.Name): $($_.Value)" }
                }
            )
        Error:
            $_
        "
        Throw($_)
    }
}

function Add-SqlWhereClause($Query,$Clause){
    $query = $query.ToLower()
    $splitOn = "select", "where", "from", "order by", "group by"
    
    if(
        $query.Contains("where")
    ){
        $whereClausePos = $query.LastIndexOf("where")
        
        $remainingString = $query.Substring($whereClausePos)
        $keywordEnd = $remainingString.IndexOf(" ")
        $remainingStringWithoutKeyWord = $remainingString.Substring($KeyWordEnd)

        $splitOn | Foreach-object {
            if(
                ($nextKeyWord = $remainingStringWithoutKeyWord.IndexOf($_)) -and
                ($nextKeyWord -ne -1)
            ){
                $remainingStringWithoutKeyWord = $remainingStringWithoutKeyWord.Substring(0,$nextKeyWord)
            }
        }

        $clauseEndPos = $remainingStringWithoutKeyWord.Length + $query.LastIndexOf($remainingStringWithoutKeyWord)

        return $query.Insert($clauseEndPos," AND $clause ")
    }else{
        return "$query WHERE $clause"
    }
    
}