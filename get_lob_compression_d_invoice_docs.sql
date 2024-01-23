SET LINES 400 PAGES 1000
set serveroutput on SIZE 25000

DECLARE
  l_blkcnt_cmp     PLS_INTEGER;
  l_blkcnt_uncmp   PLS_INTEGER;
  l_row_cmp        PLS_INTEGER;
  l_lobcnt         PLS_INTEGER;
  l_cmp_ratio      NUMBER;
  l_comptype_str   VARCHAR2(32767);

  l_scratchtbsname varchar2(256) := 'USERS';
  l_tabowner varchar2(256) := 'AAX2DMSSW';
  l_tabname varchar2(256) := 'D_INVOICE_DOCS';
  l_lobname varchar2(256) := 'BLOB_DATA';

  l_numbers CONSTANT SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(
    DBMS_COMPRESSION.COMP_LOB_LOW,
    DBMS_COMPRESSION.COMP_LOB_MEDIUM,
    DBMS_COMPRESSION.COMP_LOB_HIGH
  );

BEGIN
  --there are 24 different document types, each stored in their own partition, and sub-partitioned by date range
  FOR x IN (
    SELECT DISTINCT partition_name
    FROM dba_tab_partitions
    WHERE owner = l_tabowner
    AND table_name = l_tabname
    ORDER BY 1
  ) LOOP

    DBMS_OUTPUT.PUT_LINE(chr(13)||chr(10)||'Object = ' || l_tabowner || '.' || l_tabname || '.' || x.partition_name ||'.' || l_lobname);

    FOR i IN 1..l_numbers.COUNT LOOP
    -- Loop through different compression types
      DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
        scratchtbsname => l_scratchtbsname,
        tabowner       => l_tabowner,
        tabname        => l_tabname,
        lobname        => l_lobname,
        partname       => x.partition_name,
        comptype       => l_numbers(i),
        blkcnt_cmp     => l_blkcnt_cmp,
        blkcnt_uncmp   => l_blkcnt_uncmp,
        lobcnt         => l_lobcnt,
        cmp_ratio      => l_cmp_ratio,
        comptype_str   => l_comptype_str,
        subset_numrows => DBMS_COMPRESSION.COMP_RATIO_LOB_MAXROWS /* 5000 rows sampled */
      );

      -- Display compression information for each compression type
      DBMS_OUTPUT.PUT_LINE('Compression Type                                                : ' || l_comptype_str);
      DBMS_OUTPUT.PUT_LINE('Estimated Compression Ratio of Sample                           : ' || l_cmp_ratio);    
      DBMS_OUTPUT.PUT_LINE('Compression Ratio                                               : ' || LTRIM(TO_CHAR(l_blkcnt_uncmp/l_blkcnt_cmp,'999,999,999.00'))||' to 1');
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the compressed sample of the object    : ' || l_blkcnt_cmp);
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the uncompressed sample of the object  : ' || l_blkcnt_uncmp);
      DBMS_OUTPUT.PUT_LINE('Number of LOBs actually sampled                                 : ' || l_lobcnt);
    END LOOP;
  END LOOP;
END;
/
