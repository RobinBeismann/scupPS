Add-PodeSchedule -Name 'electJobmaster' -Cron '@minutely' -OnStart -ScriptBlock { 
    Invoke-scupPSJobMasterElection
}
