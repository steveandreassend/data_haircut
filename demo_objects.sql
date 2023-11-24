PROMPT Create some test tables with range and composite partitioning

CREATE TABLE PRODUCTS (partno NUMBER,
      description VARCHAR(32),
       costprice NUMBER)
  PARTITION BY RANGE (partno)
     SUBPARTITION BY HASH(description)
    SUBPARTITIONS 8
      (PARTITION p1 VALUES LESS THAN (100),
       PARTITION p2 VALUES LESS THAN (200),
       PARTITION p3 VALUES LESS THAN (MAXVALUE));

CREATE INDEX ind_products on PRODUCTS (partno) LOCAL;

INSERT INTO PRODUCTS VALUES (1,1,1);
INSERT INTO PRODUCTS VALUES (101,1,1);
INSERT INTO PRODUCTS VALUES (201,1,1);
COMMIT;

CREATE TABLE SALES (
    sales_id NUMBER,
    sales_date DATE,
    amount NUMBER
)
PARTITION BY RANGE (sales_date) (
    PARTITION sales_q1_2023 VALUES LESS THAN (TO_DATE('2023-04-01', 'YYYY-MM-DD')),
    PARTITION sales_q2_2023 VALUES LESS THAN (TO_DATE('2023-07-01', 'YYYY-MM-DD')),
    PARTITION sales_q3_2023 VALUES LESS THAN (TO_DATE('2023-10-01', 'YYYY-MM-DD')),
    PARTITION sales_q4_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD'))
);

CREATE INDEX ind_SALES on SALES (sales_id) LOCAL;

INSERT INTO SALES VALUES (1,TO_DATE('2023-04-01', 'YYYY-MM-DD')-1,100);
INSERT INTO SALES VALUES (1,TO_DATE('2023-07-01', 'YYYY-MM-DD')-1,100);
INSERT INTO SALES VALUES (1,TO_DATE('2023-10-01', 'YYYY-MM-DD')-1,100);
INSERT INTO SALES VALUES (1,TO_DATE('2024-01-01', 'YYYY-MM-DD')-1,100);
COMMIT;