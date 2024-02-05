SET SERVEROUTPUT ON
SET LINES 400 PAGES 1000


/*
If a lot of rows have been deleted from LOB tables then fragmentation may be an issue. The following commands explore this.
Otherwise rows are not being deleted, then the LOB Segment Storage Size is indicative of the LOB data size.
*/
/*
PROMPT Determine size of BLOB data...

SELECT SUM(dbms_lob.getlength(BLOB_DATA)) getlength
FROM AAX2DMSSW.D_INVOICE_DOCS;

PROMPT If CLOB then this is length
PROMPT If BLOB then this is bytes

PROMPT Determine size of CLOB data
*/
/*
How to Return CLOB Size in Bytes like LENGTHB Function of CHAR/VARCHAR2 (Document  790886.1)

The dbms_lob.getlength function returns the number of CHARACTERS not (as often assumed) the nr of BYTES of the CLOB.
This is the same behavior as LENGTH (column) who also returns the amount of characters.
           
To get bytes convert CLOB to BLOB:
*/

CREATE OR REPLACE FUNCTION cloblengthb(
  p_clob IN clob
)
RETURN NUMBER AS
  v_temp_blob BLOB;
  v_dest_offset NUMBER := 1;
  v_src_offset NUMBER := 1;
  v_amount INTEGER := dbms_lob.lobmaxsize;
  v_blob_csid NUMBER := dbms_lob.default_csid;
  v_lang_ctx INTEGER := dbms_lob.default_lang_ctx;
  v_warning INTEGER;
  v_total_size number := 0; -- Return total clob length in bytes
BEGIN
  IF p_clob is not null THEN
    DBMS_LOB.CREATETEMPORARY(
      lob_loc=>v_temp_blob,
      cache=>TRUE
    );

    DBMS_LOB.CONVERTTOBLOB(
      v_temp_blob,
      p_clob,
      v_amount,
      v_dest_offset,
      v_src_offset,
      v_blob_csid,
      v_lang_ctx,
      v_warning
    );

    v_total_size := DBMS_LOB.GETLENGTH(v_temp_blob);
    DBMS_LOB.FREETEMPORARY(v_temp_blob);

  ELSE
    v_total_size := 0;
  END IF;
  RETURN v_total_size;
END cloblengthb;
/

/* Unnecessary it is a BLOB
SELECT SUM(cloblengthb(BLOB_DATA)) cloblengthb
FROM AAX2DMSSW.D_INVOICE_DOCS;
*/       

DROP FUNCTION cloblengthb;

PROMPT Determine the storage usage in a LOB segment using DBMS_SPACE.SPACE_USAGE

DECLARE
  l_owner VARCHAR2(64) := 'AAX2DMSSW';
  l_tabname varchar2(256) := 'D_INVOICE_DOCS';
  l_column_name VARCHAR2(64) := 'BLOB_DATA';
  l_segname VARCHAR2(64); -- := 'SYS_LOB0000277792C00008$$';
  l_segtype VARCHAR2(64) := 'LOB';

  /* partition counters */
  p_segment_size_blocks NUMBER;
  p_segment_size_bytes NUMBER;
  p_used_blocks NUMBER;
  p_used_bytes NUMBER;
  p_expired_blocks NUMBER;
  p_expired_bytes NUMBER;
  p_unexpired_blocks NUMBER;
  p_unexpired_bytes NUMBER;
  p_unused_blocks NUMBER;
  p_unused_bytes NUMBER;
  p_non_data_blocks NUMBER;
  p_non_data_bytes NUMBER;

  /* subpartition counters */
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

  DBMS_OUTPUT.ENABLE;

  dbms_output.put_line('Table Owner: '||l_ower);
  dbms_output.put_line('Table Name: '||l_tabname);
  dbms_output.put_line('Column Name: '||l_column_name);

  SELECT DISTINCT segment_name
  INTO l_segname
  FROM dba_lobs
  WHERE owner = UPPER(l_owner)
  AND table_name = UPPER(l_tabname)
  AND column_name = UPPER(l_column_name);

  dbms_output.put_line('LOB Segment Name: '||l_segname);

  /* because DBMS_SPACE requires LOB specified for a LOGSEGMENT */
  SELECT DISTINCT DECODE(segment_type,'LOBSEGMENT','LOB',segment_type)
  INTO l_segtype
  FROM dba_segments
  WHERE owner = UPPER(l_owner)
  AND   segment_name = UPPER(l_segname);

  IF UPPER(l_segtype) NOT IN ('LOB','LOB PARTITION','LOB SUBPARTITION') THEN
    raise_application_error(-20000,'Specify LOB, or LOB PARTITION if the target objected is a partitioned LOB column');
  END IF;

  dbms_output.put_line('LOB Segment Type: '||l_segtype);

  FOR x IN (
    SELECT DISTINCT partition_name
    FROM dba_tab_partitions
    WHERE TABLE_OWNER = UPPER(l_owner)
    AND table_name = UPPER(l_tabname)
    ORDER BY 1
  ) LOOP

