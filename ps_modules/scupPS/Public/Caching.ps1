function Invoke-scupPSAppRequestCaching($RequestGuid){
    $query =  "
        MERGE INTO 
            [dbo].[ApplicationRequests] 
            AS t
        USING 
            (
                SELECT 
                    [RequestGuid] = @RequestGuid,
                    [ModelName] = @ModelName,
                    [RequestedMachine] = @RequestedMachine,
                    [RequestHistory] = @RequestHistory,
                    [User] = @User,
                    [UserSid] = @UserSid,
                    [CurrentState] = @CurrentState,
                    [Comments] = @Comments,
                    [CI_UniqueID] = @CI_UniqueID,
                    [Application] = @Application
            ) 
            AS s
        ON 
            t.RequestGuid = s.RequestGuid
        WHEN MATCHED THEN
            UPDATE SET 
                [RequestGuid]=s.[RequestGuid],
                [ModelName] = s.[ModelName],
                [RequestedMachine] = s.[RequestedMachine],
                [RequestHistory] = s.[RequestHistory],
                [User] = s.[User],
                [UserSid] = s.[UserSid],
                [CurrentState] = s.[CurrentState],
                [Comments] = s.[Comments],
                [CI_UniqueID] = s.[CI_UniqueID],
                [Application] = s.[Application]
        WHEN NOT MATCHED THEN 
            INSERT 
            (
                [RequestGuid],
                [ModelName],
                [RequestedMachine],
                [RequestHistory],
                [User],
                [UserSid],
                [CurrentState],
                [Comments],
                [CI_UniqueID],
                [Application]
            )
            VALUES
            (
                s.[RequestGuid],
                s.[ModelName],
                s.[RequestedMachine],
                s.[RequestHistory],
                s.[User],
                s.[UserSid],
                s.[CurrentState],
                s.[Comments],
                s.[CI_UniqueID],
                s.[Application]
            );
    "       
    $queryAddition = $null
    if($RequestGuid){
        $queryAddition = "
            WHERE
                SMS_UserApplicationRequest.RequestGuid = '$requestGuid'
        "
    }
    Get-CimInstance -namespace (Get-scupPSValue -Name "SCCM_SiteNamespace") -computer (Get-scupPSValue -Name "SCCM_SiteServer") -query "
        SELECT 
            SMS_UserApplicationRequest.RequestedMachine,
            SMS_UserApplicationRequest.RequestGuid,
            SMS_UserApplicationRequest.Application,
            SMS_UserApplicationRequest.Comments,
            SMS_UserApplicationRequest.CurrentState,
            SMS_UserApplicationRequest.ModelName,
            SMS_UserApplicationRequest.User,
            SMS_R_User.givenName,
            SMS_R_User.sn,
            SMS_R_User.mail,
            SMS_R_User.SID,
            SMS_R_User.FullUserName,
            SMS_R_User.UserGroupName,
            SMS_R_User.DistinguishedName,
            SMS_R_User.$(Get-scupPSValue -Name "Attribute_managedcostCenters"),
            SMS_R_User.$(Get-scupPSValue -Name "Attribute_costCenter"),
            SMS_Application.LocalizedDisplayName,
            SMS_Application.ModelName,
            SMS_Application.CI_ID,
            SMS_Application.CI_UniqueID
        FROM 
            SMS_UserApplicationRequest
        JOIN 
            SMS_Application 
        ON 
            SMS_Application.ModelName = SMS_UserApplicationRequest.ModelName
        JOIN 
            SMS_R_User 
        ON 
            SMS_R_User.UniqueUserName = SMS_UserApplicationRequest.User
        $queryAddition
    " | ForEach-Object {
        Invoke-scupPSSqlQuery -Query $query -Parameters @{
            "RequestGUID" = [string]$_.SMS_UserApplicationRequest.RequestGUID
            "ModelName" = [string]$_.SMS_UserApplicationRequest.ModelName
            "RequestedMachine" = [string]$_.SMS_UserApplicationRequest.RequestedMachine
            "RequestHistory" = (Get-CMAppApprovalHistory -RequestObject $_.SMS_UserApplicationRequest | ConvertTo-Json)
            "User" = [string]$_.SMS_UserApplicationRequest.User
            "UserSid" = [string]$_.SMS_R_User.SID
            "CurrentState" = [string]$_.SMS_UserApplicationRequest.CurrentState
            "Comments" = [string]$_.SMS_UserApplicationRequest.Comments
            "CI_UniqueID" = [string]$_.SMS_Application.CI_UniqueID
            "Application" = [string]$_.SMS_UserApplicationRequest.Application
        }
    }
}