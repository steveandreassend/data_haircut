SET LINES 400 PAGES 1000
set serveroutput on

PROMPT Create a new table to sample the data

/* C_CDRS	P20231029	AAX2_CDR_TAB_2023_10 */

CREATE TABLE AAX2BSW.COPY_C_CDRS TABLESPACE USERS AS
  SELECT * FROM AAX2BSW.C_CDRS PARTITION (P20231029);

/* C_CDRS_BODY P20231001 AAX2_CDR_TAB_2023_10
C_CDRS_BODY	P20231008	AAX2_CDR_TAB_2023_10
C_CDRS_BODY	P20231015	AAX2_CDR_TAB_2023_10
C_CDRS_BODY	P20231022	AAX2_CDR_TAB_2023_10
C_CDRS_BODY	P20231029	AAX2_CDR_TAB_2023_10
*/
CREATE TABLE AAX2BSW.COPY_C_CDRS_BODY TABLESPACE USERS  AS
  SELECT * FROM AAX2BSW.C_CDRS_BODY PARTITION (P20231001)
  UNION
  SELECT * FROM AAX2BSW.C_CDRS_BODY PARTITION (P20231008)
  UNION
  SELECT * FROM AAX2BSW.C_CDRS_BODY PARTITION (P20231008)
  UNION
  SELECT * FROM AAX2BSW.C_CDRS_BODY PARTITION (P20231015)
  UNION
  SELECT * FROM AAX2BSW.C_CDRS_BODY PARTITION (P20231022)  
  UNION
  SELECT * FROM AAX2BSW.C_CDRS_BODY PARTITION (P20231029);

/* D_TOLL_OBJECT_USAGE P20231001	AAX2_CDR_TAB_2023_10 */
CREATE TABLE AAX2BSW.COPY_D_TOLL_OBJECT_USAGE TABLESPACE USERS AS
  SELECT * FROM AAX2BSW.D_TOLL_OBJECT_USAGE PARTITION (P20231001);

/* create indexes
SQL> select table_name, index_name, column_name, COLUMN_POSITION FROM DBA_IND_COLUMNS WHERE table_name IN ('C_CDRS','C_CDRS_BODY','D_TOLL_OBJECT_USAGE') ORDER BY 1,2, 4;

TABLE_NAME                               INDEX_NAME                                         COLUMN_NAME                              COLUMN_POSITION
---------------------------------------- -------------------------------------------------- ---------------------------------------- ---------------
C_CDRS                                   C_CDRS1$$ID                                        ID                                                     1
C_CDRS                                   C_CDRS1$DUPLICATE_CDR                              CDR_ID                                                 1
C_CDRS                                   C_CDRS1$DUPLICATE_CHECK                            CDR_ID                                                 1
C_CDRS                                   C_CDRS1$DUPLICATE_CHECK                            OBU_ID                                                 2
C_CDRS                                   C_CDRS1$DUPLICATE_CHECK                            FIRST_TIME_OF_TOLL_OBJ_DET_TS                          3
C_CDRS                                   C_CDRS1$DUPLICATE_OBU                              OBU_ID                                                 1
C_CDRS_BODY                              C_CDRS_BODY1$$ID                                   ID                                                     1
C_CDRS_BODY                              C_CDRS_BODY1$$TOLLUSAGE                            TOLL_USAGE                                             1
C_CDRS_BODY                              C_CDRS_BODY1$CDR_RAW_ID                            CDR_RAW_ID                                             1
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAG1$REGION_OBU                     REGION                                                 1
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAG1$REGION_OBU                     OBU                                                    2
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE$TOU_ID                         TOU_ID                                                 1
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE$US_AM                          USAGE                                                  1
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE$US_AM                          AMOUNT                                                 2
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE1$$ID                           ID                                                     1
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE1$$OBU                          EXIT_TIME                                              1
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE1$$OBU                          OBU                                                    2
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE1$$OBU                          SYS_NC00016$                                           3
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE1$ENTITY                        ENTITY                                                 1
D_TOLL_OBJECT_USAGE                      D_TOLL_OBJECT_USAGE1$USAGE                         USAGE                                                  1

20 rows selected. 

*/
-- Index on C_CDRS table
CREATE INDEX AAX2BSW.COPY_C_CDRS1$$ID ON AAX2BSW.COPY_C_CDRS (ID) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_C_CDRS1$DUPLICATE_CDR ON AAX2BSW.COPY_C_CDRS (CDR_ID) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_C_CDRS1$DUPLICATE_CHECK ON AAX2BSW.COPY_C_CDRS (CDR_ID, OBU_ID, FIRST_TIME_OF_TOLL_OBJ_DET_TS) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_C_CDRS1$DUPLICATE_OBU ON AAX2BSW.COPY_C_CDRS (OBU_ID) TABLESPACE USERS;

