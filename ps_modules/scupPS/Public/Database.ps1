function Invoke-scupPSSqlQuery($Query,$Parameters){    
    if(!$Parameters){
        $Parameters = @{}
    }
    return (
        Invoke-Sqlcmd2 -ServerInstance (Get-PodeState -Name "sqlInstance") -Database (Get-PodeState -Name "sqlDB") -SqlParameters $Parameters -ErrorAction Stop -Query $Query
    )
}

function Invoke-scupCCMSqlQuery($Query,$Parameters){    
    if(!$Parameters){
        $Parameters = @{}
    }
    return (
        Invoke-Sqlcmd2 -ServerInstance (Get-scupPSValue -Name "SCCM_SiteDatabaseInstance") -Database (Get-scupPSValue -Name "SCCM_SiteDatabaseName") -SqlParameters $Parameters -ErrorAction Stop -Query $Query
    )
}