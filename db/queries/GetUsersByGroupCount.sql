SELECT
    COUNT([users].[Unique_User_Name0])
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