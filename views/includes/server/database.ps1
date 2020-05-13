. "$(Get-PodeState -Name "PSScriptRoot")\views\includes\lib\logging.ps1"

function Invoke-scupPSSqlQuery($Query,$Parameters){    
    if(!$Parameters){
        $Parameters = @{}
    }
    return (
        Invoke-Sqlcmd2 -ServerInstance (Get-PodeState -Name "sqlInstance") -Database (Get-PodeState -Name "sqlDB") -SqlParameters $Parameters -ErrorAction Stop -Query $Query
    )
}

#Initiate DB if not already done
if(
    (
        (Invoke-scupPSSqlQuery -Query "
        IF 
            OBJECT_ID (N'db', N'U') IS NOT NULL 
            SELECT 
                1 AS res 
        ELSE 
            SELECT 
                0 AS res;").res -eq 0
    ) -or
    !(Invoke-scupPSSqlQuery -Query "SELECT * FROM db WHERE db_name = 'db_version'")
){
    Write-Host("Creating 'db' table..")
    #Create DB Version Table
    $query = "
    DROP TABLE IF EXISTS [dbo].[db]
    GO
    
    SET ANSI_NULLS ON
    GO
    
    SET QUOTED_IDENTIFIER ON
    GO
    
    CREATE TABLE [dbo].[db](
        [db_name] [nchar](10) NULL,
        [db_value] [nchar](10) NULL
    ) ON [DATA]
    GO
    INSERT [dbo].[db] ([db_name], [db_value]) VALUES (N'db_version', N'1')
    GO
    "  
    Invoke-scupPSSqlQuery -Query $query
}

#Check for required updates
$dbVersion = (Invoke-scupPSSqlQuery -Query "SELECT * FROM db WHERE db_name = 'db_version'").db_value

$continue = $true
Get-ChildItem -Path "$(Get-PodeState -Name "PSScriptRoot")\db\schema_updates" -Filter "*.sql" | Where-Object {
    $version = [int]$_.BaseName
    $version -gt $dbVersion
} | ForEach-Object {
    Write-Host("Applying Database Upgrade Version $($_.BaseName)")
    #Split at GO to support SSMS "GO" Statements
    ($_ | Get-Content -Raw).Split("GO") | ForEach-Object {
        try{
            if($continue -and $_){
                Invoke-scupPSSqlQuery -Query $_ -ErrorAction Stop
            }
        }catch{
            $continue = $false
            Write-Error -ErrorAction Stop -Message "Error on DB Upgrade: $_"
        }
    }
}