SELECT    
		users.full_user_name0					AS user_displayname, 
		users.mail0								AS user_mail,         
		users.#Attribute_costCenter#			AS user_costcenter
FROM
	[dbo].[v_R_User]							AS users
WHERE
        users.#Attribute_costCenter# IS NOT NULL