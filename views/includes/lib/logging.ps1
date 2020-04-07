function Write-scupPSLog($Message){
    $MessageType = "informational"

    if($Message.ToLower().Contains("warning")){
        $MessageType = "warning"
    }
    if($Message.ToLower().Contains("error")){
        $MessageType = "error"
    }
    
    @{
        MessageType = $MessageType
        Message = $Message
        Date = Get-Date -Format "yyyy-MM-dd hh:mm:ss"
    } | Write-PodeLog -Name "feed"

    Write-Host("scupPS Log: $Message")
}