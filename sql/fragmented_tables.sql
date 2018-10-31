SELECT TABLE_SCHEMA,
       TABLE_NAME,
       CONCAT(ROUND(DATA_LENGTH / ( 1024 * 1024 ), 2), 'MB') DATA,
       CONCAT(ROUND(DATA_FREE  / ( 1024 * 1024 ), 2), 'MB') FREE
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_SCHEMA = 'fistdb'
ORDER BY DATA_FREE DESC
;
