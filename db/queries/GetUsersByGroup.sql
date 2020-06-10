SELECT
    [users].[Full_User_Name0]				AS [user_displayname]
    ,[users].[Mail0]						AS [user_mail]
    ,[users].[Unique_User_Name0]			AS [user_netbiosName]
    ,[users].[User_Name0]					AS [user_username]
    ,[users].[User_Principal_Name0]			AS [user_userPrincipalName]
    ,[users].[Windows_NT_Domain0]			AS [user_NTdomain]
	,[groups].Name0							AS [group_name]
FROM
	v_R_User AS [users]

LEFT JOIN
	[v_RA_User_UserGroupName] AS group_membership
ON
	group_membership.ResourceID = users.ResourceID
LEFT JOIN
	[dbo].[v_R_UserGroup] AS groups
ON
	group_membership.User_Group_Name0 = groups.Name0
WHERE
	[groups].Name0 = @groupName