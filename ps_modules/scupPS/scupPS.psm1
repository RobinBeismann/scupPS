# load private functions
$root = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
if(Test-Path -Path "$($root)/Private/*.ps1" -ErrorAction SilentlyContinue){
    Get-ChildItem "$($root)/Private/*.ps1" | Resolve-Path | ForEach-Object { . $_ }
}

$sysfuncs = Get-ChildItem Function:

# load public functions
if(Test-Path -Path "$($root)/Public/*.ps1"  -ErrorAction SilentlyContinue){
    Get-ChildItem "$($root)/Public/*.ps1"  | Resolve-Path | ForEach-Object { . $_ }
}

# get functions from memory and compare to existing to find new functions added
$funcs = Get-ChildItem Function: | Where-Object { $sysfuncs -notcontains $_ }

# export the module's public functions
Export-ModuleMember -Function ($funcs.Name)