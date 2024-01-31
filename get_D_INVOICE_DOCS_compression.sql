SET LINES 400 PAGES 1000
set serveroutput on

PROMPT Reporting table compression...

DECLARE
  l_blkcnt_cmp     PLS_INTEGER;
  l_blkcnt_uncmp   PLS_INTEGER;
  l_row_cmp        PLS_INTEGER;
  l_row_uncmp       PLS_INTEGER;
  l_cmp_ratio      NUMBER;
  l_comptype_str   VARCHAR2(32767);
  l_scratchtbsname varchar2(256) := 'USERS';
  l_tabowner varchar2(256) := 'AAX2DMSSW';
  l_tabname varchar2(256) := 'D_INVOICE_DOCS';

  l_numbers CONSTANT SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(DBMS_COMPRESSION.COMP_ADVANCED,
    /* Compression Advisor does not require Exadata to validate HCC ratios */
    DBMS_COMPRESSION.COMP_QUERY_LOW,
    DBMS_COMPRESSION.COMP_QUERY_HIGH,
    DBMS_COMPRESSION.COMP_ARCHIVE_LOW,
    DBMS_COMPRESSION.COMP_ARCHIVE_HIGH
  );

  l_subpartition_name VARCHAR2(256);

BEGIN
  --there are 24 different document types, each stored in their own partition, and sub-partitioned by date range
/*
PARTITION_NAME
------------------------------
P_INV_DOC_APPBRS
P_INV_DOC_APPFLN
P_INV_DOC_APPSFC
P_INV_DOC_CPO
P_INV_DOC_DTCSV
P_INV_DOC_DTS
P_INV_DOC_DTSCUST
P_INV_DOC_EFNBAG
P_INV_DOC_EFNDE
P_INV_DOC_FIBRS
P_INV_DOC_FIFLN
P_INV_DOC_FILHT
P_INV_DOC_FISFC
P_INV_DOC_MABAG
P_INV_DOC_MADE
P_INV_DOC_RS
P_INV_DOC_SB
P_INV_DOC_SF
P_INV_DOC_SW
P_INV_DOC_TDPOL
P_INV_DOC_TFCSV
P_INV_DOC_TSPOL
P_INV_DOC_VSLHT
P_INV_DOC_WDCSV

24 rows selected. 
*/

  FOR x IN (
    SELECT DISTINCT partition_name
    FROM dba_tab_partitions
    WHERE TABLE_OWNER = l_tabowner
    AND table_name = l_tabname
    ORDER BY 1
  ) LOOP

    /* get the largest subpartition for the give partition_name */
    SELECT partition_name INTO l_subpartition_name
    FROM (
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
             ROW_NUMBER() OVER (PARTITION BY b.table_name ORDER BY SUM(a.bytes) / (1024 * 1024 * 1024) DESC) AS rn
      FROM dba_segments a, dba_tab_subpartitions b, dba_tablespaces c
      WHERE a.segment_type = 'TABLE SUBPARTITION'
      AND c.tablespace_name = a.tablespace_name
      AND a.owner = b.table_owner
      AND b.table_name = l_tabname
      AND a.segment_name = b.table_name
      AND a.partition_name = b.subpartition_name
      AND b.PARTITION_NAME = x.partition_name /* limit query of range based subpartitions to the given doc type partition */
      and a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N')
      GROUP BY a.owner, b.table_name, a.partition_name, a.tablespace_name, c.DEF_TAB_COMPRESSION, c.COMPRESS_FOR, c.BIGFILE, c.STATUS, a.segment_name, a.segment_type
    )
    WHERE rn = 1;

    DBMS_OUTPUT.PUT_LINE(chr(13)||chr(10)||'Object = ' || l_tabowner || '.' || l_tabname || '.' || x.partition_name  ||'.' || l_subpartition_name ;

    FOR i IN 1..l_numbers.COUNT LOOP
      -- Loop through different compression types
      DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
        scratchtbsname => l_scratchtbsname,
        ownname        => l_tabowner,
        objname        => l_tabname,
        subobjname     => l_subpartition_name,
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

/* WE ALREADY HAVE THE INDEX DATA */
EXIT;
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
      AND d.table_name IN ('D_INVOICE_DOCS') /* specify your table names */
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
      AND d.table_name IN ('D_INVOICE_DOCS') /* specify your table names */
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
