# Regulary transfer values
Write-Host("Adding Scheduled Job to save admin group into role every minute..")
Add-PodeSchedule -Name 'saveValues' -Cron '@minutely' -OnStart -ScriptBlock { 
    #Update the role with the group set under general settings
    Set-scupPSRole -Name "admin" -Value (Get-scupPSValue -Name "scupPSAdminGroup")
}