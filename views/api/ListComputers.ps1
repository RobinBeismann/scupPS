#Request Information


if($operation -eq "listcomputers" -and $(Test-scupPSRole -Name "helpdesk" -User $authenticatedUser) -and ($collection = $Data.Query.submitcollection) -and ($collection -in $((Get-scupPSValue -Name "Collection_BrowsingAllowed").Split(";") ))){
    
    #Get Computers
    $wmiComputers = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
    SELECT
        * 
    FROM SMS_R_System
     
    JOIN 
        SMS_UserMachineRelationship 
    ON 
        SMS_R_System.ResourceID  = SMS_UserMachineRelationship.ResourceID
        
    JOIN 
        SMS_G_System_CH_ClientSummary 
    ON 
        SMS_R_System.ResourceID = SMS_G_System_CH_ClientSummary.ResourceID

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
    
    $computers = @{}
    $wmiComputers | ForEach-Object {
        $computers[$_.SMS_R_System.Name] = $_
    }

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
    <th>Primary User</th>
    <th>Last Logged On</th>
    <th>Last AD Site</th>
    <th>Last Client Activity</th>
    </tr>
    '

    #Fill table
    $computers.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
        $System = $_.Value.SMS_R_System
        $ClientSum = $_.Value.SMS_G_System_CH_ClientSummary
        $Affinity = $_.Value.SMS_UserMachineRelationship
        "<tr>
            <td scope='col'>$($System.Name)</td>
            <td scope='col'>$($Affinity.UniqueUserName)</td>
            <td scope='col'>
                $(        
                    if($System.LastLogonUserDomain -and $System.LastLogonUsername){
                        "$($System.LastLogonUserDomain)\$($System.LastLogonUserName)"
                    }
                )
            </td>
            <td scope='col'>$($System.ADSiteName)</td>
            <td scope='col'>$($clientSum.LastActiveTime | Get-Date -Format "yyyy-MM-dd HH:mm:ss")</td>
        </tr>"
    }

    #End Table    
    '</table><br/>'

}

