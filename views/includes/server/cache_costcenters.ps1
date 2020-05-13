# Cache Applications
Write-Host("Adding Scheduled Job to cache costcenters..")
Add-PodeSchedule -Name 'CacheCostcenters' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 10
    
    #Include Config
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\core\config.ps1"

    if(Test-scupPSJobMaster){
        $costcenters = @{}
        $attrManagedCostcenters = Get-scupPSValue -Name "Attribute_managedcostCenters"
        $attrCostcenter = Get-scupPSValue -Name "Attribute_Costcenter"

        Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
            SELECT 
                $attrManagedCostcenters,
                $attrCostcenter,
                SID
            FROM 
                SMS_R_User
        " | ForEach-Object {    
            $user = $_
            if(
                ($managedCostcenters = $_.$attrManagedCostcenters) -and
                ($managedCostcenters = $managedCostcenters.Split(";"))
            ){
                $managedCostcenters | ForEach-Object {
                    if(!$costcenters.$_){
                        $costcenters.$_ = @()
                    }
                    $costcenters.$_ += $user.SID
                }
            }
        }

            $costcenters.GetEnumerator() | ForEach-Object {
                $query =  "
                            MERGE INTO 
                                [dbo].[costcenters] 
                                AS t
                            USING 
                                (
                                    SELECT 
                                        costcenter_id = @costcenter_id,
                                        costcenter_managers = @costcenter_managers
                                ) 
                                AS s
                            ON 
                                t.costcenter_id = s.costcenter_id
                            WHEN MATCHED THEN
                                UPDATE SET 
                                    costcenter_id=s.costcenter_id,
                                    costcenter_managers = s.costcenter_managers
                            WHEN NOT MATCHED THEN 
                                INSERT 
                                (
                                    costcenter_id,
                                    costcenter_managers
                                )
                                VALUES
                                (
                                    s.costcenter_id,
                                    s.costcenter_managers
                                );      
                    " 
                Invoke-scupPSSqlQuery -Query $query -Parameters @{
                    "costcenter_id" = $_.Name
                    "costcenter_managers" = ($_.Value -join ";")
            }
        }
        Write-Host("Cached $((Invoke-scupPSSqlQuery -Query "SELECT COUNT(costcenter_id) FROM costcenters;").'Column1') Costcenters..")
    }
}
