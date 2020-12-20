SELECT
    COUNT([CI_ID])
  FROM vSMS_R_System as s
  INNER JOIN [vAppDeploymentResultsPerClient] as r ON r.ResourceID = s.ItemKey
  INNER JOIN vCollections as c ON c.SiteID = r.TargetCollectionID
  WHERE
	s.Name0 = @ClientName