# Create default values for all not yet set ones
Write-Host("Creating default values..")
#Include Config
. "$(Get-PodeState -Name "PSScriptRoot")\views\includes\core\config.ps1"

$ConfigVals.GetEnumerator() | ForEach-Object {
    Set-scupPSValue -Name $_.Name -Value (Get-scupPSValue -Name $_.Name)
}
