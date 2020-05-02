try{
    #Try to load the local module
    Import-Module -Name "$PSScriptRoot\pode\Pode.psm1" -ErrorAction Stop
    Write-Host("Loaded local Pode module.")
}catch{
    #Fail back to the system module
    Import-Module -Name "Pode"
    Write-Host("Loaded system Pode module.")
}


Start-PodeServer -Threads (Get-CimInstance -ClassName "Win32_Processor" | Select-Object -ExpandProperty NumberOfLogicalProcessors) -ScriptBlock {
    Add-PodeEndpoint -Address 127.0.0.1 -Protocol Http

    #Logging
    New-PodeLoggingMethod -File -Path ./logs -Name "$($env:COMPUTERNAME)_errors" -MaxSize "100MB" | Enable-PodeErrorLogging
    New-PodeLoggingMethod -File -Path ./logs -Name "$($env:COMPUTERNAME)_request" -MaxSize "100MB" | Enable-PodeRequestLogging
    New-PodeLoggingMethod -File -Path ./logs -Name "$($env:COMPUTERNAME)_feed" -MaxSize "100MB" | Add-PodeLogger -Name 'Feed' -ScriptBlock {
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
    
    if(Test-PodeIsIIS){
        #Running as IIS Sub Process, use Windows Auth
        Write-Host("Using IIS Authentication")
        Add-PodeAuthIIS -Name 'IISAuth' -NoGroups -NoLocalCheck
        $Auth = Get-PodeAuthMiddleware -Name 'IISAuth'
    }else{
        #Running as non IIS Process, entering Debug Mode
        Write-Host("Using Debug Authentication")
        $custom_type = New-PodeAuthType -Custom -ScriptBlock {
            param($e, $opts)

            return @("test")
        }
    
        # now, add a new custom authentication method using the type you created above
        $custom_type | Add-PodeAuth -Name 'Login' -ScriptBlock {
            param($username)
    
            # check if the client is valid in some database
    
            # return a user object (return $null if validation failed)
            return  @{ User = "test" }
        }
        $Auth = Get-PodeAuthMiddleware -Name 'Login'
    }
    
    #Save current directory as Pode State
    Set-PodeState -Name "PSScriptRoot" -Value $PSScriptRoot

    #Routes
    Write-Host("Server: Adding 'Index' Route..")
    Add-PodeRoute -Method Get -Path '/' -Middleware $Auth -ScriptBlock {
        param($Data)        
        Write-PodeViewResponse -Path 'index' -Data $Data
    }

    Write-Host("Server: Adding 'Page' Route..")
    Add-PodeRoute -Method Get -Path '/page' -Middleware $Auth -ScriptBlock {
        param($Data)               
        Write-PodeViewResponse -Path 'page' -Data $Data
    }
    
    Write-Host("Server: Adding 'api' Route..")
    Add-PodeRoute -Method Get -Path '/api' -Middleware $Auth -ScriptBlock {
        param($Data)               
        Write-PodeViewResponse -Path 'api' -Data $Data
    }

    #Include Includes    
    Write-Host("Server: Adding includes..")
    #Include Config
    Get-ChildItem -Path "$(Get-PodeState -Name "PSScriptRoot")\views\includes\server" -File -Include "*.ps1" -Recurse | ForEach-Object {
        Write-Host("Server: Including " + $_.FullName)
        Use-PodeScript -Path $_.FullName
    }
}