-- Index on C_CDRS_BODY table
CREATE INDEX AAX2BSW.COPY_C_CDRS_BODY1$$ID ON AAX2BSW.COPY_C_CDRS_BODY (ID) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_C_CDRS_BODY1$$TOLLUSAGE ON AAX2BSW.COPY_C_CDRS_BODY (TOLL_USAGE) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_C_CDRS_BODY1$CDR_RAW_ID ON AAX2BSW.COPY_C_CDRS_BODY (CDR_RAW_ID) TABLESPACE USERS;

-- Index on D_TOLL_OBJECT_USAGE table
CREATE INDEX AAX2BSW.COPY_D_TOLL_OBJECT_USAG1$REGION_OBU ON AAX2BSW.COPY_D_TOLL_OBJECT_USAGE (REGION, OBU) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_D_TOLL_OBJECT_USAGE$TOU_ID ON AAX2BSW.COPY_D_TOLL_OBJECT_USAGE (TOU_ID) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_D_TOLL_OBJECT_USAGE$US_AM ON AAX2BSW.COPY_D_TOLL_OBJECT_USAGE (USAGE, AMOUNT) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_D_TOLL_OBJECT_USAGE1$$ID ON AAX2BSW.COPY_D_TOLL_OBJECT_USAGE (ID) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_D_TOLL_OBJECT_USAGE1$$OBU ON AAX2BSW.COPY_D_TOLL_OBJECT_USAGE (EXIT_TIME, OBU, SYS_NC00016$) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_D_TOLL_OBJECT_USAGE1$ENTITY ON AAX2BSW.COPY_D_TOLL_OBJECT_USAGE (ENTITY) TABLESPACE USERS;
CREATE INDEX AAX2BSW.COPY_D_TOLL_OBJECT_USAGE1$USAGE ON AAX2BSW.COPY_D_TOLL_OBJECT_USAGE (USAGE) TABLESPACE USERS;

PROMPT Reporting table compression...

DECLARE
  l_blkcnt_cmp     PLS_INTEGER;
  l_blkcnt_uncmp   PLS_INTEGER;
  l_row_cmp        PLS_INTEGER;
  l_row_uncmp       PLS_INTEGER;
  l_cmp_ratio      NUMBER;
  l_comptype_str   VARCHAR2(32767);
  l_scratchtbsname varchar2(256) := 'USERS';

  l_numbers CONSTANT SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(
    DBMS_COMPRESSION.COMP_ADVANCED,
    /* Compression Advisor does not require Exadata to validate HCC ratios */
    DBMS_COMPRESSION.COMP_QUERY_LOW,
    DBMS_COMPRESSION.COMP_QUERY_HIGH,
    DBMS_COMPRESSION.COMP_ARCHIVE_LOW,
    DBMS_COMPRESSION.COMP_ARCHIVE_HIGH
  );

