@{
    Server = @{
        FileMonitor = @{
            Enable = $false
            Include = @("*.ps1", "*.pode")
        }
    }
    Web = @{
        TransferEncoding = @{
            Default = "gzip"
        }
    }
}