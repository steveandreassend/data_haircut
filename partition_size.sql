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

col owner FORMAT A30
col table_owner FORMAT A30
col index_owner FORMAT A30
col table_name FORMAT A30
col index_name FORMAT A30
col partition_name FORMAT A30
col tablespace_name FORMAT A30
col segment_name FORMAT A30
col segment_type FORMAT A30
col size_in_gb FORMAT 999,999,999,999.00
col num_tablespaces FORMAT 999,999,999,999
col num_partitions FORMAT 999,999,999,999

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

/* DROP DEMO DATA

DROP TABLE SALES;
DROP TABLE PRODUCTS;

*/
