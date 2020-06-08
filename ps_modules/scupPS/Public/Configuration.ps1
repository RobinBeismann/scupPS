function Get-scupPSDefaultValues(){
    return [ordered]@{
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
        "SCCM_SiteDatabaseInstance" = @{
            DefaultValue = "<Name of Site Server Database Instance>"
            Description = "[Required] SCCM Site Database Instance"
            Type = 0
        }
        "SCCM_SiteDatabaseName" = @{
            DefaultValue = "<Name of Site Server Database>"
            Description = "[Required] SCCM Site Database Name"
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
}

function Get-scupPSValue([string]$Name,[Switch]$IgnoreCache){
    $cachedItem = $null
    if(!($Cache = Get-PodeState -Name "ConfigCache" -ErrorAction SilentlyContinue)){
        Set-PodeState -Name "ConfigCache" -Value @{}
        $Cache = @{}
    }
    
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
    #Cached Value    
    }elseif(
        ($cachedItem = $Cache.$Name) -and
        !$IgnoreCache
    ){
        #Write-Host("Returning Cache Value $cachedItem for Property $Name")
        return $cachedItem
    }elseif(
        #Not cached, retrieve it from DB
        $res = Invoke-scupPSSqlQuery -Query "SELECT [config_value] AS Value FROM [dbo].[config] WHERE [config_name] = @Name" -Parameters @{ Name = $Name }
    ){
        $null = $cache | Add-Member -NotePropertyName $Name -NotePropertyValue $res.Value -Force
        #Write-Host("Returning DB Value $($res.Value) for Property $Name")
        $null = Set-PodeState -Name "ConfigCache" -Value $Cache
        return $cache.$Name
    }elseif(
        $DefaultVal = (Get-scupPSDefaultValues).$Name
    ){
        return $DefaultVal.DefaultValue
    }
        
    return $false    
}

function Set-scupPSValue($Name,$Value){
    if(
        ($Value -is [hashtable]) -or
        ([String]$Value -like "*.Hashtable*")
    ){
        Write-scupPSLog("Not writing $Value for $Name to Database, invalid format!")
    }else{
        if($Name -and $Value){
            Invoke-scupPSSqlQuery -Query "
                UPDATE [dbo].[config]
                SET 
                    [config_value] = @Value
                WHERE
                    [config_name] = @Name
                IF @@ROWCOUNT = 0
                INSERT INTO [dbo].[config]
                    (
                        [config_name],
                        [config_value]
                    ) VALUES (
                        @Name,
                        @Value
                    )
            " -Parameters @{
                Name = $Name
                Value = $Value
            }
        } 
        $null = Set-PodeState -Name "ConfigCache" -Value @{}
    }
}