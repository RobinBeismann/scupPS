# Create default values for all not yet set ones
Write-Host("Creating default values..")

(Get-scupPSDefaultValues).GetEnumerator() | ForEach-Object {
    Set-scupPSValue -Name $_.Name -Value (Get-scupPSValue -Name $_.Name)
}
