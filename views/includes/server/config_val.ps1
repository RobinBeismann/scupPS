# Create default values for all not yet set ones
Write-Host("Creating default values..")
#Include Config
. (Get-PodeRelativePath -Path ".\views\includes\core\config.ps1" -JoinRoot -Resolve)

$ConfigVals.GetEnumerator() | ForEach-Object {
    Set-scupPSValue -Name $_.Name -Value (Get-scupPSValue -Name $_.Name)
}
