﻿CREATE PROCEDURE [metadata].[ExecutePrecursorProcedure]
AS
BEGIN
	DECLARE @SQL VARCHAR(MAX) 
	DECLARE @ErrorDetail NVARCHAR(MAX)

	IF OBJECT_ID([metadata].[GetPropertyValueInternal]('ExecutionPrecursorProc')) IS NOT NULL
		BEGIN
			BEGIN TRY
				SET @SQL = [metadata].[GetPropertyValueInternal]('ExecutionPrecursorProc');
				EXEC(@SQL);
			END TRY
			BEGIN CATCH
				SELECT
					@ErrorDetail = 'Precursor procedure failed with error: ' + ERROR_MESSAGE();

				RAISERROR(@ErrorDetail,16,1);
			END CATCH
		END;
	ELSE
		BEGIN
			PRINT 'Precursor object not found in database.';
		END;
END;