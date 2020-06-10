if($operation -eq "ClientDetails_submit" -and $(Test-scupPSRole -Name "helpdesk" -User $Data.authenticatedUser)){
    #Request Information
    if(!$requestorMachine){
        $requestorMachine = $Data.Query.submitrequestmachine
    }

    $query = Invoke-scupCCMSqlQuery -Query "
    SELECT 
        *
    FROM
        [dbo].[v_R_System] as [system]
    INNER JOIN 
        v_GS_COMPUTER_SYSTEM_PRODUCT AS [system_product] 
        ON 
            [system].ResourceID = system_product.ResourceID
    INNER JOIN 
        v_GS_COMPUTER_SYSTEM AS [computer_system]
        ON
            [system].ResourceID = [computer_system].ResourceID
    INNER JOIN 
        v_CH_ClientSummary AS [clientsummary]
        ON
            [system].ResourceID = [clientsummary].ResourceID
    WHERE
        [system].Name0 = @Machine
    " -Parameters @{ Machine = $requestorMachine }
    
    
    #Build basic data array
    $dataArr = [ordered]@{
        "Computer Details" = [ordered]@{
            "Manufacturer" = $query.Manufacturer0
            "Model" = $query.Model0
            "SerialNumber" = $query.IdentifyingNumber0
            "Name" = $query.Name0
            "Domain" = $query.Domain0
            "CPU Count" = $query.NumberOfProcessors0
            "Memory" = "$([math]::Round($query.TotalPhysicalMemory0/1024/1024))GB"
            "Extended Security Updates Key" = $query.ESUValue
            "Windows Build" = $query.BuildExt
        }
    
        "Disks" = @{}
    
        "AD Details" = [ordered]@{
            "Last AD Logon Date" = $query.Last_Logon_Timestamp0 | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Distinguished Name" = $query.Distinguished_Name0
            "Azure AD Device ID" = $query.AADDeviceID
            "Azure AD Tenant ID" = $query.AADTenantID
        }

        "Config Manager Details" = [ordered]@{
            "Last Hardware Inventory" = $query.LastHW | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Last active time" = $query.LastOnline | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Last policy request" = $query.LastPolicyRequest | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Last management point" = $query.LastMPServerName
            "Expected next reporting" = $query.ExpectedNextPolicyRequest | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    
    }
    
    Invoke-scupCCMSqlQuery -Query "
    SELECT 
        *
    FROM
        v_GS_DISK AS disks
    LEFT JOIN 
        [dbo].[v_R_System] as [system]
        ON
            [system].ResourceID = disks.ResourceID
    WHERE
        [system].Name0 = '$requestorMachine'
    " | Foreach-Object {
        $dataArr.'Disks'.$($_.Index0) += @{
            DiskID = $_.Index0
            Model = $_.Model0
            Size = "$([math]::Round($_.Size0/1024))GB"
        }
    }
    #Build the tables
    $dataArr.Keys | ForEach-Object {
        Write-Host("Processing $_")
        "<legend>$_</legend>"
        $data = $dataArr.$_
    
        Get-GeneratedTable($data)  
    }

}

