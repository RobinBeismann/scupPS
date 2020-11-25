if($operation -eq "ClientList_submit" -and $(Test-scupPSRole -Name "helpdesk" -User $WebEvent.authenticatedUser) -and ($collection = $WebEvent.Query.submitcollection) -and ($collection -in $((Get-scupPSValue -Name "Collection_BrowsingAllowed").Split(";") ))){
    
    #Get Computers
    $query = Invoke-scupCCMSqlQuery -Query "
        SELECT
            [system].name0 AS machine_name,
            (
            CASE
            WHEN [system].user_domain0 IS NOT NULL AND
                [system].user_name0 IS NOT NULL THEN Concat(
                [system].user_domain0,
                '\', [system].user_name0)
        
            END
            ) AS machine_user,
            [system].ad_site_name0 AS machine_lastadsite,
            [clientsummary].lastactivetime AS machine_lastclientactivity,
            [computer_system].manufacturer0 AS machine_manufacturer,
            [computer_system].model0 AS machine_model,
            [system_product].identifyingnumber0 AS machine_serialnumber,
            [processor].name0 AS machine_cpu,
            Concat(([computer_system].totalphysicalmemory0 / 1024), ' MB ') AS machine_memory
        FROM [dbo].[v_r_system] AS [system]
        LEFT JOIN v_ch_clientsummary AS [clientsummary]
            ON [system].resourceid = [clientsummary].resourceid
        LEFT JOIN v_gs_processor AS processor
            ON [system].resourceid = [processor].resourceid
        LEFT JOIN v_gs_computer_system_product AS [system_product]
            ON [system].resourceid = system_product.resourceid
        LEFT JOIN v_gs_computer_system AS [computer_system]
            ON [system].resourceid = [computer_system].resourceid
        WHERE [system].resourceid IN (SELECT
            membership.resourceid
        FROM [dbo].[v_fullcollectionmembership] AS membership
        LEFT JOIN [dbo].[v_collections] AS collections
            ON [collections].[siteid] = [membership].collectionid
        WHERE collections.collectionname LIKE @Collection)
        AND [system].client0 = 1
        ORDER BY [system].name0
    " -Parameters @{ Collection = $collection }

    #Table header
    '
    <!-- Form Name -->
    <legend>List Computers</legend>
    <style type="text/css">
    .tg  {border-collapse:collapse;border-spacing:0;}
    .tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg .tg-0lax{text-align:left;vertical-align:top}
    </style>
    <table class="table table-responsive">
    <tr>
    <th>Name</th>
    <th>Last User</th>
    <th>Last AD Site</th>
    <th>Last Client Activity</th>
    <th>Manufacturer</th>
    <th>Model</th>
    <th>Serialnumber</th>
    <th>CPU</th>
    <th>Memory</th>
    </tr>
    '

    #Fill table
    $query | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.machine_name)</td>
            <td scope='col'>$($_.machine_user)</td>
            <td scope='col'>$($_.machine_lastadsite)</td>
            <td scope='col'>$($_.machine_lastclientactivity | Get-Date -Format "yyyy-MM-dd HH:mm:ss")</td>
            <td scope='col'>$($_.machine_manufacturer)</td>
            <td scope='col'>$($_.machine_model)</td>
            <td scope='col'>$($_.machine_serialnumber)</td>
            <td scope='col'>$($_.machine_cpu)</td>
            <td scope='col'>$($_.machine_memory)</td>
        </tr>"
    }

    #End Table    
    '</table><br/>'

}

