SET LINES 400 PAGES 1000
set serveroutput on

DECLARE
  l_blkcnt_cmp     PLS_INTEGER;
  l_blkcnt_uncmp   PLS_INTEGER;
  l_row_cmp        PLS_INTEGER;
  l_row_uncmp       PLS_INTEGER;
  l_cmp_ratio      NUMBER;
  l_comptype_str   VARCHAR2(32767);
  l_scratchtbsname varchar2(256) := 'USERS';

BEGIN
  /* find all tables larger than 1GB that are not partitioned */
  FOR x IN (
    SELECT a.owner, b.table_name
    FROM dba_segments a, dba_tables b
    WHERE a.segment_type = 'TABLE'
    AND a.owner = b.owner
    AND a.segment_name = b.table_name
    AND a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
    GROUP BY a.owner, b.table_name
    HAVING ROUND(SUM(a.bytes) / (1024 * 1024 * 1024), 2) >= 1

  )
  LOOP
  DBMS_OUTPUT.PUT_LINE('Object = ' || x.owner || '.' || x.table_name );
  -- Loop through different compression types
    DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
      scratchtbsname => l_scratchtbsname,
      ownname        => x.owner,
      objname        => x.table_name,
      subobjname     => NULL,
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
    SELECT owner, table_owner, table_name, index_name, segment_name, segment_type
    FROM (
      SELECT a.owner, d.table_owner, d.table_name, d.index_name, a.segment_name, a.segment_type,
      ROW_NUMBER() OVER (PARTITION BY d.index_name ORDER BY SUM(a.bytes) / (1024 * 1024 * 1024) DESC) AS rn
      FROM dba_segments a, dba_tablespaces c, dba_indexes d
      WHERE a.segment_type IN ('INDEX')
      AND c.tablespace_name = a.tablespace_name
      AND a.owner = d.owner
      AND a.segment_name = d.index_name
      AND a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N')
      AND (d.table_owner, d.table_name) IN (
        SELECT c.owner, d.table_name
        FROM dba_segments c, dba_tables d
        WHERE c.segment_type = 'TABLE'
        AND c.owner = d.owner
        AND c.segment_name = d.table_name
        AND c.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N') 
        GROUP BY c.owner, d.table_name
        HAVING ROUND(SUM(c.bytes) / (1024 * 1024 * 1024), 2) >= 1
      )
      GROUP BY a.owner, d.table_owner, d.table_name, d.index_name, a.segment_name, a.segment_type
    )
    WHERE rn = 1
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(chr(13)||chr(10)||'Object = Table '|| x.table_owner ||'.'|| x.table_name||' Index '|| x.owner || '.' || x.index_name );

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
