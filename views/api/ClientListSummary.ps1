if($operation -eq "ClientListSummary_submit" -and $(Test-scupPSRole -Name "helpdesk" -User $Data.authenticatedUser) -and ($collection = $Data.Query.submitcollection) -and ($collection -in $((Get-scupPSValue -Name "Collection_BrowsingAllowed").Split(";")))){
    
    #Get Computers
    $query = Invoke-scupCCMSqlQuery -Query "
    SELECT
        COUNT([computer_system].Model0) AS [amount],
        CONCAT([computer_system].Manufacturer0,' - ', [computer_system].Model0) AS model
    FROM
        v_GS_COMPUTER_SYSTEM AS [computer_system]
    WHERE  [computer_system].resourceid IN (
                                SELECT 
                                    membership.resourceid 
                                FROM   
                                    [dbo].[v_fullcollectionmembership] AS membership 
                                LEFT JOIN 
                                    [dbo].[v_collections] AS collections 
                                        ON [collections].[siteid] = [membership].collectionid 
                                WHERE  collections.collectionname LIKE @Collection) 
    GROUP BY
        (CONCAT([computer_system].Manufacturer0,' - ', [computer_system].Model0))
    ORDER BY
        COUNT([computer_system].Model0) DESC
    " -Parameters @{ Collection = $collection }

    #Table header
    '
    <!-- Form Name -->
    <legend>List Computers by Model</legend>
    <style type="text/css">
    .tg  {border-collapse:collapse;border-spacing:0;}
    .tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg .tg-0lax{text-align:left;vertical-align:top}
    </style>
    <table class="table table-responsive">
    <tr>
    <th>Count</th>
    <th>Devices</th>
    </tr>
    '

    #Fill table
    $query | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.model)</td>
            <td scope='col'>$($_.amount)</td>
        </tr>"
    }

    #End Table    
    '</table><br/>'
}

