SELECT
    [users].Full_User_Name0             AS user_displayname,
	[users].mail0                       AS user_mail,   
    value                               AS user_managedCostcenter
FROM
    [dbo].[v_R_User] AS users
    CROSS APPLY STRING_SPLIT([users].#Attribute_managedcostCenters#, ';')