BEGIN
/* find all tables larger than 1GB that are partitioned, and get the largest partition */
  FOR x IN (
    SELECT owner, table_name, partition_name, segment_name, segment_type
    FROM (
      SELECT a.owner, b.table_name, a.partition_name, a.segment_name, a.segment_type,
      ROW_NUMBER() OVER (PARTITION BY b.table_name ORDER BY SUM(a.bytes) / (1024 * 1024 * 1024) DESC) AS rn
      FROM dba_segments a, dba_tab_partitions b, dba_tablespaces c
      WHERE a.segment_type IN ('TABLE PARTITION','TABLE SUBPARTITION')
      AND c.tablespace_name = a.tablespace_name
      AND a.owner = b.table_owner
      AND a.segment_name = b.table_name
      AND a.partition_name = b.partition_name
      AND b.table_name IN ('COPY_C_CDRS','COPY_C_CDRS_BODY','COPY_D_TOLL_OBJECT_USAGE') /* specify your table names */
      AND a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
      GROUP BY a.owner, b.table_name, a.partition_name, a.segment_name, a.segment_type
      HAVING ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) >= 1
    )
    WHERE rn = 1
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(chr(13)||chr(10)||'Object = ' || x.owner || '.' || x.table_name||'.'||x.partition_name);
    FOR i IN 1..l_numbers.COUNT LOOP
      -- Loop through different compression types
      DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
        scratchtbsname => l_scratchtbsname,
        ownname        => x.owner,
        objname        => x.table_name,
        subobjname     => x.partition_name,
        comptype       => l_numbers(i),
        blkcnt_cmp     => l_blkcnt_cmp,
        blkcnt_uncmp   => l_blkcnt_uncmp,
        row_cmp        => l_row_cmp,
        row_uncmp      => l_row_uncmp,
        cmp_ratio      => l_cmp_ratio,  
        comptype_str   => l_comptype_str,
        subset_numrows => DBMS_COMPRESSION.COMP_RATIO_MINROWS, /* 1000000 rows sampled | for all rows use: DBMS_COMPRESSION.COMP_RATIO_ALLROWS */
        objtype        => DBMS_COMPRESSION.objtype_table
      );

      -- Display compression information for each compression type
      DBMS_OUTPUT.PUT_LINE('Estimated Compression Ratio of Sample                           : ' || l_cmp_ratio);
      DBMS_OUTPUT.PUT_LINE('Compression Ratio                                               : ' || LTRIM(TO_CHAR(l_blkcnt_uncmp/l_blkcnt_cmp,'999,999,999.00'))||' to 1');
      DBMS_OUTPUT.PUT_LINE('Compression Type                                                : ' || l_comptype_str||' '||l_numbers(i));
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the compressed sample of the object    : ' || l_blkcnt_cmp);
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the uncompressed sample of the object  : ' || l_blkcnt_uncmp);
      DBMS_OUTPUT.put_line('Number of rows in a block in compressed sample of the object    : ' || l_row_cmp);
      DBMS_OUTPUT.put_line('Number of rows in a block in uncompressed sample of the object  : ' || l_row_uncmp);
    END LOOP;  
  END LOOP;
END;
/

/* alternate way to do all index types together
  
DECLARE
  l_index_cr      DBMS_COMPRESSION.compreclist;
  l_comptype_str  VARCHAR2(32767);
BEGIN
  DBMS_COMPRESSION.get_compression_ratio (
    scratchtbsname  => 'USERS',
    ownname         => 'ADMIN',
    tabname         => 'C_CDRS',
    comptype        => DBMS_COMPRESSION.comp_index_advanced_low,
    index_cr        => l_index_cr,
    comptype_str    => l_comptype_str,
    subset_numrows  => DBMS_COMPRESSION.comp_ratio_lob_maxrows
  );

  FOR i IN l_index_cr.FIRST .. l_index_cr.LAST LOOP
    DBMS_OUTPUT.put_line('----');
    DBMS_OUTPUT.put_line('ownname      : ' || l_index_cr(i).ownname);
    DBMS_OUTPUT.put_line('objname      : ' || l_index_cr(i).objname);
    DBMS_OUTPUT.put_line('blkcnt_cmp   : ' || l_index_cr(i).blkcnt_cmp);
    DBMS_OUTPUT.put_line('blkcnt_uncmp : ' || l_index_cr(i).blkcnt_uncmp);
    DBMS_OUTPUT.put_line('row_cmp      : ' || l_index_cr(i).row_cmp);
    DBMS_OUTPUT.put_line('row_uncmp    : ' || l_index_cr(i).row_uncmp);
    DBMS_OUTPUT.put_line('cmp_ratio    : ' || l_index_cr(i).cmp_ratio);
    DBMS_OUTPUT.put_line('objtype      : ' || l_index_cr(i).objtype);
  END LOOP;
END;
/
*/

