# Cache Users
Write-Host("Creating default values..")
. ".\views\includes\core\config.ps1"

$ConfigVals.GetEnumerator() | ForEach-Object {
    Set-scupPSValue -Name $_.Name -Value (Get-scupPSValue -Name $_.Name)
}
