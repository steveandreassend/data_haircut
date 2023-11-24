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

PROMPT Report large table partitions
SELECT a.owner,
b.table_name,
a.partition_name,
a.tablespace_name,
c.DEF_TAB_COMPRESSION,
c.COMPRESS_FOR,
c.BIGFILE,
c.STATUS,
a.segment_name,
a.segment_type,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_tab_partitions b, dba_tablespaces c
WHERE a.segment_type = 'TABLE PARTITION'
AND c.tablespace_name = a.tablespace_name
AND a.owner = b.table_owner
AND a.segment_name = b.table_name
AND a.partition_name = b.partition_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.table_name, a.partition_name, a.tablespace_name, c.DEF_TAB_COMPRESSION, c.COMPRESS_FOR, c.BIGFILE, c.STATUS, a.segment_name, a.segment_type
ORDER BY 1,2,3,4,5;

PROMPT Report large index partitions
SELECT a.owner,
b.index_name,
a.partition_name,
a.tablespace_name,
c.DEF_TAB_COMPRESSION,
c.COMPRESS_FOR,
c.BIGFILE,
c.STATUS,
a.segment_name,
a.segment_type,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_ind_partitions b, dba_tablespaces c
WHERE a.segment_type = 'INDEX PARTITION'
AND c.tablespace_name = a.tablespace_name
AND a.owner = b.index_owner
AND a.segment_name = b.index_name
AND a.partition_name = b.partition_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.index_name, a.partition_name, a.tablespace_name, c.DEF_TAB_COMPRESSION, c.COMPRESS_FOR, c.BIGFILE, c.STATUS, a.segment_name, a.segment_type
ORDER BY 1,2,3,4,5;

PROMPT Report large table subpartitions
SELECT a.owner,
b.table_name,
a.partition_name,
a.tablespace_name,
c.DEF_TAB_COMPRESSION,
c.COMPRESS_FOR,
c.BIGFILE,
c.STATUS,
a.segment_name,
a.segment_type,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_tab_subpartitions b, dba_tablespaces c
WHERE a.segment_type = 'TABLE SUBPARTITION'
AND c.tablespace_name = a.tablespace_name
AND a.owner = b.table_owner
AND a.segment_name = b.table_name
AND a.partition_name = b.subpartition_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.table_name, a.partition_name, a.tablespace_name, c.DEF_TAB_COMPRESSION, c.COMPRESS_FOR, c.BIGFILE, c.STATUS, a.segment_name, a.segment_type
ORDER BY 1,2,3,4,5;

PROMPT Report large index subpartitions
SELECT a.owner,
b.index_name,
a.partition_name,
a.tablespace_name,
c.DEF_TAB_COMPRESSION,
c.COMPRESS_FOR,
c.BIGFILE,
c.STATUS,
a.segment_name,
a.segment_type,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_ind_subpartitions b, dba_tablespaces c
WHERE a.segment_type = 'INDEX SUBPARTITION'
AND c.tablespace_name = a.tablespace_name
AND a.owner = b.index_owner
AND a.segment_name = b.index_name
AND a.partition_name = b.subpartition_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.index_name, a.partition_name, a.tablespace_name, c.DEF_TAB_COMPRESSION, c.COMPRESS_FOR, c.BIGFILE, c.STATUS, a.segment_name, a.segment_type
ORDER BY 1,2,3,4,5;

PROMPT Report if table partitions share tablespaces
select b.table_owner, b.table_name, count(1) num_partitions, count(distinct b.tablespace_name) num_tablespaces
from dba_tab_partitions b
where b.SUBPARTITION_COUNT = 0
and b.table_owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
group by b.table_owner, b.table_name
order by 1,2;

PROMPT Report if index partitions share tablespaces
select b.index_owner, b.index_name, count(1) num_partitions, count(distinct b.tablespace_name) num_tablespaces
from dba_ind_partitions b
where b.SUBPARTITION_COUNT = 0
and b.index_owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
group by b.index_owner, b.index_name
order by 1,2;

PROMPT Report if table subpartitions share tablespaces
select b.table_owner, b.table_name, b.partition_name, count(1) num_subpartitions, count(distinct b.tablespace_name) num_tablespaces
from dba_tab_subpartitions b
where b.table_owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
group by b.table_owner, b.table_name, b.partition_name
order by 1,2;

PROMPT Report if index subpartitions share tablespaces
select b.index_owner, b.index_name, b.partition_name, count(1) num_subpartitions, count(distinct b.tablespace_name) num_tablespaces
from dba_ind_subpartitions b
where b.index_owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
group by b.index_owner, b.index_name, b.partition_name
order by 1,2;
