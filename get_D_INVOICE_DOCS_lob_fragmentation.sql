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
  l_segname VARCHAR2(64) := 'SYS_LOB0000277792C00008$$';
  l_segtype VARCHAR2(64) := 'LOB';
  l_tabname varchar2(256) := 'D_INVOICE_DOCS';
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

  SELECT DISTINCT DECODE(segment_type,'LOBSEGMENT','LOB',segment_type) INTO l_segtype
  FROM dba_segments
  WHERE owner = UPPER(l_owner)
  AND   segment_name = UPPER(l_segname);

  IF UPPER(l_segtype) NOT IN ('LOB','LOB PARTITION','LOB SUBPARTITION') THEN
    raise_application_error(-20000,'Specify LOB, or LOB PARTITION if the target objected is a partitioned LOB column');
  END IF;

  FOR x IN (
    SELECT DISTINCT partition_name
    FROM dba_tab_partitions
    WHERE TABLE_OWNER = UPPER(l_owner)
    AND table_name = UPPER(l_tabname)
    ORDER BY 1
  ) LOOP

  BEGIN
    DBMS_OUTPUT.PUT_LINE(' Owner.Segment Name.Partition Name  = '||UPPER(l_owner)||'.'||UPPER(l_segname)||'.'||UPPER(x.partition_name));
    
    DBMS_SPACE.SPACE_USAGE(
      segment_owner => UPPER(l_owner),
      segment_name => UPPER(l_segname),
      segment_type => UPPER(l_segtype),
      segment_size_blocks => l_segment_size_blocks,
      segment_size_bytes => l_segment_size_bytes,
      used_blocks => l_used_blocks,
      used_bytes => l_used_bytes,
      expired_blocks => l_expired_blocks,
      expired_bytes => l_expired_bytes,
      unexpired_blocks => l_unexpired_blocks,
      unexpired_bytes => l_unexpired_bytes,
      partition_name => x.partition_name
    );

    l_unused_blocks := l_segment_size_blocks - (l_used_blocks + l_expired_blocks + l_unexpired_blocks);
    l_unused_bytes := l_segment_size_bytes - (l_used_bytes + l_expired_bytes + l_unexpired_bytes);
    l_non_data_blocks := l_unused_blocks + l_expired_blocks + l_unexpired_blocks;
    l_non_data_bytes := l_unused_bytes + l_expired_bytes + l_unexpired_bytes;

    DBMS_OUTPUT.ENABLE;
    DBMS_OUTPUT.PUT_LINE(' Segment Blocks/Bytes   = '||l_segment_size_blocks||' / '||l_segment_size_bytes);
    DBMS_OUTPUT.PUT_LINE(' Unused Blocks/Bytes    = '||l_unused_blocks||' / '||l_unused_bytes);
    DBMS_OUTPUT.PUT_LINE(' Used Blocks/Bytes      = '||l_used_blocks||' / '||l_used_bytes);
    DBMS_OUTPUT.PUT_LINE(' Expired Blocks/Bytes   = '||l_expired_blocks||' / '||l_expired_bytes);
    DBMS_OUTPUT.PUT_LINE(' Unexpired Blocks/Bytes = '||l_unexpired_blocks||' / '||l_unexpired_bytes);
    DBMS_OUTPUT.PUT_LINE('===========================================================================');
    DBMS_OUTPUT.PUT_LINE(' Non-Data Blocks/Bytes  = '||l_non_data_blocks||' / '||l_non_data_bytes);
  EXCEPTION
    WHEN OTHERS THEN
      -- Handling exceptions
      DBMS_OUTPUT.PUT_LINE('SQL Error Code: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('SQL Error Message: ' || SQLERRM);
    END;

  END LOOP;
END;
/

/*
    If there are many extents smaller than the Non-Data Blocks, then it is is a candidate for rebuild:
    SELECT BYTES, COUNT(1)
    FROM DBA_EXTENTS
    WHERE SEGMENT_NAME = 'SYS_LOB0000067626C00002$$'
    GROUP BY BYTES ORDER BY 2;
*/