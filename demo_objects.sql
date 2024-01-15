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

FOR x IN 1 .. 1000000 LOOP
  INSERT INTO PRODUCTS VALUES (x,x,x, NULL);
END LOOP;
END;
/

COMMIT;


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

CREATE INDEX ind_SALES on SALES (sales_id) LOCAL;

INSERT INTO SALES VALUES (1,TO_DATE('2023-04-01', 'YYYY-MM-DD')-1,100, NULL);
INSERT INTO SALES VALUES (1,TO_DATE('2023-07-01', 'YYYY-MM-DD')-1,100, NULL);
INSERT INTO SALES VALUES (1,TO_DATE('2023-10-01', 'YYYY-MM-DD')-1,100, NULL);
INSERT INTO SALES VALUES (1,TO_DATE('2024-01-01', 'YYYY-MM-DD')-1,100, NULL);
COMMIT;

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

