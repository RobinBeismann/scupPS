# Cache Applications
Write-Host("Adding Scheduled Job to cache application requests..")
Add-PodeSchedule -Name 'CacheAppRequests' -Cron '@hourly' -OnStart -ScriptBlock {
    Start-Sleep -Seconds 10
    
    if(Test-scupPSJobMaster){
        Invoke-scupPSAppRequestCaching
    }
    Write-Host("Cached $( (Invoke-scupPSSqlQuery -Query "SELECT COUNT(RequestGUID) FROM ApplicationRequests;").'Column1') Application Requests..")
}