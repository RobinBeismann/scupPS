SELECT    
		COUNT(users.ResourceID)
FROM
	[dbo].[v_R_User]							AS users
WHERE
        users.#Attribute_costCenter# IS NOT NULL