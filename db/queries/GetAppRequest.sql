SELECT    
		requests.ci_uniqueid          AS request_uniqueid, 
		requests.displayname          AS request_displayname, 
		requests.currentstate         AS request_currentsate, 
		requests.modelid              AS request_modelid, 
		requests.unique_user_name0    AS request_uniquename, 
		requests.sid0                 AS request_usersid, 
		requests.netbios_name0        AS request_machinename, 
		requests.machineresourceid    AS request_machin_id, 
		requests.requestguid          AS request_guid, 
		requests.currentstate         AS request_state, 
		requests.comments             AS request_comments, 
		requests.Id					  AS request_id,
		apps.app_modelname            AS app_modelname, 
		apps.app_modelid              AS app_modelid, 
		apps.app_civersion            AS app_civersion, 
		apps.app_title			      AS app_title, 
		apps.app_issuperseded         AS app_issuperseded, 
		apps.app_issuperseding        AS app_issuperseding, 
		apps.app_manufacturer         AS app_manufacturer, 
		apps.app_version              AS app_version, 
		apps.app_description          AS app_description, 
		apps.app_title_admin          AS app_title_admin, 
		apps.app_description_admin    AS app_description_admin,
		apps.app_icon_hash            AS app_icon_hash,
		apps.app_CI_ID			      AS app_CI_ID, 
		users.full_user_name0         AS user_displayname, 
		users.mail0                   AS user_mail,         
		users.#Attribute_costCenter#         AS user_costcenter,
		users.#Attribute_managedcostCenters# AS user_managedcostcenter

FROM      v_userapprequests             AS requests 
LEFT JOIN 
		( 
					SELECT    
							[apps].[ModelName]                              AS app_modelname, 
							[apps].[ModelID]                                AS app_modelid, 
							[localizedproperties].[CI_ID]                   AS app_CI_ID, 
							[localizedproperties].[Publisher]               AS app_manufacturer, 
							[localizedproperties].[Title]                   AS app_title, 
							[localizedproperties].[Description]             AS app_description, 
							[localizedproperties].[Version]                 AS app_version, 
							[localizedproperties].[LocaleID]                AS app_localeid, 
							BINARY_CHECKSUM([localizedproperties].[Icon])   AS app_icon_hash,
							[localizedproperties].[InfoUrl]                 AS app_infourl, 
							[localizedproperties].[InfoUrlText]             AS app_infourltxt, 
							[localizedproperties].[PrivacyUrl]              AS app_privacyurl, 
							[localizedproperties].[UserCategories]          AS app_usercategories, 
							[apps].[DisplayName]                            AS app_title_admin, 
							[apps].[Description]                            AS app_description_admin, 
							[apps].[IsSuperseded]                           AS app_issuperseded, 
							[apps].[IsSuperseding]                          AS app_issuperseding, 
							[apps].[CIVersion]                              AS app_civersion 
					FROM      fn_listlatestapplicationcis(1033)             AS apps 
					LEFT JOIN fn_localizedappproperties(1033)               AS localizedproperties 
					ON        apps.ci_id = localizedproperties.ci_id )      AS apps 
ON        apps.app_modelid = requests.modelid 
LEFT JOIN [dbo].[v_R_User] AS users 
ON        users.sid0 = requests.sid0 
WHERE     requests.unique_user_name0 != 'None'