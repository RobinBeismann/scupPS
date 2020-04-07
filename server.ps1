Start-PodeServer -Threads 10 {
    Add-PodeEndpoint -Address 127.0.0.1 -Protocol Http

    #Logging
    New-PodeLoggingMethod -File -Path ./logs -Name 'errors' -MaxSize "100MB" | Enable-PodeErrorLogging
    New-PodeLoggingMethod -File -Path ./logs -Name 'request' -MaxSize "100MB" | Enable-PodeRequestLogging
    New-PodeLoggingMethod -File -Path ./logs -Name 'feed' -MaxSize "100MB" | Add-PodeLogger -Name 'Feed' -ScriptBlock {
        param($arg)        
        $string = ($arg.GetEnumerator() | ForEach-Object { $_.Name + ": " + $_.Value }) -join "; "
        return $string
    } -ArgumentList $arg

    #View Engine
    Set-PodeViewEngine -Type Pode

    #Generate Session Secret and store it
    try{
        $state = Restore-PodeState -Path ".\states.json" 
    }catch{
        Write-Host("Unable to read states")
    }
    if(!(Test-PodeState -Name "sessionSecret")){        
        $secretGen = -join ((65..90) + (97..122) | Get-Random -Count 30 | % {[char]$_})
        Set-PodeState -Name "sessionSecret" -Value $secretGen
        Save-PodeState -Path ".\states.json"
    }
    
    #Authentication 
    Enable-PodeSessionMiddleware -Secret (Get-PodeState -Name "sessionSecret") -Duration 120 -Extend
    Add-PodeAuthIIS -Name 'IISAuth'
    $IISAuth = Get-PodeAuthMiddleware -Name 'IISAuth'

    #Routes
    Write-Host("Server: Adding 'Index' Route..")
    Add-PodeRoute -Method Get -Path '/' -Middleware $IISAuth -ScriptBlock {
        param($Data)        
        Write-PodeViewResponse -Path 'index' -Data $Data
    }

    Write-Host("Server: Adding 'Page' Route..")
    Add-PodeRoute -Method Get -Path '/page' -Middleware $IISAuth -ScriptBlock {
        param($Data)               
        Write-PodeViewResponse -Path 'page' -Data $Data
    }
    
    Write-Host("Server: Adding 'api' Route..")
    Add-PodeRoute -Method Get -Path '/api' -Middleware $IISAuth -ScriptBlock {
        param($Data)               
        Write-PodeViewResponse -Path 'api' -Data $Data
    }

    #Include Includes    
    Write-Host("Server: Adding includes..")
    Get-ChildItem -Path "views\includes\server" -File -Include "*.ps1" -Recurse | ForEach-Object {
        Write-Host("Server: Including " + $_.FullName)
        Use-PodeScript -Path $_.FullName
    }
}