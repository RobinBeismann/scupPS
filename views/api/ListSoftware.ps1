if($operation -eq "listsoftware" -and $(Test-scupPSRole -Name "helpdesk" -User $authenticatedUser)){
    $requestorMachine = $Data.Query.submitrequestmachine

    $software = Get-CimInstance -ComputerName (Get-scupPSValue -Name "SCCM_SiteServer") -Namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -Query (
    "SELECT 
        InstalledLocation,ProductVersion,ProductName
    FROM
        SMS_R_System
    JOIN 
        SMS_G_SYSTEM_Installed_Software on SMS_R_System.ResourceID = SMS_G_SYSTEM_Installed_Software.ResourceID
    WHERE
        SMS_R_SYSTEM.Name= ""$($requestorMachine)"" ") |
    Select-Object -Property ProductName, ProductVersion, InstalledLocation | 
    Sort-Object ProductName

    #Table header
    '<style type="text/css">
    .tg  {border-collapse:collapse;border-spacing:0;}
    .tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg .tg-0lax{text-align:left;vertical-align:top}
    </style>
    <table class="table table-responsive">
    <tr>
    <th>Software</th>
    <th>Version</th>
    <th>Install Location</th>
    </tr>
    '

    #Fill table
    $software | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.ProductName)</td>
            <td scope='col'>$($_.ProductVersion)</td>
            <td scope='col'>$($_.InstalledLocation)</a></td>
        </tr>"
    }

    #End Table    
    '</table><br/>'
}

