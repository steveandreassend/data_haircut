set lines 400 pages 10000

col owner FORMAT A30
col table_owner FORMAT A30
col index_owner FORMAT A30
col table_name FORMAT A30
col index_name FORMAT A30
col partition_name FORMAT A30
col tablespace_name FORMAT A30
col segment_name FORMAT A30
col segment_type FORMAT A30
col DEF_TAB_COMPRESSION FORMAT A16
col COMPRESS_FOR FORMAT A16
col BIGFILE FORMAT A10
col status FORMAT A12
col size_in_gb FORMAT 999,999,999,999.00
col num_tablespaces FORMAT 999,999,999,999
col num_partitions FORMAT 999,999,999,999

PROMPT Report LOB Segments Storage Size

select s.owner, l.table_name, l.column_name, l.tablespace_name, l.securefile, l.compression, s.segment_name, s.segment_type, ROUND(SUM(s.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
from dba_lobs l, dba_segments s
where s.segment_type LIKE '%LOB%'
and s.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
AND s.owner = l.owner
and s.segment_name = l.segment_name
group by s.owner, l.table_name, l.column_name, l.tablespace_name, l.securefile, l.compression, s.segment_name, s.segment_type
ORDER BY 1,2,3,4;
