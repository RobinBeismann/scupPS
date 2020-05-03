. "$(Get-PodeState -Name "PSScriptRoot")\views\includes\server\database.ps1"

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
        DefaultValue = (@{
            admin = "will-be-overwritten"
            helpdesk = "Please select"
        } | ConvertTo-Json)
        Description = 'Roles Definition'
    }
}

function Get-scupPSValue($Name){
    
    if(!$Name){
        return (
            Execute-SQLiteQuery -Query "
            SELECT
                config.config_name AS Name,
                config.config_value AS Value
            FROM
                config
            "
        )    
    }elseif($res = Execute-SQLiteQuery -Query "SELECT config_value FROM config WHERE config_name = '$Name'"){
        return $res.config_value
    }elseif($ConfigVals[$Name]){
        return $ConfigVals[$Name].DefaultValue
    }
        
    return $false    
}

function Set-scupPSValue($Name,$Value){
    if($Name -and $Value){
        Execute-SQLiteQuery -Query @"
        INSERT OR REPLACE INTO 
            "main"."config" 
            (
                "config_name", 
                "config_value"
            ) VALUES (
                '$Name', 
                '$Value'
            )
"@
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
    return $ready
}

function Invoke-scupPSJobMasterElection(){
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\lib\logging.ps1"
    
    if(
        #No heartbeat
        !($heartbeat = Get-scupPSValue -Name "jobMasterHeartbeat") -or
        #No current master
        !($curMaster = Get-scupPSValue -Name "jobMaster") -or        
        #Other host did not set a heartbeat for over two minutes
        ($heartbeat | Get-Date) -lt (Get-Date).AddMinutes(-2)
    ){
        Write-scupPSLog("Cluster: Error - Last heartbeat of $curMaster was $heartbeat, re-elected $env:COMPUTERNAME as master.")
        Set-scupPSValue -Name "jobMaster" -Value $env:COMPUTERNAME
        Set-scupPSValue -Name "jobMasterHeartbeat" -Value ([string](Get-Date))
    }else{
        Write-scupPSLog("Cluster: Current Master is $env:COMPUTERNAME, heartbeat '$heartbeat' is recent enough - not re-electing.")
    }

    if(
        ($curMaster = Get-scupPSValue -Name "jobMaster") -and
        ($curMaster -eq $env:COMPUTERNAME)
    ){
        Set-scupPSValue -Name "jobMasterHeartbeat" -Value ([string](Get-Date))
        Write-scupPSLog("Cluster: $env:COMPUTERNAME sent heartbeat..")
    }
}

function Get-scupPSJobMaster(){
    $master = $false
    try{
        if(!(Get-scupPSValue -Name "jobMaster")){
            Invoke-scupPSJobMasterElection
        }
        $master = (Get-scupPSValue -Name "jobMaster")
    }catch{
        Write-Host("Error on Get-scupPSJobMaster: $_")
    }
    return $master
}
function Test-scupPSJobMaster(){
    $res = $false
    try{
        if(!(Get-scupPSValue -Name "jobMaster")){
            Invoke-scupPSJobMasterElection
        }
        $res = (Get-scupPSValue -Name "jobMaster") -eq $env:COMPUTERNAME
    }catch{
        Write-Host("Error on Test-scupPSJobMaster: $_")
    }
    return $res
}

