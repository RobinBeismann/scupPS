function Invoke-scupPSSqlQuery($Query,$Parameters){    
    if(!$Parameters){
        $Parameters = @{}
    }
    return (
        Invoke-Sqlcmd2 -ServerInstance (Get-PodeState -Name "sqlInstance") -Database (Get-PodeState -Name "sqlDB") -SqlParameters $Parameters -ErrorAction Stop -Query $Query
    )
}