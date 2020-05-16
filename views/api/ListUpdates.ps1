if($operation -eq "listupdates" -and $(Test-scupPSRole -Name "helpdesk" -User $Data.authenticatedUser)){
    #Request Information
    $requestorMachine = $Data.Query.submitrequestmachine

    $query = Invoke-scupCCMSqlQuery -Query "
        SELECT 
            systems.Name0				AS machine_name,
            updates.Description0		AS hotfix_desc,
            updates.HotFixID0			AS hotfix_id,
            updates.InstalledOn0		AS hotfix_installdate,
            updates.InstalledBy0		AS hotfix_installedby,
            updates.Caption0			AS hotfix_caption

        FROM
            [dbo].[v_R_System] as systems
        JOIN 
            v_GS_QUICK_FIX_ENGINEERING AS updates
                ON systems.ResourceID = updates.ResourceID
        WHERE
            systems.Name0 = @machine
        ORDER BY
            updates.HotFixID0
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
    <th>Hotfix ID</th>
    <th>Description</th>
    <th>Installed On</th>
    <th>Installed By</th>
    <th>URL</th>
    </tr>
    '

    #Fill table
    $query | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.hotfix_id)</td>
            <td scope='col'>$($_.hotfix_desc)</td>
            <td scope='col'>$($_.hotfix_installdate)</td>
            <td scope='col'>$($_.hotfix_installedby)</td>
            <td scope='col'><a href='$($_.hotfix_caption)'>$($_.hotfix_caption)</a></td>
        </tr>"
    }

    #End Table    
    '</table><br/>'
}

