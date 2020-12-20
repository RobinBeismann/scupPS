if($operation -eq "ClientListSoftware_submit" -and $(Test-scupPSRole -Name "helpdesk" -User $WebEvent.authenticatedUser)){
    $requestorMachine = $WebEvent.Query.submitrequestmachine

    $query = Invoke-scupCCMSqlQuery -Query "
        SELECT 
            systems.Name0				AS machine_name,
            software.Publisher0			AS app_publisher,
            software.ProductName0		AS app_title,
            software.ProductVersion0	AS app_version,
            software.InstalledLocation0	AS app_installlocation,
            software.InstallDate0		AS app_installdate
        FROM
            [dbo].[v_R_System] as systems
        JOIN 
            v_GS_INSTALLED_SOFTWARE AS software
                ON systems.ResourceID = software.ResourceID
        WHERE
            systems.Name0 = @machine
        ORDER BY
            software.Publisher0,software.ProductName0,software.ProductVersion0
    " -Parameters @{ Machine = $requestorMachine }

    #Table header
    '<style type="text/css">
    .tg  {border-collapse:collapse;border-spacing:0;}
    .tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg .tg-0lax{text-align:left;vertical-align:top}
    </style>
    <table class="table table-responsive">
    <tr>
    <th>Publisher</th>
    <th>Software</th>
    <th>Version</th>
    <th>Install Location</th>
    </tr>
    '

    #Fill table
    $query | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.app_publisher)</td>
            <td scope='col'>$($_.app_title)</td>
            <td scope='col'>$($_.app_version)</td>
            <td scope='col'>$($_.app_installlocation)</a></td>
        </tr>"
    }

    #End Table    
    '</table><br/>'
}

