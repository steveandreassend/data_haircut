PROMPT Create some test tables with range and composite partitioning

CREATE TABLE PRODUCTS (partno NUMBER,
      description VARCHAR(32),
       costprice NUMBER,
       PDF BLOB
)
  PARTITION BY RANGE (partno)
     SUBPARTITION BY HASH(description)
    SUBPARTITIONS 8
      (PARTITION p1 VALUES LESS THAN (100),
       PARTITION p2 VALUES LESS THAN (200),
       PARTITION p3 VALUES LESS THAN (MAXVALUE));

CREATE INDEX ind_products on PRODUCTS (partno) LOCAL;

BEGIN
      
FOR x IN 1 .. 1000000 LOOP
  INSERT INTO PRODUCTS VALUES (x,x,x, NULL);
END LOOP;

END;
/

COMMIT;

/* alternate faster way

INSERT INTO PRODUCTS
SELECT level,
       CASE
         WHEN MOD(level,2)=0 THEN 'CODE1'
         ELSE 'CODE2'
       END,
       CASE
         WHEN MOD(level,2)=0 THEN 'Description for CODE1'
         ELSE 'Description for CODE2'
       END,
       CASE
         WHEN MOD(level,2)=0 THEN 'CLOB description for CODE1'
         ELSE 'CLOB description for CODE2'
       END,
       CASE
         WHEN MOD(level,2)=0 THEN TO_DATE('01/07/2015','DD/MM/YYYY')
         ELSE TO_DATE('01/07/2016','DD/MM/YYYY')
       END
FROM   dual
CONNECT BY level <= 100000;
*/

CREATE TABLE SALES (
    sales_id NUMBER,
    sales_date DATE,
    amount NUMBER,
    PDF BLOB
)
PARTITION BY RANGE (sales_date) (
    PARTITION sales_q1_2023 VALUES LESS THAN (TO_DATE('2023-04-01', 'YYYY-MM-DD')),
    PARTITION sales_q2_2023 VALUES LESS THAN (TO_DATE('2023-07-01', 'YYYY-MM-DD')),
    PARTITION sales_q3_2023 VALUES LESS THAN (TO_DATE('2023-10-01', 'YYYY-MM-DD')),
    PARTITION sales_q4_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD'))
);

BEGIN
      
FOR x IN 1 .. 1000000 LOOP
  /* generate random date */
  INSERT INTO SALES VALUES (
      x,
      TO_DATE('2022-01-01', 'YYYY-MM-DD') + DBMS_RANDOM.VALUE(1, SYSDATE - TO_DATE('2022-01-01', 'YYYY-MM-DD')),
      TO_CHAR(DBMS_RANDOM.VALUE(1000, 999999), '999,999.00'),
      NULL);
END LOOP;

END;
/

COMMIT;

CREATE INDEX ind_SALES on SALES (sales_id) LOCAL;

/* Generate BLOB data */
DECLARE
  v_clob        CLOB;
  v_blob        BLOB;
  v_dest_offset INTEGER := 1;
  v_src_offset  INTEGER := 1;
  v_warn        INTEGER;
  v_ctx         INTEGER := DBMS_LOB.default_lang_ctx;
BEGIN
  FOR idx IN 1..5 LOOP
    v_clob := v_clob || DBMS_RANDOM.string('x', 2000);
  END LOOP;

  DBMS_LOB.createTemporary(v_blob, FALSE);

  DBMS_LOB.convertToBlob(
    dest_lob      => v_blob,
    src_clob      => v_clob,
    amount        => DBMS_LOB.lobmaxsize,
    dest_offset   => v_dest_offset,
    src_offset    => v_src_offset,
    blob_csid     => DBMS_LOB.default_csid,
    lang_context  => v_ctx,
    warning       => v_warn
  );
    
  UPDATE PRODUCTS SET PDF = v_blob;
  COMMIT;
END;
/

