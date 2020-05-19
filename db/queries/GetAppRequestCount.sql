SELECT    
		  COUNT(requests.RequestGuid)
FROM      v_userapprequests          AS requests 
LEFT JOIN 
		( 
					SELECT    
							[apps].[ModelID]                                AS app_modelid, 
							[localizedproperties].[Publisher]               AS app_manufacturer, 
							[localizedproperties].[Title]                   AS app_title, 
							[localizedproperties].[Description]             AS app_description 
					FROM      fn_listlatestapplicationcis(1033)             AS apps 
					LEFT JOIN fn_localizedappproperties(1033)               AS localizedproperties 
					ON        apps.ci_id = localizedproperties.ci_id )      AS apps 
ON        apps.app_modelid = requests.modelid 
LEFT JOIN [dbo].[v_R_User] AS users 
ON        users.sid0 = requests.sid0 
WHERE     requests.unique_user_name0 != 'None' 
