# Cache Applications
Write-Host("Adding Scheduled Job to cache costcenters..")
Add-PodeSchedule -Name 'CacheCostcenters' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 10
    
    if(Test-scupPSJobMaster){
        $costcenters = @{}
        $attrManagedCostcenters = Get-scupPSValue -Name "Attribute_managedcostCenters"
        $attrCostcenter = Get-scupPSValue -Name "Attribute_Costcenter"
        
        $costcenterInsert = "
            MERGE INTO 
                [dbo].[costcenters] 
                AS t
            USING 
                (
                    SELECT 
                        [costcenter_id] = @costcenter_id
                ) 
                AS s
            ON 
                t.costcenter_id = s.costcenter_id
            WHEN NOT MATCHED THEN 
                INSERT 
                (
                    [costcenter_id]
                )
                VALUES
                (
                    s.[costcenter_id]
                );
        "
        $relationInsert =  "
            MERGE INTO 
                [dbo].[costcenterManagers] 
                AS t
            USING 
                (
                    SELECT 
                        [relation_costcenter_mSID] = @relation_costcenter_mSID,
                        [relation_costcenter_id] = @relation_costcenter_id
                ) 
                AS s
            ON 
                t.relation_costcenter_mSID = s.relation_costcenter_mSID AND
                t.relation_costcenter_id = s.relation_costcenter_id
            WHEN NOT MATCHED THEN 
                INSERT 
                (
                    [relation_costcenter_mSID],
                    [relation_costcenter_id]
                )
                VALUES
                (
                    s.[relation_costcenter_mSID],
                    s.[relation_costcenter_id]
                );  
        " 
        
        Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
            SELECT 
                $attrManagedCostcenters,
                $attrCostcenter,
                SID
            FROM 
                SMS_R_User
            WHERE
                $attrCostcenter IS NOT NULL
            " | ForEach-Object {    
            $user = $_
            Invoke-scupPSSqlQuery -Parameters @{
                    "costcenter_id" = $user.$attrCostcenter
                } -Query $costcenterInsert
            
    
            if(
                ($managedCostCenters = $_.$attrManagedCostcenters) -and
                ($managedCostCenters = $managedCostCenters.Split(";"))
            ){
                $managedCostCenters | ForEach-Object {
                    if(!$costcenters.$_){
                        $costcenters.$_ = @()
                    }
                    $costcenters.$_ += $user.SID
                }
            }
        }
        $costcenters.GetEnumerator() | ForEach-Object {
            $costcenter = $_.Name
                    
            #Loop through SID and insert
            $_.Value | Foreach-Object {
                Invoke-scupPSSqlQuery -Query $relationInsert -Parameters @{
                    "relation_costcenter_mSID" = $_
                    "relation_costcenter_id" = $costcenter 
                }
            }
        }
        
        Write-Host("Cached $((Invoke-scupPSSqlQuery -Query "SELECT COUNT(costcenter_id) FROM costcenters;").'Column1') Costcenters..")
        Write-Host("Cached $((Invoke-scupPSSqlQuery -Query "SELECT COUNT(relation_costcenter_mSID) FROM costcenterManagers;").'Column1') Costcenter Manager Relations..")
    }
}
