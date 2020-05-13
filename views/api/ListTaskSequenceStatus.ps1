if($operation -eq "listtasksequencestatus" -and $(Test-scupPSRole -Name "helpdesk" -User $authenticatedUser) -and ($requestorMachine = $Data.Query.submitrequestmachine)){
    
    $ts = Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
    SELECT 
        * 
    FROM 
        SMS_TaskSequenceExecutionStatus
    WHERE 
        ResourceID = $requestorMachine
    ORDER BY 
        Step DESC
    "

    '
    <style type="text/css">
    .tg  {border-collapse:collapse;border-spacing:0;}
    .tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;}
    .tg .tg-0lax{text-align:left;vertical-align:top}
    </style>
    <br/><a>Refresh Interval: 30s</a><br/>
    <table class="table table-responsive">
    <tr>
    <th>Step</th>
    <th>Group Name</th>
    <th>ActionName</th>
    <th>Exit Code</th>
    <th>ActionOutput</th>
    </tr>
    '

    #Fill table
    
    $ts | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.Step)</td>
            <td scope='col'>$($_.GroupName)</td>
            <td scope='col'>$($_.ActionName)</td>
            <td scope='col'>$($_.ExitCode)</td>
            <td scope='col'>$(Get-HTMLString -Value $_.ActionOutput)</td>
        </tr>"
    }

    #End Table    
    '</table><br/>'
    

}

