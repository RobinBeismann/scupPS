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
            Invoke-scupPSSqlQuery -Query "
            SELECT
                [config_name] AS Name,
                [config_value] AS Value
            FROM
                [dbo].[config]
            "
        )    
    }elseif($res = Invoke-scupPSSqlQuery -Query "SELECT [config_value] AS Value FROM [dbo].[config] WHERE [config_name] = '$Name'"){
        return $res.Value
    }elseif($ConfigVals[$Name]){
        return $ConfigVals[$Name].DefaultValue
    }
        
    return $false    
}

function Set-scupPSValue($Name,$Value){
    if($Name -and $Value){
        Invoke-scupPSSqlQuery -Query "
            UPDATE [dbo].[config]
            SET 
                [config_value] = '$Value'
            WHERE
                [config_name] = '$Name'
            IF @@ROWCOUNT = 0
            INSERT INTO [dbo].[config]
                (
                    [config_name],
                    [config_value]
                ) VALUES (
                    '$Name',
                    '$Value'
                )
        "
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


function Get-CMAppApprovalHistory($requestObject){
    ($requestObject | Get-CimInstance).RequestHistory | ForEach-Object {
    
        [PSCustomObject]@{
            Comments = $_.Comments
            Date = $_.ModifiedDate
            State = $_.State
        }
    } | Sort-Object -Property Date
}
function Invoke-scupPSAppRequestCaching($RequestGuid){
    $query =  "
        MERGE INTO 
            [dbo].[ApplicationRequests] 
            AS t
        USING 
            (
                SELECT 
                    [RequestGuid] = @RequestGuid,
                    [ModelName] = @ModelName,
                    [RequestedMachine] = @RequestedMachine,
                    [RequestHistory] = @RequestHistory,
                    [User] = @User,
                    [UserSid] = @UserSid,
                    [CurrentState] = @CurrentState,
                    [Comments] = @Comments,
                    [CI_UniqueID] = @CI_UniqueID,
                    [Application] = @Application
            ) 
            AS s
        ON 
            t.RequestGuid = s.RequestGuid
        WHEN MATCHED THEN
            UPDATE SET 
                [RequestGuid]=s.[RequestGuid],
                [ModelName] = s.[ModelName],
                [RequestedMachine] = s.[RequestedMachine],
                [RequestHistory] = s.[RequestHistory],
                [User] = s.[User],
                [UserSid] = s.[UserSid],
                [CurrentState] = s.[CurrentState],
                [Comments] = s.[Comments],
                [CI_UniqueID] = s.[CI_UniqueID],
                [Application] = s.[Application]
        WHEN NOT MATCHED THEN 
            INSERT 
            (
                [RequestGuid],
                [ModelName],
                [RequestedMachine],
                [RequestHistory],
                [User],
                [UserSid],
                [CurrentState],
                [Comments],
                [CI_UniqueID],
                [Application]
            )
            VALUES
            (
                s.[RequestGuid],
                s.[ModelName],
                s.[RequestedMachine],
                s.[RequestHistory],
                s.[User],
                s.[UserSid],
                s.[CurrentState],
                s.[Comments],
                s.[CI_UniqueID],
                s.[Application]
            );
    "       
    $queryAddition = $null
    if($RequestGuid){
        $queryAddition = "
            WHERE
                SMS_UserApplicationRequest.RequestGuid = '$requestGuid'
        "
    }
    Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
        SELECT 
            SMS_UserApplicationRequest.RequestedMachine,
            SMS_UserApplicationRequest.RequestGuid,
            SMS_UserApplicationRequest.Application,
            SMS_UserApplicationRequest.Comments,
            SMS_UserApplicationRequest.CurrentState,
            SMS_UserApplicationRequest.ModelName,
            SMS_UserApplicationRequest.User,
            SMS_R_User.givenName,
            SMS_R_User.sn,
            SMS_R_User.mail,
            SMS_R_User.SID,
            SMS_R_User.FullUserName,
            SMS_R_User.UserGroupName,
            SMS_R_User.DistinguishedName,
            SMS_R_User.$(Get-scupPSValue -Name "Attribute_managedcostCenters"),
            SMS_R_User.$(Get-scupPSValue -Name "Attribute_costCenter"),
            SMS_Application.LocalizedDisplayName,
            SMS_Application.ModelName,
            SMS_Application.CI_ID,
            SMS_Application.CI_UniqueID
        FROM 
            SMS_UserApplicationRequest
        JOIN 
            SMS_Application 
        ON 
            SMS_Application.ModelName = SMS_UserApplicationRequest.ModelName
        JOIN 
            SMS_R_User 
        ON 
            SMS_R_User.UniqueUserName = SMS_UserApplicationRequest.User
        $queryAddition
    " | ForEach-Object {
        Invoke-scupPSSqlQuery -Query $query -Parameters @{
            "RequestGUID" = [string]$_.SMS_UserApplicationRequest.RequestGUID
            "ModelName" = [string]$_.SMS_UserApplicationRequest.ModelName
            "RequestedMachine" = [string]$_.SMS_UserApplicationRequest.RequestedMachine
            "RequestHistory" = (Get-CMAppApprovalHistory -RequestObject $_.SMS_UserApplicationRequest | ConvertTo-Json)
            "User" = [string]$_.SMS_UserApplicationRequest.User
            "UserSid" = [string]$_.SMS_R_User.SID
            "CurrentState" = [string]$_.SMS_UserApplicationRequest.CurrentState
            "Comments" = [string]$_.SMS_UserApplicationRequest.Comments
            "CI_UniqueID" = [string]$_.SMS_Application.CI_UniqueID
            "Application" = [string]$_.SMS_UserApplicationRequest.Application
        }
    }
}
