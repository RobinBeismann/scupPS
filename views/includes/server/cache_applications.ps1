# Cache Applications
Write-Host("Adding Scheduled Job to cache applications..")
Add-PodeSchedule -Name 'CacheApplications' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 10
    
    if(Test-scupPSJobMaster){
        Write-Host("Caching Applications..")
        while(
            (Get-ServerReadyness) -eq $false
        ){
            Start-Sleep -Seconds 10
        }
        Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
            SELECT 
                ModelName,CI_ID 
            FROM 
                SMS_Application 
            WHERE 
                IsLatest = 1
        " | Get-CimInstance | ForEach-Object {    
            $data = $null
            [xml]$xml = $_ | Select-Object -ExpandProperty SDMPackageXML
            if($xml.AppMgmtDigest.Application.DisplayInfo.Info.Count -gt 1){
                $data = $xml.AppMgmtDigest.Application.DisplayInfo.Info | Where-Object {
                    $_.Language.ToLower() -eq "en-US" -or
                    $_.Language.ToLower() -eq "en"
                }
            }else{
                $data = $xml.AppMgmtDigest.Application.DisplayInfo.Info
            }

            $query =  "
            MERGE INTO 
                [dbo].[applications] 
                AS t
            USING 
                (
                    SELECT 
                        app_modelname = @app_modelname,
                        app_publisher = @app_publisher,
                        app_title = @app_title,
                        app_description = @app_description
                ) 
                AS s
            ON 
                t.app_modelname = s.app_modelname
            WHEN MATCHED THEN
                UPDATE SET 
                    app_modelname=s.app_modelname,
                    app_publisher = s.app_publisher,
                    app_title = s.app_title,
                    app_description = s.app_description
            WHEN NOT MATCHED THEN 
                INSERT 
                (
                    app_modelname,
                    app_publisher,
                    app_title,
                    app_description
                )
                VALUES
                (
                    s.app_modelname,
                    s.app_publisher,
                    s.app_title,
                    s.app_description
                );
            "    
             
            Invoke-scupPSSqlQuery -Query $query -Parameters @{
                "app_modelname" = $_.Modelname
                "app_publisher" = $data.Publisher
                "app_title" = $data.Title
                "app_description" = $data.Description
            }
        }
        Write-Host("Cached $( (Invoke-scupPSSqlQuery -Query "SELECT COUNT(app_modelname) FROM applications;").'Column1') Applications..")
    }
}
