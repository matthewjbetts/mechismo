# http://www.mysqlperformanceblog.com/2008/02/04/finding-out-largest-tables-on-mysql-server/

SELECT CONCAT(TABLE_SCHEMA, '.', TABLE_NAME)                                          table_name,
       CONCAT(ROUND(TABLE_ROWS / 1000000, 2), 'M')                                    rows,
       CONCAT(ROUND(DATA_LENGTH / ( 1024 * 1024 * 1024 ), 2), 'G')                    data,
       CONCAT(ROUND(INDEX_LENGTH / ( 1024 * 1024 * 1024 ), 2), 'G')                   idx,
       CONCAT(ROUND((DATA_LENGTH + INDEX_LENGTH) / ( 1024 * 1024 * 1024 ), 2), 'G')   total_size,
       ROUND(INDEX_LENGTH / DATA_LENGTH, 2)                                           idxfrac
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_SCHEMA = DATABASE()
ORDER  BY DATA_LENGTH + INDEX_LENGTH DESC
;