PROMPT Reporting partitioned indexes...

DECLARE
  l_blkcnt_cmp     PLS_INTEGER;
  l_blkcnt_uncmp   PLS_INTEGER;
  l_row_cmp        PLS_INTEGER;
  l_row_uncmp       PLS_INTEGER;
  l_cmp_ratio      NUMBER;
  l_comptype_str   VARCHAR2(32767);
  l_scratchtbsname varchar2(256) := 'USERS';

  l_numbers CONSTANT SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(
    DBMS_COMPRESSION.comp_index_advanced_low,
    DBMS_COMPRESSION.comp_index_advanced_high
  );

BEGIN
/* find all partitioned indexes and get the largest partition */
  FOR x IN (
    SELECT owner, table_owner, table_name, index_name, partition_name, segment_name, segment_type
    FROM (
      SELECT a.owner, d.table_owner, d.table_name, b.index_name, a.partition_name, a.segment_name, a.segment_type,
      ROW_NUMBER() OVER (PARTITION BY b.index_name ORDER BY SUM(a.bytes) / (1024 * 1024 * 1024) DESC) AS rn
      FROM dba_segments a, dba_ind_partitions b, dba_tablespaces c, dba_indexes d
      WHERE a.segment_type IN ('INDEX PARTITION','INDEX SUBPARTITION')
      AND d.owner = b.index_owner
      AND d.index_name = b.index_name
      AND c.tablespace_name = a.tablespace_name
      AND a.owner = b.index_owner
      AND a.segment_name = b.index_name
      AND a.partition_name = b.partition_name
      AND d.table_name IN ('COPY_C_CDRS','COPY_C_CDRS_BODY','COPY_D_TOLL_OBJECT_USAGE') /* specify your table names */
      AND a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
      GROUP BY a.owner, d.table_owner, d.table_name, b.index_name, a.partition_name, a.segment_name, a.segment_type
    )
    WHERE rn = 1
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(chr(13)||chr(10)||'Object = Table '|| x.table_owner ||'.'|| x.table_name||' Index '|| x.owner || '.' || x.index_name || '.' || x.partition_name );

    FOR i IN 1..l_numbers.COUNT LOOP
      -- Loop through different compression types
      DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
        scratchtbsname => l_scratchtbsname,
        ownname        => x.owner,
        objname        => x.index_name,
        subobjname     => x.partition_name,
        comptype       => l_numbers(i),
        blkcnt_cmp     => l_blkcnt_cmp,
        blkcnt_uncmp   => l_blkcnt_uncmp,
        row_cmp        => l_row_cmp,
        row_uncmp      => l_row_uncmp,
        cmp_ratio      => l_cmp_ratio,  
        comptype_str   => l_comptype_str,
        subset_numrows => DBMS_COMPRESSION.COMP_RATIO_MINROWS, /* 1000000 rows sampled | for all rows use: DBMS_COMPRESSION.COMP_RATIO_ALLROWS */
        objtype        => DBMS_COMPRESSION.objtype_index
      );

      -- Display compression information for each compression type
      DBMS_OUTPUT.PUT_LINE('Estimated Compression Ratio of Sample                           : ' || l_cmp_ratio);
      DBMS_OUTPUT.PUT_LINE('Compression Ratio                                               : ' || LTRIM(TO_CHAR(l_blkcnt_uncmp/l_blkcnt_cmp,'999,999,999.00'))||' to 1');
      DBMS_OUTPUT.PUT_LINE('Compression Type                                                : ' || l_comptype_str||' '||l_numbers(i));
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the compressed sample of the object    : ' || l_blkcnt_cmp);
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the uncompressed sample of the object  : ' || l_blkcnt_uncmp);
      DBMS_OUTPUT.put_line('Number of rows in a block in compressed sample of the object    : ' || l_row_cmp);
      DBMS_OUTPUT.put_line('Number of rows in a block in uncompressed sample of the object  : ' || l_row_uncmp);

    END LOOP;
  END LOOP;
