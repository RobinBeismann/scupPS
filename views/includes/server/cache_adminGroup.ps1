# Regulary transfer values
Write-Host("Adding Scheduled Job to save states every minute..")
Add-PodeSchedule -Name 'saveValues' -Cron '@minutely' -OnStart -ScriptBlock { 
    #Update the role with the group set under general settings
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\core\config.ps1"
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\core\userLib.ps1"
    Set-scupPSRole -Name "admin" -Value (Get-scupPSValue -Name "scupPSAdminGroup")
}