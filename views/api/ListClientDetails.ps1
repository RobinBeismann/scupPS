function Generate-Table($arr){
    
    #Table header
    '<style type="text/css">
    .tg  {border-collapse:collapse;border-spacing:0;}
    .tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg .tg-0lax{text-align:left;vertical-align:top}
    </style>
        
    <table class="table table-responsive">
    <tr>
    <th>Name</th>
    <th>Value</th>
    </tr>
    '

    $arr.GetEnumerator() | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.Name)</td>
            <td scope='col'>$(
                if($_.Value -is [hashtable]){
                    Generate-Table($_.Value)
                }else{
                    $_.Value
                }
            )</td>
        </tr>"
    }

    #End Table    
    '</table><br/>'
}

if($operation -eq "listclientdetails" -and $(Test-scupPSRole -Name "helpdesk" -User $Data.authenticatedUser)){
    #Request Information
    if(!$requestorMachine){
        $requestorMachine = $Data.Query.submitrequestmachine
    }

    $PCInfo = Get-CimInstance -ComputerName (Get-scupPSValue -Name "SCCM_SiteServer") -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -Query (
    "SELECT 
        *
    FROM
        SMS_R_System
    INNER JOIN 
        SMS_G_System_Computer_System_Product on SMS_R_System.ResourceID = SMS_G_System_Computer_System_Product.ResourceID
    INNER JOIN 
        SMS_G_System_Computer_System on SMS_R_System.ResourceID = SMS_G_System_Computer_System.ResourceID
    INNER JOIN 
        SMS_G_System_CH_ClientSummary on SMS_R_System.ResourceID = SMS_G_System_CH_ClientSummary.ResourceID
    INNER JOIN 
        SMS_G_System_DISK on SMS_R_System.ResourceID = SMS_G_System_DISK.ResourceID
    WHERE
        SMS_R_SYSTEM.Name= '$requestorMachine'
    ")

    $ClientSum = $PCInfo.SMS_G_System_CH_ClientSummary | Select-Object -First 1
    $ClientSystem = $PCInfo.SMS_G_System_Computer_System | Select-Object -First 1
    $ClientProduct = $PCInfo.SMS_G_System_Computer_System_Product

    #Build basic data array
    $dataArr = [ordered]@{
        "Computer Details" = [ordered]@{
            Manufacturer = $ClientSystem.Manufacturer
            Model = $ClientSystem.Model
            SerialNumber = ($ClientProduct.IdentifyingNumber | Select-Object -First 1)
            Name = $ClientSystem.Name
            Domain = $ClientSystem.Domain
            Memory = "$([math]::Round($ClientSystem.TotalPhysicalMemory/1024/1024))GB"
        }

        "Disks" = @{}

        "Config Manager Details" = [ordered]@{
            "Last AD Logon (might not be accurate)" = $clientSum.ADLastLogonTime | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Last active time" = $clientSum.LastActiveTime | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Last policy request" = $clientSum.LastPolicyRequest | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

    }

    #Fill the array with some infos (disks)
    $PCInfo.SMS_G_System_DISK | ForEach-Object {
        $dataArr.'Disks'.$($_.Index) += @{
            DiskID = $_.Index
            Model = $_.Model
            Size = "$([math]::Round($_.Size/1024))GB"
        }
    }

    #Build the tables
    $dataArr.Keys | ForEach-Object {
        Write-Host("Processing $_")
        "<legend>$_</legend>"
        $data = $dataArr.$_

        Generate-Table($data)  
    }

}

