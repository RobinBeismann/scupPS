SELECT
    COUNT(value) 
FROM
    [dbo].[v_R_User] AS users
    CROSS APPLY STRING_SPLIT([users].#Attribute_managedcostCenters#, ';')