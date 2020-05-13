# Regulary save states
Write-Host("Adding Scheduled Job to save states every minute..")
Add-PodeSchedule -Name 'saveStates' -Cron '@minutely' -ScriptBlock { 
    #param($e)        
    #Lock-PodeObject -Object $e.Lockable -ScriptBlock {
        Save-PodeState -Path ".\states.json"
    #}
}


