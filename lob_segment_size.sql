set lines 400 pages 10000

PROMPT Report LOB Segments Storage Size

select s.owner, l.table_name, l.column_name, l.tablespace_name, l.securefile, l.compression, s.segment_name, s.segment_type, ROUND(SUM(s.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
from dba_lobs l, dba_segments s
where s.segment_type = 'LOBSEGMENT'
and s.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
AND s.owner = l.owner
and s.segment_name = l.segment_name
group by s.owner, l.table_name, l.column_name, l.tablespace_name, l.securefile, l.compression, s.segment_name, s.segment_type
ORDER BY 1,2,3,4;
