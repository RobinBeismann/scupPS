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
        Static = @{
            Cache = @{
                Enable = $true               
                Include = @(
                    "*"
                )
                MaxAge = 604800
            }
        }
    }
}