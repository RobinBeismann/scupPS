$global:log = ""

function Custom-Log($string){
    $log += ([string](Get-Date) + ": $string")
    return $string
}

#Request Information
$requestID = $Data.Query.submitrequestid
$denyreason = $Data.Query.submitdenyreason

$currentDate = [string](Get-Date -Format "yyyy\/MM\/dd hh:MM")

$localSender = $smtpSender.Replace("%SenderDisplayName%","$approverDisplayNameV1 (Approval Portal)")

if(
    ($operation -eq "approverequest") -or
    ($operation -eq "denyrequest") -or
    ($operation -eq "revokerequest")
){
    $reqObj = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "Select * From SMS_UserApplicationRequest where RequestGUID='$requestID'" | Get-CimInstance
    $reqObjRequestor = Get-CimInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "Select * From SMS_R_USER where Sid='$($reqObj.UserSid)'"
    $reqObjApprover = $authenticatedUser
    $reqObjOO = [wmi]"\\$SCCMServer\$($SCCMNameSpace):SMS_UserApplicationRequest.RequestGuid=`"$requestId`"" #Object for object oriented calls

    #Requestor Information
    $requestorFirstname = $reqObjRequestor.givenName
    $requestorLastname = $reqObjRequestor.sn
    $requestorMail = $reqObjRequestor.Mail
    $requestorDisplayNameV1 = "$requestorLastname, $requestorFirstname" 
    $requestorDisplayNameV2 = "$requestorFirstname $requestorLastname"

    #Approver Information
    $approverFirstname = $reqObjApprover.givenName
    $approverLastname = $reqObjApprover.sn
    $approverMail = $reqObjApprover.Mail
    $approverDisplayNameV1 = "$approverLastname, $approverFirstname" 
    $approverDisplayNameV2 = "$approverFirstname $approverLastname"

    $softwareTitle = $reqObj.Application
    $requestorMachine = $reqObj.RequestedMachine
    $mailTemplate = $null

    if($operation -eq "approverequest"){

        if($requestID -and $softwareTitle -and $requestorMachine){
            "Approved $softwareTitle for $requestorDisplayNameV1, starting installation on $requestorMachine"
            try{
                $result = $reqObjOO.Approve("Approved by $approverDisplayNameV1")
            }catch{
                $_
            }
            
            $mailTemplate = "approval.mailtemplate.html"    
            $mailSubject = "Application Approval granted"   
        }else{
            "An error occured while receiving request data."
        }
    }elseif($operation -eq "denyrequest"){

        if($requestID -and $softwareTitle -and $requestorMail -and $requestorMachine){
            "Denied $softwareTitle for $requestorDisplayNameV1."

            try{
                $result = $reqObjOO.Deny("Denied by $approverDisplayNameV1 with the Reason `"$denyreason`"")
            }catch{
                $_
            }

            $mailTemplate = "denied.mailtemplate.html"
            $mailSubject = "Application Approval denied" 
        }else{
            "An error occured while receiving request data."
        }
    }elseif($operation -eq "revokerequest"){

        if($requestID -and $softwareTitle -and $requestorMachine){
            "Revoked $softwareTitle for $requestorDisplayNameV1, starting uninstallation on $requestorMachine"

            try{
                $result = $reqObjOO.Deny("Revoked by $approverDisplayNameV1 with the Reason `"$denyreason`"")
            }catch{
                $_
            }

            $mailTemplate = "revoke.mailtemplate.html"
            $mailSubject = "Application Approval revoked"   
        }else{
            "An error occured while receiving request data."
        }
    }

    if($mailSubject -and $mailTemplate -and $mailTemplate -ne ""){
        
        $userText = Get-Content -Path ".\public\Assets\templates\$mailTemplate" -Raw
        $userText = $userText.Replace("%requestorDisplayNameV1%",$requestorDisplayNameV1)
        $userText = $userText.Replace("%requestorDisplayNameV2%",$requestorDisplayNameV2)
        $userText = $userText.Replace("%requestorFirstname%",$requestorFirstname)
        $userText = $userText.Replace("%requestorLastname%",$requestorLastname)
        $userText = $userText.Replace("%requestorMail%",$requestorMail)
        $userText = $userText.Replace("%approverDisplayNameV1%",$approverDisplayNameV1)
        $userText = $userText.Replace("%approverDisplayNameV2%",$approverDisplayNameV2)
        $userText = $userText.Replace("%approverFirstname%",$approverFirstname)
        $userText = $userText.Replace("%approverLastname%",$approverLastname)
        $userText = $userText.Replace("%approverMail%",$approverMail)
        $userText = $userText.Replace("%softwareTitle%",$softwareTitle)
        $userText = $userText.Replace("%requestorMachine%",$requestorMachine)
        $userText = $userText.Replace("%denyreason%",$denyreason)
        $userText = $userText.Replace("%mailSignature%",$smtpSignature)
        $userText = Replace-HTMLVariables -Value $userText

        if($requestorMail){
            Send-CustomMailMessage -SmtpServer $smtpServer -from $localSender -ReplyTo $smtpReplyTo -subject $mailSubject -to ($requestorMail,$approverMail) -CC $licensingContact -body $userText -BodyAsHtml
        }
    }

}