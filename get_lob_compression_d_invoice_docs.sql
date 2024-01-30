SET LINES 400 PAGES 1000
set serveroutput on

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

  /* To avoid: ORA-20000: Compression Advisor sample size must be at least 0.1 percent of the total lobs */
  l_sample_size PLS_INTEGER;


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
    WHERE owner = l_tabowner
    AND table_name = l_tabname
    ORDER BY 1
  ) LOOP

    DBMS_OUTPUT.PUT_LINE(chr(13)||chr(10)||'Object = ' || l_tabowner || '.' || l_tabname || '.' || x.partition_name ||'.' || l_lobname);

    EXECUTE IMMEDIATE 'SELECT COUNT(1)*0.11 FROM '||l_tabowner||'.'||l_tabname||' PARTITION ('||x.partition_name||') WHERE '||l_lobname||' IS NOT NULL'
    INTO l_sample_size;

    SELECT GREATEST(l_sample_size, DBMS_COMPRESSION.COMP_RATIO_LOB_MAXROWS) INTO l_sample_size
    FROM DUAL;

    FOR i IN 1..l_numbers.COUNT LOOP
      BEGIN
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
        subset_numrows => l_sample_size
      );

        -- Display compression information for each compression type
        DBMS_OUTPUT.PUT_LINE('Compression Type                                                : ' || l_comptype_str);
        DBMS_OUTPUT.PUT_LINE('Estimated Compression Ratio of Sample                           : ' || l_cmp_ratio);    
        DBMS_OUTPUT.PUT_LINE('Compression Ratio                                               : ' || LTRIM(TO_CHAR(l_blkcnt_uncmp/l_blkcnt_cmp,'999,999,999.00'))||' to 1');
        DBMS_OUTPUT.PUT_LINE('Number of blocks used by the compressed sample of the object    : ' || l_blkcnt_cmp);
        DBMS_OUTPUT.PUT_LINE('Number of blocks used by the uncompressed sample of the object  : ' || l_blkcnt_uncmp);
        DBMS_OUTPUT.PUT_LINE('Number of LOBs actually sampled                                 : ' || l_lobcnt);
      EXCEPTION
        WHEN OTHERS THEN
          -- Handling exceptions
          DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE);
          DBMS_OUTPUT.PUT_LINE('SQL Error Message: ' || SQLERRM);
      END;
    END LOOP;
  END LOOP;
END;
/
