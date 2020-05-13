CREATE TABLE [dbo].[costcenterManagers](
	[relation_id] [nchar](150) NOT NULL,
	[relation_costcenter_id] [nchar](150) NOT NULL,
	[relation_costcenter_mSID] [nchar](150) NOT NULL,
	[relation_created] [datetime] NULL,
	[relation_modified] [datetime] NULL,
    CONSTRAINT [PK_costcenterManagers] PRIMARY KEY CLUSTERED 
    (
        [relation_id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA] 
GO

ALTER TABLE [dbo].[costcenterManagers]
ADD FOREIGN KEY (relation_costcenter_mSID) REFERENCES users(SID);
GO

ALTER TABLE [dbo].[costcenters]
ADD PRIMARY KEY (costcenter_id);
GO

ALTER TABLE [dbo].[costcenterManagers]
ADD FOREIGN KEY (relation_costcenter_id) REFERENCES costcenters(costcenter_id);
GO

UPDATE [dbo].[db] SET "db_value"=11 WHERE "db_name" = 'db_version'
GO