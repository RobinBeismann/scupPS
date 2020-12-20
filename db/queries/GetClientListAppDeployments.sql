SELECT [CI_ID]
      ,[TargetCollectionID]
	  ,[CollectionName] AS [TargetCollectionName]
      ,[AssignmentID]
      ,[Descript]
	  ,IIf([EnforcementState]=1001,'Installation Success',
		IIf([EnforcementState]>=1000 And [EnforcementState]<2000 And [EnforcementState]<>1001,'Installation Success',
		IIf([EnforcementState]>=2000 And [EnforcementState]<3000,'In Progress', IIf([EnforcementState]>=3000 And [EnforcementState]<4000,'Requirements Not Met ', IIf([EnforcementState]>=4000 And [EnforcementState]<5000,'Unknown', IIf([EnforcementState]>=5000 And [EnforcementState]<6000,'Error','Unknown')))))) AS Status
      ,[StartTime]
      ,[LastModificationTime]
      ,[ComplianceState]
      ,[OfferTypeID]
      ,[Revision]
  FROM vSMS_R_System as s
  INNER JOIN [vAppDeploymentResultsPerClient] as r ON r.ResourceID = s.ItemKey
  INNER JOIN vCollections as c ON c.SiteID = r.TargetCollectionID
  WHERE
	s.Name0 = @ClientName