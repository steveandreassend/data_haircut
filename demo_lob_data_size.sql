/*
If a lot of rows have been deleted from LOB tables then fragmentation may be an issue. The following commands explore this.
Otherwise rows are not being deleted, then the LOB Segment Storage Size is indicative of the LOB data size.
*/

PROMPT Determine size of BLOB data
/* SELECT sum(dbms_lob.getlength(<lob column name>)) from <table_name>; */

PROMPT Determine size of CLOB data
/*
  CLOBs use the following note
  How to Return CLOB Size in Bytes like LENGTHB Function of CHAR/VARCHAR2 (Document  790886.1)
*/

PROMPT Determine the storage usage in a LOB segment using DBMS_SPACE.SPACE_USAGE

SET SERVEROUTPUT ON SIZE 25000

CREATE OR REPLACE PROCEDURE check_space_securefile (
  p_owner in varchar2,
  p_segname in varchar2,
  p_segtype in varchar2 DEFAULT 'LOB'
) IS
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
  IF UPPER(p_segtype) NOT IN ('LOB','LOB PARTITION') THEN
    raise_application_error(-20000,'Specify LOB, or LOB PARTITION if the target objected is a partitioned LOB column');
  END IF;

  DBMS_SPACE.SPACE_USAGE(
      segment_owner => UPPER(p_owner),
      segment_name => UPPER(p_segname),
      segment_type => UPPER(p_segtype),
      segment_size_blocks => l_segment_size_blocks,
      segment_size_bytes => l_segment_size_bytes,
      used_blocks => l_used_blocks,
      used_bytes => l_used_bytes,
      expired_blocks => l_expired_blocks,
      expired_bytes => l_expired_bytes,
      unexpired_blocks => l_unexpired_blocks,
      unexpired_bytes => l_unexpired_bytes
  );

  l_unused_blocks := l_segment_size_blocks - (l_used_blocks + l_expired_blocks + l_unexpired_blocks);
  l_unused_bytes := l_segment_size_bytes - (l_used_bytes + l_expired_bytes + l_unexpired_bytes);
  l_non_data_blocks := l_unused_blocks + l_expired_blocks + l_unexpired_blocks;
  l_non_data_bytes :=  l_unused_bytes + l_expired_bytes + l_unexpired_bytes;

  DBMS_OUTPUT.ENABLE;
  DBMS_OUTPUT.PUT_LINE(' Owner.Segment Namne    = '||UPPER(p_owner)||'.'||UPPER(p_segname));
  DBMS_OUTPUT.PUT_LINE(' Segment Blocks/Bytes   = '||l_segment_size_blocks||' / '||l_segment_size_bytes);
  DBMS_OUTPUT.PUT_LINE(' Unused Blocks/Bytes    = '||l_unused_blocks||' / '||l_unused_bytes);
  DBMS_OUTPUT.PUT_LINE(' Used Blocks/Bytes      = '||l_used_blocks||' / '||l_used_bytes);
  DBMS_OUTPUT.PUT_LINE(' Expired Blocks/Bytes   = '||l_expired_blocks||' / '||l_expired_bytes);
  DBMS_OUTPUT.PUT_LINE(' Unexpired Blocks/Bytes = '||l_unexpired_blocks||' / '||l_unexpired_bytes);
  DBMS_OUTPUT.PUT_LINE('===========================================================================');
  DBMS_OUTPUT.PUT_LINE(' NON Data Blocks/Bytes  = '||l_non_data_blocks||' / '||l_non_data_bytes);

/*
    if there are many extents smaller than the Non Data Blocks, then it is is a candidate for rebuild:
    SELECT BYTES, COUNT(*)
    FROM DBA_EXTENTS
    WHERE SEGMENT_NAME = 'SYS_LOB0000067626C00002$$'
    GROUP BY BYTES ORDER BY 2;
  */
END;
/

BEGIN
  check_space_securefile(
    p_owner   => '?',
    p_segname => 'SYS_LOB?$$',
    p_segtype => 'LOB'
  );
END;
/

/* Example LOB commands

CREATE TABLE print_media
    ( product_id        NUMBER(6),
      ad_id             NUMBER(6),
      ad_sourcetext     CLOB)
    LOB (ad_sourcetext)  STORE AS SECUREFILE (TABLESPACE tbs_2)
    PARTITION BY RANGE(product_id)
    (PARTITION P1 VALUES LESS THAN (1000)
         LOB (ad_sourcetext) STORE AS BASICFILE (TABLESPACE tbs_1),
     PARTITION P2 VALUES LESS THAN (2000)
         LOB (ad_sourcetext) STORE AS (TABLESPACE tbs_2 COMPRESS HIGH),
     PARTITION P3 VALUES LESS THAN (3000));
     
ALTER TABLE print_media ADD PARTITION P4 VALUES LESS THAN (4000)
         LOB (ad_sourcetext) STORE AS SECUREFILE(TABLESPACE tbs_2);

ALTER TABLE print_media MODIFY PARTITION P3 LOB(ad_sourcetext)
     (RETENTION AUTO);

ALTER TABLE print_media MOVE PARTITION P1 LOB(ad_sourcetext)  
    STORE AS (TABLESPACE tbs_3 COMPRESS LOW);

ALTER TABLE print_media SPLIT PARTITION  P1 AT(500) into
(PARTITION P1A LOB(ad_sourcetext) STORE AS (TABLESPACE tbs_1),
PARTITION P1B LOB(ad_sourcetext) STORE AS (TABLESPACE tbs_2)) UPDATE INDEXES;

ALTER TABLE print_media MERGE PARTITIONS P1A, P1B INTO PARTITION P1;

CREATE TABLE print_media_nonpart
    ( product_id NUMBER(6),
      ad_id NUMBER(6),
      ad_sourcetext CLOB)
      LOB (ad_sourcetext) STORE AS SECUREFILE (COMPRESS HIGH);

ALTER TABLE print_media  EXCHANGE PARTITION p1 WITH TABLE print_media_nonpart;

CREATE INDEX ad_sourcetext_idx_sql on print_media (to_char(substr(ad_sourcetext,1,10)))
      GLOBAL;

CREATE INDEX ad_sourcetext_idx_sql on print_media (to_char(substr(ad_sourcetext,1,10)))
      LOCAL;

*/

