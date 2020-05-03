Add-PodeSchedule -Name 'electJobmaster' -Cron '@minutely' -OnStart -ScriptBlock { 
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\core\config.ps1"
    Invoke-scupPSJobMasterElection
}
