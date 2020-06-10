Write-Host("Adding to read the SQL Queries..")
Add-PodeSchedule -Name 'CacheSqlQueries' -Cron '@minutely' -OnStart -ScriptBlock { 
    $table = @{}
    Get-ChildItem -Path "$(Get-PodeState -Name "PSScriptRoot")\db\queries" -Filter "*.sql" | Sort-Object | ForEach-Object {
        $baseName = $_.BaseName
        Write-Host("Caching Sql Query $baseName")
        $content = $_ | Get-Content -Raw
    
        (Get-scupPSValue).GetEnumerator() | Foreach-Object {
            $lName = "#$($_.Name.Trim())#"
            $oldContent = $content
            $content = $content.Replace($lName,$_.Value)
            if($oldContent -ne $content){
                Write-Host("$($baseName): Value $name got replaced by $($_.Value)")
            }
        }
        $table.$baseName = $content
    }
    Set-PodeState -Name "sqlQueries" -Value $table | Out-Null
}