/*
There are 24 different document types, each stored in their own partition, and sub-partitioned by date range
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

    DBMS_OUTPUT.PUT_LINE('Partition Name: '||UPPER(x.partition_name));

    /* look through all non-empty subpartitions, and aggregate the stats */
    FOR y IN (
      SELECT *
      FROM (
        SELECT a.owner,
        b.table_name,
        a.partition_name,
        b.subpartition_name,
        a.tablespace_name,
        c.DEF_TAB_COMPRESSION,
        c.COMPRESS_FOR,
        c.BIGFILE,
        c.STATUS,
        a.segment_name,
        a.segment_type,
        SUM(a.bytes)
      FROM dba_segments a, dba_tab_subpartitions b, dba_tablespaces c
      WHERE a.segment_type = UPPER(l_segtype) --'LOB SUBPARTITION' --TABLE SUBPARTITION
      AND b.table_owner = UPPER(l_owner)
      AND b.table_name = UPPER(l_tabname)
      AND c.tablespace_name = a.tablespace_name
      AND a.owner = b.table_owner
      AND a.segment_name = b.table_name
      AND a.partition_name = b.subpartition_name
      AND b.PARTITION_NAME = x.partition_name /* limit query of range based subpartitions to the given doc type partition */
      AND a.owner IN (SELECT username FROM dba_users where oracle_maintained = 'N')
      GROUP BY a.owner,
               b.table_name,
               a.partition_name,
               b.subpartition_name,
               a.tablespace_name,
               c.DEF_TAB_COMPRESSION,
               c.COMPRESS_FOR,
               c.BIGFILE,
               c.STATUS,
               a.segment_name,
               a.segment_type
      HAVING SUM(a.bytes) > 0
      )
    ) LOOP

      /* for each subpartition */
      dbms_output.put_line('Subpartition Name: '||y.subpartition);
      BEGIN
        DBMS_SPACE.SPACE_USAGE(
          segment_owner => UPPER(l_owner),
          segment_name => UPPER(l_segname),
          segment_type => UPPER('TABLE SUBPARTITION'),
          segment_size_blocks => l_segment_size_blocks,
          segment_size_bytes => l_segment_size_bytes,
          used_blocks => l_used_blocks,
          used_bytes => l_used_bytes,
          expired_blocks => l_expired_blocks,
          expired_bytes => l_expired_bytes,
          unexpired_blocks => l_unexpired_blocks,
          unexpired_bytes => l_unexpired_bytes,
          partition_name => y.subpartition_name
        );

        /* calculate subpartition figures */
        l_unused_blocks := l_segment_size_blocks - (l_used_blocks + l_expired_blocks + l_unexpired_blocks);
        l_unused_bytes := l_segment_size_bytes - (l_used_bytes + l_expired_bytes + l_unexpired_bytes);
        l_non_data_blocks := l_unused_blocks + l_expired_blocks + l_unexpired_blocks;
        l_non_data_bytes := l_unused_bytes + l_expired_bytes + l_unexpired_bytes;

        /* add subpartition to cumulative partition counters */
        p_used_blocks         := p_used_blocks         + l_used_blocks;
        p_used_bytes          := p_used_bytes          + l_used_bytes;
        p_unused_blocks       := p_unused_blocks       + l_unused_blocks;
        p_unused_bytes        := p_unused_bytes        + l_unused_bytes;
        p_non_data_blocks     := p_non_data_blocks     + l_non_data_blocks;
        p_non_data_bytes      := p_non_data_bytes      + l_non_data_bytes;
        p_segment_size_bytes  := p_segment_size_bytes  + l_segment_size_bytes;
        p_segment_size_blocks := p_segment_size_blocks + l_segment_size_blocks;
        p_unexpired_bytes     := p_unexpired_bytes     + l_unexpired_bytes;
        p_unexpired_blocks    := p_unexpired_blocks    + l_unexpired_blocks;
        p_expired_blocks      := p_expired_blocks      + l_expired_blocks;
        p_expired_bytes       := p_expired_bytes       + l_expired_bytes;

      EXCEPTION
        WHEN OTHERS THEN
          -- Handling exceptions
          DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE);
          DBMS_OUTPUT.PUT_LINE('SQL Error Message: ' || SQLERRM);
      END;

    END LOOP; /* next subpartition */

    /* report partition aggregated statistics */
    DBMS_OUTPUT.PUT_LINE(' Aggregated Statistics for all subpartitions of partition: '||x.partition_name);
    DBMS_OUTPUT.PUT_LINE(' Segment Blocks/Bytes   = '||p_segment_size_blocks||' / '||p_segment_size_bytes);
    DBMS_OUTPUT.PUT_LINE(' Unused Blocks/Bytes    = '||p_unused_blocks||' / '||p_unused_bytes);
    DBMS_OUTPUT.PUT_LINE(' Used Blocks/Bytes      = '||p_used_blocks||' / '||p_used_bytes);
    DBMS_OUTPUT.PUT_LINE(' Expired Blocks/Bytes   = '||p_expired_blocks||' / '||p_expired_bytes);
    DBMS_OUTPUT.PUT_LINE(' Unexpired Blocks/Bytes = '||p_unexpired_blocks||' / '||p_unexpired_bytes);
    DBMS_OUTPUT.PUT_LINE('===========================================================================');
    DBMS_OUTPUT.PUT_LINE(' Non-Data Blocks/Bytes  = '||p_non_data_blocks||' / '||p_non_data_bytes);
      
    /* reset partition counters */
    p_segment_size_blocks := 0;
    p_segment_size_bytes := 0;
    p_used_blocks := 0;
    p_used_bytes := 0;
    p_expired_blocks := 0;
    p_expired_bytes := 0;
    p_unexpired_blocks := 0;
    p_unexpired_bytes := 0;
    p_unused_blocks := 0;
    p_unused_bytes := 0;
    p_non_data_blocks := 0;
    p_non_data_bytes := 0;
  END LOOP; /* next partition */
END;
/

/*
    If there are many extents smaller than the Non-Data Blocks, then it is is a candidate for rebuild:
    SELECT BYTES, COUNT(1)
    FROM DBA_EXTENTS
    WHERE SEGMENT_NAME = 'SYS_LOB0000067626C00002$$'
    GROUP BY BYTES ORDER BY 2;
*/
