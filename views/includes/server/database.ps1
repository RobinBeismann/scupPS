. "$(Get-PodeState -Name "PSScriptRoot")\views\includes\lib\logging.ps1"

function Execute-SQLiteQuery($Query) {
    Write-scupPSLog($query)
    Add-Type -Path "$(Get-PodeState -Name "PSScriptRoot")\libs\System.Data.SQLite.dll"
    $db_data_source = "$(Get-PodeState -Name "PSScriptRoot")\db\db.sqlite"
    $db_data_source = $db_data_source.Replace("\","\\")
    
    $CONN = New-Object -TypeName System.Data.SQLite.SQLiteConnection
  
    $CONN.ConnectionString = "Data Source=$db_data_source"
    $CONN.Open()

    $CMD = $CONN.CreateCommand()
    $CMD.CommandText = $Query

    if (!($Query.Trim().ToLower().StartsWith("select"))) {
        [void]$CMD.ExecuteNonQuery()
        $CMD.Dispose()
        $CONN.Close()

        return $true
    }else{
        $ADAPTER = New-Object  -TypeName System.Data.SQLite.SQLiteDataAdapter $CMD
        $DATA = New-Object System.Data.DataSet

        [void]$ADAPTER.Fill($DATA)

        
        if(
            $DATA.Tables -and 
            $Data.Tables[0] -and 
            $Data.Tables[0].Rows.Count -gt 0
        ){
            $TABLE = $Data.Tables.Rows
        }else{
            $TABLE = $false
        }
        $CMD.Dispose()
        $CONN.Close()

        return $TABLE
    }

    return $false
}

#Check if DB exists, else create
if(!(Test-Path -Path "$(Get-PodeState -Name "PSScriptRoot")\db\db.sqlite")){
    Copy-Item -Path "$(Get-PodeState -Name "PSScriptRoot")\db\db.sqlite.default" -Destination "$(Get-PodeState -Name "PSScriptRoot")\db\db.sqlite"
}

#Check for required updates
$dbVersion = (Execute-SQLiteQuery -Query "SELECT db_version FROM db").db_version
Get-ChildItem -Path "$(Get-PodeState -Name "PSScriptRoot")\db\schema_updates" -Filter "*.sql" | Where-Object {
    $version = [int]$_.BaseName
    $version -gt $dbVersion
} | ForEach-Object {
    Write-Host("Applying Database Upgrade Version $($_.BaseName)")
    Execute-SQLiteQuery -Query ($_ | Get-Content -Raw)
}

function Check-IsNullWithSQLDBNullSupport ($Value) {
    if ($Value -eq [System.DBNull]::Value -or $Value -eq $null) {
        return $true
    } else {
        return $false
    }
}