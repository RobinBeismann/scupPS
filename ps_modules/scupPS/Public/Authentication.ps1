function Get-scupPSAuthUser($Data){
    #Get values and return fake valid ones incase they were not yet set
    if(!($attrMCostcenters = Get-scupPSValue -Name "Attribute_managedcostCenters")){
        $attrMCostcenters = "ResourceID"
    }
    if(!($attrCostcenter = Get-scupPSValue -Name "Attribute_costCenter")){
        $attrCostcenter = "ResourceID"
    }

    $userQuery = "
        SELECT 
            [ResourceID]						AS [ResourceID]
            ,[ResourceType]					    AS [ResourceType]
            ,[AADTenantID]					    AS [AADTenantID]
            ,[AADUserID]						AS [AADUserID]
            ,[AD_Object_Creation_Time0]		    AS [ADObjectCreationTime]
            ,[CloudUserId]					    AS [CloudUserId]
            ,[Creation_Date0]					AS [Creation_Date]
            ,[Full_User_Name0]					AS [displayName]
            ,[Distinguished_Name0]			    AS [DistinguishedName]
            ,[$attrCostcenter]			        AS [$attrCostcenter]
            ,[$attrMCostcenters]			    AS [$attrMCostcenters]
            ,[Full_Domain_Name0]				AS [FullDomainName]
            ,[Full_User_Name0]				    AS [FullUserName]
            ,[givenName]						AS [givenName]
            ,[Mail0]							AS [Mail]
            ,[Name0]							AS [Name]
            ,[Network_Operating_System0]		AS [Network_Operating_System]
            ,[Object_GUID0]					    AS [ObjectGUID]
            ,[Primary_Group_ID0]				AS [Primary_Group_ID]
            ,[SID0]							    AS [SID]
            ,[sn]								AS [sn]
            ,[Unique_User_Name0]				AS [UniqueUserName]
            ,[User_Account_Control0]			AS [UserAccountControl]
            ,[User_Name0]						AS [UserName]
            ,[User_Principal_Name0]			    AS [UserPrincipalName]
            ,[Windows_NT_Domain0]				AS [WindowsNTDomain]
            ,Substring(
				(
					SELECT
						';' + User_Group_Name0
					FROM
						[v_RA_User_UserGroupName] AS group_membership
					LEFT JOIN
						[dbo].[v_R_UserGroup] AS groups
					ON 
						group_membership.User_Group_Name0 = groups.Name0
					LEFT JOIN
						[dbo].[v_R_User] AS users
					ON 
						group_membership.ResourceID = users.ResourceID
					WHERE
						users.ResourceID = [user].ResourceID
					FOR XML PATH ('')
				),2,10000000)                   AS UserGroupName
        FROM
            v_R_User AS [user]
        WHERE
            [user].Distinguished_Name0 = @distinguishedName
    "
    
    if(
        !($Data.Auth.User.DistinguishedName) -or
        !($AuthenticatedUser = Invoke-scupCCMSqlQuery -Query $userQuery -Parameters @{ distinguishedName = ($Data.Auth.User.DistinguishedName) })
    ){
        $AuthenticatedUser = $null
    }else{
        $AuthenticatedUser | Add-Member –MemberType NoteProperty –Name "UserGroupName" –Value (([string]$AuthenticatedUser.UserGroupName).Split(";")) -Force
    }
    
    return $AuthenticatedUser
}

function Get-scupPSManagedCostCenters($Data){
    $authenticatedUser = Get-scupPSAuthUser($Data)
    $managedCostCenters = $null
    if(
        ($managedCostCenters = $authenticatedUser.$(Get-scupPSValue -Name "Attribute_managedcostCenters")) -and
        ($managedCostCenters -ne "") -and
        ($managedCostCenters -ne "#")    
    ){
        $managedCostCenters = $managedCostCenters.Split(";")
    }else{
        $managedCostCenters = $null
    }

    return $managedCostCenters
}