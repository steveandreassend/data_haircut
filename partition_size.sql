set lines 400 pages 10000

/* DEMO DATA

PROMPT Create some test tables with range and composite partitioning

CREATE TABLE PRODUCTS (partno NUMBER,
      description VARCHAR(32),
       costprice NUMBER)
  PARTITION BY RANGE (partno)
     SUBPARTITION BY HASH(description)
    SUBPARTITIONS 8
      (PARTITION p1 VALUES LESS THAN (100),
       PARTITION p2 VALUES LESS THAN (200),
       PARTITION p3 VALUES LESS THAN (MAXVALUE));

CREATE INDEX ind_products on PRODUCTS (partno) LOCAL;

INSERT INTO PRODUCTS VALUES (1,1,1);
INSERT INTO PRODUCTS VALUES (101,1,1);
INSERT INTO PRODUCTS VALUES (201,1,1);
COMMIT;

CREATE TABLE SALES (
    sales_id NUMBER,
    sales_date DATE,
    amount NUMBER
)
PARTITION BY RANGE (sales_date) (
    PARTITION sales_q1_2023 VALUES LESS THAN (TO_DATE('2023-04-01', 'YYYY-MM-DD')),
    PARTITION sales_q2_2023 VALUES LESS THAN (TO_DATE('2023-07-01', 'YYYY-MM-DD')),
    PARTITION sales_q3_2023 VALUES LESS THAN (TO_DATE('2023-10-01', 'YYYY-MM-DD')),
    PARTITION sales_q4_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD'))
);

CREATE INDEX ind_SALES on SALES (sales_id) LOCAL;

INSERT INTO SALES VALUES (1,TO_DATE('2023-04-01', 'YYYY-MM-DD')-1,100);
INSERT INTO SALES VALUES (1,TO_DATE('2023-07-01', 'YYYY-MM-DD')-1,100);
INSERT INTO SALES VALUES (1,TO_DATE('2023-10-01', 'YYYY-MM-DD')-1,100);
INSERT INTO SALES VALUES (1,TO_DATE('2024-01-01', 'YYYY-MM-DD')-1,100);
COMMIT;
*/

PROMPT Report large table partitions
SELECT a.owner,
b.table_name,
a.partition_name,
a.tablespace_name,
a.segment_name,
a.segment_type,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_tab_partitions b
WHERE a.segment_type = 'TABLE PARTITION'
AND a.owner = b.table_owner
AND a.segment_name = b.table_name
AND a.partition_name = b.partition_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.table_name, a.partition_name, a.tablespace_name, a.segment_name, a.segment_type
ORDER BY 1,2,3,4,5;

PROMPT Report large index partitions
SELECT a.owner,
b.index_name,
a.partition_name,
a.tablespace_name,
a.segment_name,
a.segment_type,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_ind_partitions b
WHERE a.segment_type = 'INDEX PARTITION'
AND a.owner = b.index_owner
AND a.segment_name = b.index_name
AND a.partition_name = b.partition_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.index_name, a.partition_name, a.tablespace_name, a.segment_name, a.segment_type
ORDER BY 1,2,3,4,5;

PROMPT Report large table subpartitions
SELECT a.owner,
b.table_name,
a.partition_name,
a.tablespace_name,
a.segment_name,
a.segment_type,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_tab_subpartitions b
WHERE a.segment_type = 'TABLE SUBPARTITION'
AND a.owner = b.table_owner
AND a.segment_name = b.table_name
AND a.partition_name = b.subpartition_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.table_name, a.partition_name, a.tablespace_name, a.segment_name, a.segment_type
ORDER BY 1,2,3,4,5;

PROMPT Report large index subpartitions
SELECT a.owner,
b.index_name,
a.partition_name,
a.tablespace_name,
a.segment_name,
a.segment_type,
ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
FROM dba_segments a, dba_ind_subpartitions b
WHERE a.segment_type = 'INDEX SUBPARTITION'
AND a.owner = b.index_owner
AND a.segment_name = b.index_name
AND a.partition_name = b.subpartition_name
and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
GROUP BY a.owner, b.index_name, a.partition_name, a.tablespace_name, a.segment_name, a.segment_type
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

PROMPT Report LOB Segments Storage Size
select s.owner, l.table_name, l.column_name, l.tablespace_name, l.securefile, l.compression, s.segment_name, s.segment_type, ROUND(SUM(s.bytes) / (1024 * 1024 * 1024), 2) AS size_in_gb
from dba_lobs l, dba_segments s
where s.segment_type = 'LOBSEGMENT'
and s.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
AND s.owner = l.owner
and s.segment_name = l.segment_name
group by s.owner, l.table_name, l.column_name, l.tablespace_name, l.securefile, l.compression, s.segment_name, s.segment_type
ORDER BY 1,2,3,4;

PROMPT Exit script here
EXIT;

/*
If a lot of rows have been deleted from LOB tables then fragmentation may be an issue. The following commands explore this.
Otherwise rows are not being deleted, then the LOB Segment Storage Size is indicative of the LOB data size.
*/

PROMPT Determine size of BLOB data
/* SELECT sum(dbms_lob.getlength(<lob column name>)) from <table_name>; */

PROMPT Determine size of CLOB data
/*
  CLOBs use the following note
  How to Return CLOB Size in Bytes like LENGTHB Function of CHAR/VARCHAR2 (Document  790886.1)
*/

PROMPT Determine the storage usage in the LOBSEGMENT using DBMS_SPACE.SPACE_USAGE

SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE check_space_securefile (u_name in varchar2, v_segname varchar2 ) IS
  l_segment_size_blocks NUMBER;
  l_segment_size_bytes NUMBER;
  l_used_blocks NUMBER;
  l_used_bytes NUMBER;
  l_expired_blocks NUMBER;
  l_expired_bytes NUMBER;
  l_unexpired_blocks NUMBER;
  l_unexpired_bytes NUMBER;
  l_unused_blocks NUMBER;
  l_unused_bytes NUMBER;
  l_non_data_blocks NUMBER;
  l_non_data_bytes NUMBER;
BEGIN
  /* NOTE: If the target object is a partitioned lob column then SEGMENT_TYPE should be LOB PARTITION. */
  DBMS_SPACE.SPACE_USAGE(
      segment_owner =>u_name,
      segment_name => v_segname,
      segment_type => 'LOB',
      segment_size_blocks => l_segment_size_blocks,
      segment_size_bytes => l_segment_size_bytes,
      used_blocks => l_used_blocks,
      used_bytes => l_used_bytes,
      expired_blocks => l_expired_blocks,
      expired_bytes => l_expired_bytes,
      unexpired_blocks => l_unexpired_blocks,
      unexpired_bytes => l_unexpired_bytes
  );
  l_unused_blocks := l_segment_size_blocks - (l_used_blocks + l_expired_blocks + l_unexpired_blocks);
  l_unused_bytes := l_segment_size_bytes - (l_used_bytes + l_expired_bytes + l_unexpired_bytes);
  l_non_data_blocks := l_unused_blocks + l_expired_blocks + l_unexpired_blocks;
  l_non_data_bytes :=  l_unused_bytes + l_expired_bytes + l_unexpired_bytes;

  DBMS_OUTPUT.ENABLE;
  DBMS_OUTPUT.PUT_LINE(' Segment Blocks/Bytes   = '||l_segment_size_blocks||' / '||l_segment_size_bytes);
  DBMS_OUTPUT.PUT_LINE(' Unused Blocks/Bytes    = '||l_unused_blocks||' / '||l_unused_bytes);
  DBMS_OUTPUT.PUT_LINE(' Used Blocks/Bytes      = '||l_used_blocks||' / '||l_used_bytes);
  DBMS_OUTPUT.PUT_LINE(' Expired Blocks/Bytes   = '||l_expired_blocks||' / '||l_expired_bytes);
  DBMS_OUTPUT.PUT_LINE(' Unexpired Blocks/Bytes = '||l_unexpired_blocks||' / '||l_unexpired_bytes);
  DBMS_OUTPUT.PUT_LINE('===========================================================================');
  DBMS_OUTPUT.PUT_LINE(' NON Data Blocks/Bytes  = '||l_non_data_blocks||' / '||l_non_data_bytes);
  /*
    if there are many extents smaller than the Non Data Blocks, then it is is a candidate for rebuild:
    SELECT BYTES, COUNT(*)
    FROM DBA_EXTENTS
    WHERE SEGMENT_NAME = 'SYS_LOB0000067626C00002$$'
    GROUP BY BYTES ORDER BY 2;
  */
END;
/

exec check_space_securefile('TEST','SYS_LOB0000067626C00002$$');

/* Example LOB commands

CREATE TABLE print_media
    ( product_id        NUMBER(6),
      ad_id             NUMBER(6),
      ad_sourcetext     CLOB)
    LOB (ad_sourcetext)  STORE AS SECUREFILE (TABLESPACE tbs_2)
    PARTITION BY RANGE(product_id)
    (PARTITION P1 VALUES LESS THAN (1000)
         LOB (ad_sourcetext) STORE AS BASICFILE (TABLESPACE tbs_1),
     PARTITION P2 VALUES LESS THAN (2000)
         LOB (ad_sourcetext) STORE AS (TABLESPACE tbs_2 COMPRESS HIGH),
     PARTITION P3 VALUES LESS THAN (3000));
     
ALTER TABLE print_media ADD PARTITION P4 VALUES LESS THAN (4000)
         LOB (ad_sourcetext) STORE AS SECUREFILE(TABLESPACE tbs_2);

ALTER TABLE print_media MODIFY PARTITION P3 LOB(ad_sourcetext)
     (RETENTION AUTO);

ALTER TABLE print_media MOVE PARTITION P1 LOB(ad_sourcetext)  
    STORE AS (TABLESPACE tbs_3 COMPRESS LOW);

ALTER TABLE print_media SPLIT PARTITION  P1 AT(500) into
(PARTITION P1A LOB(ad_sourcetext) STORE AS (TABLESPACE tbs_1),
PARTITION P1B LOB(ad_sourcetext) STORE AS (TABLESPACE tbs_2)) UPDATE INDEXES;

ALTER TABLE print_media MERGE PARTITIONS P1A, P1B INTO PARTITION P1;

CREATE TABLE print_media_nonpart
    ( product_id NUMBER(6),
      ad_id NUMBER(6),
      ad_sourcetext CLOB)
      LOB (ad_sourcetext) STORE AS SECUREFILE (COMPRESS HIGH);

ALTER TABLE print_media  EXCHANGE PARTITION p1 WITH TABLE print_media_nonpart;

CREATE INDEX ad_sourcetext_idx_sql on print_media (to_char(substr(ad_sourcetext,1,10)))
      GLOBAL;

CREATE INDEX ad_sourcetext_idx_sql on print_media (to_char(substr(ad_sourcetext,1,10)))
      LOCAL;
*/

/* DROP DEMO DATA

DROP TABLE SALES;
DROP TABLE PRODUCTS;

*/
