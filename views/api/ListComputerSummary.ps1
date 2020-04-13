#Request Information
$collection = $Data.Query.submitcollection

if($operation -eq "listcomputersummary" -and $(Test-scupPSRole -Name "helpdesk" -User $authenticatedUser) -and $collection -and ($collection -in $((Get-scupPSValue -Name "Collection_BrowsingAllowed").Split(";")))){
    
    #Get Computers
    $wmiComputers = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
    SELECT
         SMS_G_System_Computer_System.Model,SMS_G_System_Computer_System.Manufacturer
    FROM SMS_R_System

    INNER JOIN 
        SMS_G_System_Computer_System
    ON 
        SMS_R_System.ResourceID = SMS_G_System_Computer_System.ResourceID
      
    WHERE ResourceID in 
        (
            SELECT 
                ResourceID
            FROM 
                SMS_FullCollectionMembership 
            JOIN 
                SMS_Collection 
            ON 
                SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID 
            WHERE
                SMS_Collection.name LIKE `'$collection`'
         )
    ORDER BY
        SMS_R_System.Name
    "

    $wmiComputers = $wmiComputers | ForEach-Object { "$($_.Manufacturer) - $($_.Model)" } | Group-Object | Sort-Object -Property Count -Descending

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
    $wmiComputers | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.Name)</td>
            <td scope='col'>$($_.Count)</td>
        </tr>"
    }

    #End Table    
    '</table><br/>'
}

