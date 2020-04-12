#$OutputEncoding = [Console]::OutputEncoding


function Count-Character($string,$char){
    ($string.ToCharArray() | Where-Object {$_ -eq $char} | Measure-Object).Count
}

function Generate-Username($firstname,$surname,$list){
    
    $syntax = @()
    $syntax += "LLLLFF"
    $syntax += "LLLFFF"
    $syntax += "LLFFFF"
    $syntax += "LLLLLF"
    $syntax += "LLLLLL"

    $electedName = $null
    
    foreach($syn in $syntax){
        $L = Count-Character -string $syn -char "L"
        $F = Count-Character -string $syn -char "F"
        
        if(!$electedName){
            if(!($L -gt $surname.Length) -or ($F -gt $firstname.Length)){
                $Genname = $surname.Substring(0,$L) + $firstname.Substring(0,$F)
                if(!($list.GetEnumerator() | Where-Object { $_ -eq $Genname })){
                    $electedName = $Genname
                }
            }
        }
    }

    return $electedName.ToLower()
}

function Get-StringHash([String] $String,$HashName = "MD5") 
{ 
    $StringBuilder = New-Object System.Text.StringBuilder 
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{ 
    [Void]$StringBuilder.Append($_.ToString("x2")) 
    } 
    $StringBuilder.ToString() 
}

function Send-CustomMailMessage(){
    param(
        [string]$smtpServer,
        [string]$from,
        [string]$subject,
        [array]$to,
        [string]$body,
        [switch]$BodyAsHtml,
        [array]$attachments,
        [string]$ReplyTo,
        [array]$CC
    )
    
    $message = New-Object System.Net.Mail.MailMessage
    $to | ForEach-Object {
        $message.To.Add($_)
    }

    if($CC){
        $CC | ForEach-Object {
            $message.CC.Add($_)
        }
    }
    
    $message.From = $from
    $message.Subject = $subject
    $message.Body = $body

    if($BodyAsHtml){
        $message.IsBodyHTML = $true
    }

    if($ReplyTo){
        $message.ReplyTo = $ReplyTo
    }

    if($attachments){
        $attachments | % {
            if(Test-Path -Path $_){
                $message.Attachments.Add($_)
            }else{
                Write-Error("Couldn't find attachment $_, breaking")
                break;
            }
        }
    }

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($message)
    
}

function Send-AdminNotification(){
    param(
        [string]$subject,
        [string]$body
    )

    Send-CustomMailMessage -SmtpServer (Get-scupPSValue -Name "smtpServer") -from (Get-scupPSValue -Name "smtpAdminRecipient") -subject $subject -to (Get-scupPSValue -Name "smtpAdminRecipient") -body $body -BodyAsHtml
}