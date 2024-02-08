SET LINES 400 PAGES 1000
set serveroutput on

ALTER SESSION SET DB_FILE_MULTIBLOCK_READ_COUNT = 128;

SET TIMING ON

PROMPT create temp table and indexes
CREATE TABLE AAX2SW.NEW_H_D_DOCUMENTS
  TABLESPACE USERS
  AS SELECT JN_OPERATION, JN_USER, JN_ID, JN_DATUM, ID, DOCUMENT_TYPE, ENTITY, STATUS,
  FILE_NAME, DOC_NAME_STRATEGY, PROCESS_DATE, MIME_TYPE, LOCKING, REF_ENTITY, CREATE_DATE, DMW_LINK, DMS_ID,
  LAST_USER, STATUS_STRING, HYPERLINK, SHORT_NAME, TEMPLATE, CLIENT, LANGUAGE, DOCUMENT_ID
  FROM AAX2SW.H_D_DOCUMENTS;

CREATE INDEX AAX2SW.NEW_H_D_DOCUMENTS$ID ON AAX2SW.NEW_H_D_DOCUMENTS (ID) TABLESPACE USERS;
CREATE INDEX AAX2SW.NEW_H_D_DOCUMENTS$JN_USER ON AAX2SW.NEW_H_D_DOCUMENTS (JN_USER) TABLESPACE USERS;
CREATE INDEX AAX2SW.NEW_H_D_DOCUMENTS$$JN_ID ON AAX2SW.NEW_H_D_DOCUMENTS (JN_ID) TABLESPACE USERS;
  
PROMPT Reporting indexes in size ...

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
    SELECT DISTINCT owner, table_owner, table_name, index_name, segment_name, segment_type
    FROM (
      SELECT a.owner, d.table_owner, d.table_name, d.index_name, a.segment_name, a.segment_type
      FROM dba_segments a, dba_tablespaces c, dba_indexes d
      WHERE a.segment_type IN ('INDEX')
      AND a.segment_name  IN ('NEW_H_D_DOCUMENTS$ID','NEW_H_D_DOCUMENTS$JN_USER','NEW_H_D_DOCUMENTS$$JN_ID')
      AND c.tablespace_name = a.tablespace_name
      AND a.owner = d.owner
      AND a.segment_name = d.index_name
    )
  )
  LOOP
    DBMS_OUTPUT.PUT_LINE(chr(13)||chr(10)||'Object = Table '|| x.table_owner ||'.'|| x.table_name||' Index '|| x.owner || '.' || x.index_name );

    FOR i IN 1..l_numbers.COUNT LOOP
      -- Loop through different compression types
      BEGIN
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

      EXCEPTION
        WHEN OTHERS THEN
          -- Handling exceptions
          DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE);
          DBMS_OUTPUT.PUT_LINE('SQL Error Message: ' || SQLERRM);
      END;

-- Display compression information for each compression type
      DBMS_OUTPUT.PUT_LINE('Estimated Compression Ratio of Sample                           : ' || l_cmp_ratio);
      DBMS_OUTPUT.PUT_LINE('Compression Ratio                                               : ' || LTRIM(TO_CHAR(l_blkcnt_uncmp/l_blkcnt_cmp,'999,999,999.00'))||' to 1');
      DBMS_OUTPUT.PUT_LINE('Compression Type                                                : ' || l_comptype_str||' '||l_numbers(i));
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the compressed sample of the object    : ' || l_blkcnt_cmp);
      DBMS_OUTPUT.PUT_LINE('Number of blocks used by the uncompressed sample of the object  : ' || l_blkcnt_uncmp);
      DBMS_OUTPUT.put_line('Number of rows in a block in compressed sample of the object    : ' || l_row_cmp);
      DBMS_OUTPUT.put_line('Number of rows in a block in uncompressed sample of the object  : ' || l_row_uncmp);

  END LOOP;
END;
/
