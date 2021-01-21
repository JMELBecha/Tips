  DECLARE @tableSchema nvarchar(500)  
	DECLARE @tableName nvarchar(500)   
	DECLARE @indexName nvarchar(500)   
	DECLARE @indexType nvarchar(55)   
	DECLARE @percentFragment decimal(11,2)   
   
	DECLARE FragmentedTableList cursor for   
  
	SELECT s.name as TableSchema, OBJECT_NAME(ind.object_id) AS TableName,   
	ind.name AS IndexName, indexstats.index_type_desc AS IndexType,   
	indexstats.avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats   
	INNER JOIN sys.indexes ind 
		ON ind.object_id = indexstats.object_id   
		AND ind.index_id = indexstats.index_id  
	INNER JOIN sys.objects o
		ON o.object_id = ind.object_id
	INNER JOIN sys.schemas s
		ON s.schema_id = o.schema_id
	WHERE  
	indexstats.avg_fragmentation_in_percent >= 10  
	AND ind.name is not null   
	ORDER BY indexstats.avg_fragmentation_in_percent DESC 
   
	OPEN FragmentedTableList   
	FETCH NEXT FROM FragmentedTableList    
	INTO @tableSchema, @tableName, @indexName, @indexType, @percentFragment   
   
	WHILE @@FETCH_STATUS = 0   
	BEGIN   
		PRINT 'Processing ' + @indexName + ' on table ' + @tableSchema + '.' + @tableName + ' which is ' + cast(@percentFragment as nvarchar(50)) + ' fragmented'   
        
		IF( OBJECT_ID(@tableName) IS NOT NULL)
		BEGIN
			IF(@percentFragment >= 30)  
			BEGIN   
				EXEC( 'ALTER INDEX [' +  @indexName + '] ON [' + @tableSchema + '].[' + @tableName + '] REBUILD; ')   
				PRINT 'Finished reorganizing ' + @indexName + ' on table ' + @tableSchema + '.' + @tableName   
			END   
			ELSE   
			BEGIN  
				EXEC( 'ALTER INDEX [' +  @indexName + '] ON [' + @tableSchema + '].[' + @tableName + '] REORGANIZE;')   
				PRINT 'Finished rebuilding ' + @indexName + ' on table ' +@tableSchema + '.' +  @tableName
			END    
		END

		FETCH NEXT FROM FragmentedTableList    
		INTO @tableSchema, @tableName, @indexName, @indexType, @percentFragment  
	END   
	CLOSE FragmentedTableList   
	DEALLOCATE FragmentedTableList