END;
/

PROMPT Reporting non-partitioned indexes...

DECLARE
  l_blkcnt_cmp     PLS_INTEGER;
  l_blkcnt_uncmp   PLS_INTEGER;
  l_row_cmp        PLS_INTEGER;
  l_row_uncmp       PLS_INTEGER;
  l_cmp_ratio      NUMBER;
  l_comptype_str   VARCHAR2(32767);
  l_scratchtbsname varchar2(256) := 'USERS';

  l_numbers CONSTANT SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(
    DBMS_COMPRESSION.comp_index_advanced_low,
    DBMS_COMPRESSION.comp_index_advanced_high
  );

BEGIN
/* find all non-partitioned indexes */
  FOR x IN (
    SELECT owner, table_owner, table_name, index_name, partition_name, segment_name, segment_type
    FROM (
      SELECT a.owner, d.table_owner, d.table_name, d.index_name, a.segment_name, a.segment_type,
      ROW_NUMBER() OVER (PARTITION BY d.index_name ORDER BY SUM(a.bytes) / (1024 * 1024 * 1024) DESC) AS rn
      FROM dba_segments a, dba_tablespaces c, dba_indexes d
      WHERE a.segment_type IN ('INDEX')
      AND c.tablespace_name = a.tablespace_name
      AND a.owner = d.owner
      AND a.segment_name = d.index_name
      AND d.table_name IN ('COPY_C_CDRS','COPY_C_CDRS_BODY','COPY_D_TOLL_OBJECT_USAGE') /* specify your table names */
      AND a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
      GROUP BY a.owner, d.table_owner, d.table_name, d.index_name, a.segment_name, a.segment_type
    )
    WHERE rn = 1
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(chr(13)||chr(10)||'Object = Table '|| x.table_owner ||'.'|| x.table_name||' Index '|| x.owner || '.' || x.index_name || '.' || x.partition_name );

    FOR i IN 1..l_numbers.COUNT LOOP
      -- Loop through different compression types
      DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
        scratchtbsname => l_scratchtbsname,
        ownname        => x.owner,
        objname        => x.index_name,
        subobjname     => NULL,
        comptype       => l_numbers(i),
        blkcnt_cmp     => l_blkcnt_cmp,
        blkcnt_uncmp   => l_blkcnt_uncmp,
        row_cmp        => l_row_cmp,
        row_uncmp      => l_row_uncmp,
        cmp_ratio      => l_cmp_ratio,  
        comptype_str   => l_comptype_str,
        subset_numrows => DBMS_COMPRESSION.COMP_RATIO_MINROWS, /* 1000000 rows sampled | for all rows use: DBMS_COMPRESSION.COMP_RATIO_ALLROWS */
        objtype        => DBMS_COMPRESSION.objtype_index
      );

      -- Display compression information for each compression type
      DBMS_OUTPUT.PUT_LINE('Estimated Compression Ratio of Sample                           : ' || l_cmp_ratio);
      DBMS_OUTPUT.PUT_LINE('Compression Ratio                                               : ' || LTRIM(TO_CHAR(l_blkcnt_uncmp/l_blkcnt_cmp,'999,999,999.00'))||' to 1');
      DBMS_OUTPUT.PUT_LINE('Compression Type                                                : ' || l_comptype_str||' '||l_numbers(i));
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the compressed sample of the object    : ' || l_blkcnt_cmp);
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the uncompressed sample of the object  : ' || l_blkcnt_uncmp);
      DBMS_OUTPUT.put_line('Number of rows in a block in compressed sample of the object    : ' || l_row_cmp);
      DBMS_OUTPUT.put_line('Number of rows in a block in uncompressed sample of the object  : ' || l_row_uncmp);

    END LOOP;
  END LOOP;
END;
/
