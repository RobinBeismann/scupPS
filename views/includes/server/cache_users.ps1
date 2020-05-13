# Cache Applications
Write-Host("Adding Scheduled Job to cache costcenters..")
Add-PodeSchedule -Name 'CacheUsers' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 10
    
    if(Test-scupPSJobMaster){
        $attrManagedCostcenters = Get-scupPSValue -Name "Attribute_managedcostCenters"
        $attrCostcenter = Get-scupPSValue -Name "Attribute_Costcenter"
        $columnQuery = "
        SELECT 
            name 
        FROM
            syscolumns 
        WHERE 
            id=OBJECT_ID('users') 
        "
        $userQuery = "
        SELECT 
            AgentTime 
        FROM 
            users 
        WHERE 
            ResourceID = @ResourceID AND
            AgentTime = @CompareTimestamp    
        "

        $currColumns = Invoke-scupPSSqlQuery -Query $columnQuery
        $startTime = Get-Date
        Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
            SELECT
                DistinguishedName,
                UserGroupName,
                UniqueUserName,
                UserName,
                WindowsNTDomain,
                SID,
                sn,
                givenName,
                Mail,
                FullDomainName,
                FullUserName,
                ResourceId,
                $attrManagedCostcenters,
                $attrCostcenter,
                AgentTime,
                userPrincipalName
            FROM 
                SMS_R_User
            WHERE
                SID IS NOT NULL
        " | ForEach-Object {
            $user = $_
            $columns = @()
            #Collect columns
            $_.PSObject.Properties | Where-Object { 
                !($_.TypeNameOfValue.StartsWith("Microsoft.Management.Infrastructure.")) -and 
                $_.Name -ne "PSShowComputerName" -and 
                $_.Name -ne "PSComputerName" -and 
                $_.Value } 
            | ForEach-Object {
                $columns += $_.Name
            }

            #Create columns
            $columns | ForEach-Object {
                #Create Columns if not exists
                if($_ -notin $currColumns.name){
                    $destinationType = $null
                    switch($_.TypeNameOfValue){
                        "uint" {
                            $destinationType = "[nchar](100)"
                        }
                        default {
                            $destinationType = "[nvarchar](max)"
                        }
                    }
                    Write-Host("Column $($_) is missing in 'users' Table - WMI Schema is $($_.TypeNameOfValue), SQL Type will be $destinationType" )
                    $query = "
                        ALTER TABLE [dbo].[users]
                        ADD $_ $destinationType NULL;
                    "
                    Invoke-scupPSSqlQuery -Query $query
                    $currColumns = Invoke-scupPSSqlQuery -Query $columnQuery
                }
            }
            
            #Insert users
            #Build Queries
            $CCMTimestamp = $_.AgentTime -join ";"
            $DBTimestamp = Invoke-scupPSSqlQuery -Query $userQuery -Parameters @{
                ResourceID = [string]$user.ResourceID
                CompareTimestamp = [string]$CCMTimestamp
            }
            
            if(
                !$DBTimestamp
            ){
                Write-Host("Updating $($_.userPrincipalName)..")
                $primaryKey = "ResourceId"
                $relColumns = $columns | Where-Object { $_ -ne $primaryKey }  

                $fieldColl = ($relColumns | ForEach-Object {
                    " $_ = @$_"
                }) -join ","
                $updateColl = ($relColumns | ForEach-Object {
                    " $_ = s.$_"
                }) -join ","
                $insertColl = $relColumns -join ","
                $insertValColl = ($relColumns | ForEach-Object {
                    " s.$_"
                }) -join ","

                $transName = "update_" + $_.Resourceid
                $query = "
                BEGIN TRAN $transName; 
                    MERGE INTO users AS t
                    USING 
                        (SELECT $primaryKey=@$primaryKey,$fieldColl) AS s
                    ON t.$primaryKey = s.$primaryKey
                    WHEN MATCHED THEN
                        UPDATE SET $primaryKey=s.$primaryKey,$updateColl
                    WHEN NOT MATCHED THEN
                        INSERT ($primaryKey,$insertColl)
                        VALUES (s.$primaryKey,$insertValColl);
                COMMIT TRAN $transName;
                "

                $parameters = @{}
                $columns | ForEach-Object {
                    $val = $user.$_
                    if($val -is [array]){
                        $val = $val -join ";"
                    }
                    $parameters.$_ = [string]$val
                }
                Invoke-scupPSSqlQuery -Parameters $parameters -Query $query
            }    
        }
        $EndTime = Get-Date
        Write-Host("Cached $( (Invoke-scupPSSqlQuery -Query "SELECT COUNT(SID) FROM users;").'Column1') Users - Time elapsed: $( ($endTime - $startTime).Seconds) Seconds..")

    }
}
