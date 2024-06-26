﻿--Run in SQLCMD mode to use environment variables.

--Optional script used to setup function testing for processing framework parts post deployment.

PRINT 'TenantId: ' + '$(AZURE_TENANT_ID)'
PRINT 'SubscriptionId: ' + '$(AZURE_SUBSCRIPTION_ID)'

--add my tenant
INSERT INTO [metadata].[Tenants]
	(
	[TenantId],
	[Name],
	[Description]
	)
VALUES
	('$(AZURE_TENANT_ID)', 'mrpaulandrew.com', NULL);

--add my subscription
INSERT INTO [metadata].[Subscriptions]
	(
	[SubscriptionId],
	[Name],
	[Description],
	[TenantId]
	)
VALUES
	('$(AZURE_SUBSCRIPTION_ID)', 'Microsoft Sponsored Subscription', NULL, '$(AZURE_TENANT_ID)');

--update Orchestrator with new subscription
UPDATE
	[metadata].[Orchestrators]
SET
	[SubscriptionId] = '$(AZURE_SUBSCRIPTION_ID)';

--remove default values
DELETE FROM [metadata].[Subscriptions] WHERE [SubscriptionId] = '12345678-1234-1234-1234-012345678910';
DELETE FROM [metadata].[Tenants] WHERE [TenantId] = '12345678-1234-1234-1234-012345678910';

/*
EXEC [metadataHelpers].[AddProperty]
	@PropertyName = N'SPNHandlingMethod',
	@PropertyValue = N'StoreInKeyVault',
	@Description = N'Accepted values: StoreInDatabase, StoreInKeyVault. See v1.8.2 release notes for full details.';
*/

IF (SELECT [metadata].[GetPropertyValueInternal]('SPNHandlingMethod')) = 'StoreInDatabase'
	BEGIN
		--Add SPN for execution of all worker pipelines using database to store SPN values
		EXEC [metadataHelpers].[AddServicePrincipalWrapper]
			@OrchestratorName = N'FrameworkFactory',
			@OrchestratorType = 'ADF',
			@PrincipalIdValue = '$(AZURE_CLIENT_ID)',
			@PrincipalSecretValue = '$(AZURE_CLIENT_SECRET)',
			@PrincipalName = '$(AZURE_CLIENT_NAME)';
		
		EXEC [metadataHelpers].[AddServicePrincipalWrapper]
			@OrchestratorName = N'metadataforsynapse',
			@OrchestratorType = 'SYN',
			@PrincipalIdValue = '$(AZURE_CLIENT_ID)',
			@PrincipalSecretValue = '$(AZURE_CLIENT_SECRET)',
			@PrincipalName = '$(AZURE_CLIENT_NAME)';

		/*
		--Add specific SPN for execution of Wait 1 pipeline (functional testing)	
		EXEC [metadataHelpers].[DeleteServicePrincipal]
			@OrchestratorName = N'FrameworkFactory',
			@OrchestratorType = 'ADF',
			@PrincipalIdValue = '$(AZURE_CLIENT_ID)',
			@SpecificPipelineName = N'Wait 1';

		EXEC [metadataHelpers].[AddServicePrincipalWrapper]
			@OrchestratorName = N'FrameworkFactory',
			@OrchestratorType = 'ADF',
			@PrincipalIdValue = '$(AZURE_CLIENT_ID_2)',
			@PrincipalSecretValue = '$(AZURE_CLIENT_SECRET_2)',
			@PrincipalName = '$(AZURE_CLIENT_NAME_2)',
			@SpecificPipelineName = N'Wait 1';
		*/
	END
ELSE IF (SELECT [metadata].[GetPropertyValueInternal]('SPNHandlingMethod')) = 'StoreInKeyVault'
	BEGIN
		--Add SPN for execution of all worker pipelines using database to store key vault URLs
		EXEC [metadataHelpers].[AddServicePrincipalWrapper]
			@OrchestratorName = N'FrameworkFactory',
			@OrchestratorType = 'ADF',
			@PrincipalIdValue = '$(AZURE_CLIENT_ID_URL)',
			@PrincipalSecretValue = '$(AZURE_CLIENT_SECRET_URL)',
			@PrincipalName = '$(AZURE_CLIENT_NAME)';
	END
ELSE
	BEGIN
		RAISERROR('Unknown SPN insert method.',16,1);
	END;

SELECT * FROM [dbo].[ServicePrincipals];