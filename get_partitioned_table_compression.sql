SET LINES 400 PAGES 1000
set serveroutput on SIZE 25000

DECLARE
  l_blkcnt_cmp     PLS_INTEGER;
  l_blkcnt_uncmp   PLS_INTEGER;
  l_row_cmp        PLS_INTEGER;
  l_row_uncmp       PLS_INTEGER;
  l_cmp_ratio      NUMBER;
  l_comptype_str   VARCHAR2(32767);
  l_scratchtbsname varchar2(256) := 'USERS';

BEGIN
  /* find all partitioned tables */
  FOR x IN (
    SELECT a.owner, b.table_name, MAX(b.PARTITION_NAME) partition_name
    FROM dba_segments a, dba_tab_partitions b, dba_tablespaces c
    WHERE a.segment_type = 'TABLE PARTITION'
    AND c.tablespace_name = a.tablespace_name
    AND a.owner = b.table_owner
    AND a.segment_name = b.table_name
    AND a.partition_name = b.partition_name
    AND a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
    GROUP BY a.owner, b.table_name
  )
  LOOP
  DBMS_OUTPUT.PUT_LINE('Object = ' || x.owner || '.' || x.table_name );
  -- Loop through different compression types
    DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
      scratchtbsname => l_scratchtbsname,
      ownname        => x.owner,
      objname        => x.table_name,
      partname       => x.partition_name
      comptype       => DBMS_COMPRESSION.COMP_ADVANCED,
      blkcnt_cmp     => l_blkcnt_cmp,
      blkcnt_uncmp   => l_blkcnt_uncmp,
      row_cmp        => l_row_cmp,
      row_uncmp      => l_row_uncmp,
      cmp_ratio      => l_cmp_ratio,  
      comptype_str   => l_comptype_str,
      subset_numrows => DBMS_COMPRESSION.comp_ratio_minrows, /* 1000000 rows sampled */
      objtype        => DBMS_COMPRESSION.objtype_table
    );

    -- Display compression information for each compression type
    DBMS_OUTPUT.PUT_LINE('Compression Type                                                : ' || l_comptype_str);
    DBMS_OUTPUT.PUT_LINE('Estimated Compression Ratio of Sample                           : ' || l_cmp_ratio);    
    DBMS_OUTPUT.PUT_LINE('Compression Ratio                                               : ' || LTRIM(TO_CHAR(l_blkcnt_uncmp/l_blkcnt_cmp,'999,999,999.00'))||' to 1');
    DBMS_OUTPUT.PUT_LINE('Number of blocks used by the compressed sample of the object    : ' || l_blkcnt_cmp);
    DBMS_OUTPUT.PUT_LINE('Number of blocks used by the uncompressed sample of the object  : ' || l_blkcnt_uncmp);
    DBMS_OUTPUT.put_line('Number of rows in a block in compressed sample of the object    : ' || l_row_cmp);
    DBMS_OUTPUT.put_line('Number of rows in a block in uncompressed sample of the object  : ' || l_row_uncmp);
  END LOOP;
END;
/



