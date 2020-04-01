$global:log = ""

function Custom-Log($string){
    $log += ([string](Get-Date) + ": $string")
    return $string
}

#Request Information
$requestorMachine = $Data.Query.submitrequestmachine

if($operation -eq "listupdates" -and $UserIsAdmin){
    
    $updates = Get-CimInstance -ComputerName $SCCMServer -Namespace $SCCMNameSpace -Query ("
        SELECT 
            SMS_R_System.Name,SMS_G_System_QUICK_FIX_ENGINEERING.HotFixID,SMS_G_System_QUICK_FIX_ENGINEERING.Description,SMS_G_System_QUICK_FIX_ENGINEERING.Caption,SMS_G_System_QUICK_FIX_ENGINEERING.Timestamp
        FROM
            SMS_R_System
        INNER JOIN 
            SMS_G_System_QUICK_FIX_ENGINEERING on SMS_R_System.ResourceID = SMS_G_System_QUICK_FIX_ENGINEERING.ResourceID
        WHERE
            SMS_R_SYSTEM.Name= '$requestorMachine'
    ")

    $updateList = @()

    $updates | ForEach-Object {
        $update = $_.SMS_G_System_QUICK_FIX_ENGINEERING
        
        $updateList += [PSCustomObject]@{
            HotFixID = $update.HotFixID
            Description = $update.Description
            Caption = $update.Caption
            InstalledOn = ($update.TimeStamp | Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
    }

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
    <th>InstalledOn</th>
    <th>URL</th>
    </tr>
    '

    #Fill table
    $updateList.GetEnumerator() | Sort-Object -Property 'InstalledOn' -Descending | ForEach-Object {
        "<tr>
            <td scope='col'>$($_.HotFixID)</td>
            <td scope='col'>$($_.Description)</td>
            <td scope='col'>$($_.InstalledOn)</td>
            <td scope='col'><a href='$($_.Caption)'>$($_.Caption)</a></td>
        </tr>"
    }

    #End Table    
    '</table><br/>'
}

