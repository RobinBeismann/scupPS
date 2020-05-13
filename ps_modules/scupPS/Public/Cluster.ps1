function Invoke-scupPSJobMasterElection(){
    . "$(Get-PodeState -Name "PSScriptRoot")\views\includes\lib\logging.ps1"
    
    if(
        #No heartbeat
        !($heartbeat = Get-scupPSValue -Name "jobMasterHeartbeat") -or
        #No current master
        !($curMaster = Get-scupPSValue -Name "jobMaster") -or        
        #Other host did not set a heartbeat for over two minutes
        ($heartbeat | Get-Date) -lt (Get-Date).AddMinutes(-2)
    ){
        Write-scupPSLog("Cluster: Error - Last heartbeat of $curMaster was $heartbeat, re-elected $env:COMPUTERNAME as master.")
        Set-scupPSValue -Name "jobMaster" -Value $env:COMPUTERNAME
        Set-scupPSValue -Name "jobMasterHeartbeat" -Value ([string](Get-Date))
    }else{
        Write-scupPSLog("Cluster: Current Master is $env:COMPUTERNAME, heartbeat '$heartbeat' is recent enough - not re-electing.")
    }

    if(
        ($curMaster = Get-scupPSValue -Name "jobMaster") -and
        ($curMaster -eq $env:COMPUTERNAME)
    ){
        Set-scupPSValue -Name "jobMasterHeartbeat" -Value ([string](Get-Date))
        Write-scupPSLog("Cluster: $env:COMPUTERNAME sent heartbeat..")
    }
}

function Get-scupPSJobMaster(){
    $master = $false
    try{
        if(!(Get-scupPSValue -Name "jobMaster")){
            Invoke-scupPSJobMasterElection
        }
        $master = (Get-scupPSValue -Name "jobMaster")
    }catch{
        Write-Host("Error on Get-scupPSJobMaster: $_")
    }
    return $master
}
function Test-scupPSJobMaster(){
    $res = $false
    try{
        if(!(Get-scupPSValue -Name "jobMaster")){
            Invoke-scupPSJobMasterElection
        }
        $res = (Get-scupPSValue -Name "jobMaster") -eq $env:COMPUTERNAME
    }catch{
        Write-Host("Error on Test-scupPSJobMaster: $_")
    }
    return $res
}