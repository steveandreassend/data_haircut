set lines 400 pages 10000

col owner FORMAT A30
col table_owner FORMAT A30
col index_owner FORMAT A30
col table_name FORMAT A30
col index_name FORMAT A30
col tablespace_name FORMAT A30
col segment_name FORMAT A30
col segment_type FORMAT A30
col compression FORMAT A30
col size_in_gb FORMAT 999,999,999,999.00

PROMPT Report large tables 1GB+
SELECT a.owner,
b.table_name,
a.tablespace_name,
a.segment_name,
a.segment_type,
b.compression,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_tables b
WHERE a.segment_type = 'TABLE'
AND a.owner = b.owner
AND a.segment_name = b.table_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.table_name, a.tablespace_name, a.segment_name, a.segment_type, b.compression
HAVING ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) >= 1
ORDER BY 1,2,3,4,5;

PROMPT Report large indexes on tables 1GB+ (Regular and GLOBAL indexes on partitioned tables)
SELECT a.owner,
b.index_name,
a.tablespace_name,
a.segment_name,
a.segment_type,
b.compression,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_indexes b
WHERE a.segment_type = 'INDEX'
AND a.owner = b.owner
AND a.segment_name = b.index_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N')
and (b.table_owner, b.table_name) IN (
  SELECT c.owner, d.table_name
  FROM dba_segments c, dba_tables d
  WHERE c.segment_type IN ('TABLE','TABLE PARTITION','TABLE SUBPARTITION')
  AND c.owner = d.owner
  AND c.segment_name = d.table_name
  and c.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
  GROUP BY c.owner, d.table_name
  HAVING SUM(c.bytes) / (1024 * 1024 * 1024) >= 1
)
GROUP BY a.owner, b.index_name, a.tablespace_name, a.segment_name, a.segment_type, b.compression
ORDER BY 1,2,3,4,5;
