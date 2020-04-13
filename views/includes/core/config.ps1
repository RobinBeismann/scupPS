$ConfigVals = [ordered]@{
    <#
        Type = 0 -> First Tab of Setup Wizard
        Type = 1 -> Second Tab of Setup Wizard
        Type = 2 -> Third Tab of Setup Wizard
        Type = 3 -> Fourth Tab of Setup Wizard
        Type = 4 -> Not display on the setup wizard
        Type = 5 -> Not display on the setup wizard and not required to be set
    #>
    "SCCM_SiteServer" = @{
        DefaultValue = "<Site Server>"
        Description = "[Required] SCCM Site Server"
        Type = 0
    }
    "SCCM_SiteName" = @{
        DefaultValue = "<Three Letter Site Code>"
        Description = "[Required] SCCM Site Code (3 Letters)"
        Type = 0
    }
    "scupPSAdminGroup" = @{
        DefaultValue = "<CONTOSO\GroupName>"
        Description = "[Required] scupPS Admin Group"
        Type = 1        
    }
    "scupPSServerReady" = @{
        DefaultValue = $false
        Description = "This value describes if the server is ready or not, used internally"
    }
    "Collection_BrowsingAllowed" = @{
        DefaultValue = "All Windows 10 Systems"
        Description = "[Required] Collections browseable by the Helpdesk"
        Type = 2
    }
    "Attribute_managedcostCenters" = @{
        DefaultValue = "extensionattribute5"
        Description = "[Required] AD/MEMCM Attribute for the managed costcenters (as plain numbers delimited by semicola)"
        Type = 2
    }
    "Attribute_costCenter" = @{
        DefaultValue = "extensionattribute12"
        Description = "[Required] AD/MEMCM Attribute for the costcenter (as plain number)"
        Type = 2
    }
    "smtpServer" = @{
        DefaultValue = "<smtp.contoso.com>"
        Description = "[Required] SMTP Server Address"
        Type = 3
    }
    "smtpSender" = @{
        DefaultValue = "<no-reply@contoso.com>"
        Description = "[Required] Sender Mail Address"
        Type = 3
    }
    "smtpSignature" = @{
        DefaultValue = "<IT Support>"
        Description = "[Required] Mail Signature"
        Type = 3
    }
    "smtpReplyTo" = @{
        DefaultValue = "<it-support@contoso.com>"
        Description = "[Required] ReplyTo Mail Address"
        Type = 3
    }
    "smtpAdminRecipient" = @{
        DefaultValue = "<admin@contoso.com>"
        Description = "[Required] Admin Mail Address (retrieves Mails for Approval Migration and Approval Deletion)"
        Type = 3
    }
    "smtpAdditionalRecipient" = @{
        DefaultValue = $null
        Description = "[Optional] Mail Recipient which is added to all mails"
        Type = 5
    }

    "siteTitle" = @{
        DefaultValue = "User Portal"
        Description = "[Optional] Site Title used in varius places on the site"
        Type = 4
    }
    "siteCopyrightText" = @{
        DefaultValue = 'Copyright &copy; 2020 <a href="https://robin-beismann.com">Robin Beismann</a>.'
        Description = '[Optional] Copyright notice, respect the license delivered with scupPS'
        Type = 4
    }
    "scupPSRoles" = @{
        DefaultValue = @{
            admin = "will-be-overwritten"
            helpdesk = "Please select"
        }
        Description = 'Roles Definition'
    }
}

function Get-scupPSValue($Name){

    if(!($config = Get-PodeState -Name "scupPSConfig")){
        $config = @{}
    }

    if(!$Name){
        return $config
    }elseif($config.$Name){
        return $config.$Name
    }elseif($ConfigVals[$Name]){
        return $ConfigVals[$Name].DefaultValue
    }
        
    return $false    
}

function Set-scupPSValue($Name,$Value){
    if(!($config = Get-PodeState -Name "scupPSConfig")){
        $config = @{}
    }

    if(
        !($config.$Name) -or
        ($config | Get-Member -Name $Name -ErrorAction SilentlyContinue) -ne $Value
    ){
        Write-Host("Set-scupPSValue: Updating Config Val '$Name' to '$Value'")
        $config | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force        
        $config | Set-PodeState -Name "scupPSConfig" | Out-Null
        try{
            Invoke-PodeSchedule -Name 'saveStates' | Out-Null
        }catch{
            Write-Host("Failed to invoke state saving procedure.")
        }
    }
}

function Get-ServerReadyness(){
    if(
        ($ready = Get-scupPSValue -Name "scupPSServerReady") -and
        $ready -eq $true
    ){
        return $true
    }

    $ready = $true
    $ConfigVals.GetEnumerator() | Where-Object { $_.Value.Type -and $_.Value.Type -le 3 } | ForEach-Object {
        if(
            !($val = (Get-scupPSValue -Name $_.Name)) -or
            $val.StartsWith("<") -or
            $val.EndsWith(">")
        ){
            Write-Host("[$(Get-Date)] Required Value for $($_.Name) is not yet set - server not ready.")
            $ready = $false
        }       
    }
    Set-scupPSValue -Name "scupPSServerReady" -Value $ready
    Write-Host("Ready State: $ready")
    Invoke-PodeSchedule -Name 'CacheUsers'
    Invoke-PodeSchedule -Name 'CacheMachines'
    Invoke-PodeSchedule -Name 'CacheApplications'
    return $ready
}

function Get-scupPSUsers(){
    return Get-PodeState -Name "cache_Users"
}

function Get-scupPSMachines(){
    return Get-PodeState -Name "cache_Machines"
}

function Get-scupPSApplications(){
    return Get-PodeState -Name "cache_Applications"
}