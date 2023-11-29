SET LINES 400 PAGES 1000
set serveroutput on

PROMPT Get LOW LOB COMPRESSION ratios

DECLARE
  l_blkcnt_cmp pls_integer;
  l_blkcnt_uncmp pls_integer;
  l_row_cmp pls_integer;
  l_row_uncmp pls_integer;
  l_cmp_ratio pls_integer;
  l_cmptype_str varchar2(100);
  l_scratchtbsname varchar2(256) := 'USERS';
  l_tabowner varchar2(256) := 'AAX2SW';
  l_tabname varchar2(256) := 'D_COMMUNICATIONS';
  l_lobname varchar2(256) := 'SYS_LOB0000100033C00003$$';
BEGIN
  DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
    scratchtbsname => l_scratchtbsname,
    tabowner => l_tabowner,
    tabname => l_tabname,
    lobname => l_lobname,
--    partname => ,
    comptype => DBMS_COMPRESSION.COMP_LOB_LOW,
    blkcnt_cmp => l_blkcnt_cmp,
    blkcnt_uncmp => l_blkcnt_uncmp,
    row_cmp => l_row_cmp,
    row_uncmp => l_row_uncmp,
    cmp_ratio => l_cmp_ratio,
    comptype_str => l_cmptype_str,
    subset_numrows => DBMS_COMPRESSION.COMP_RATIO_LOB_MAXROWS /* 5000 rows sampled */
  );

  DBMS_OUTPUT.PUT_LINE('Object = '||l_tabowner||'.'||l_tabname||'.'||l_lobname);
  DBMS_OUTPUT.PUT_LINE('Compression Type = DBMS_COMPRESSION.COMP_LOB_LOW');  
  DBMS_OUTPUT.PUT_LINE('Block count compressed = '|| l_blkcnt_cmp);
  DBMS_OUTPUT.PUT_LINE('Block count uncompressed = '|| l_blkcnt_uncmp);
  DBMS_OUTPUT.PUT_LINE('Row count per block compressed = '|| l_row_cmp);
  DBMS_OUTPUT.PUT_LINE('Row count per block uncompressed = '|| l_row_uncmp);
  DBMS_OUTPUT.PUT_LINE('Compression type = '|| l_cmptype_str);
  DBMS_OUTPUT.PUT_LINE('Compression ratio = '|| l_cmp_ratio);
END;
/

PROMPT Get MEDIUM LOB COMPRESSION ratios...

DECLARE
  l_blkcnt_cmp pls_integer;
  l_blkcnt_uncmp pls_integer;
  l_row_cmp pls_integer;
  l_row_uncmp pls_integer;
  l_cmp_ratio pls_integer;
  l_cmptype_str varchar2(100);
  l_scratchtbsname varchar2(256) := 'USERS';
  l_tabowner varchar2(256) := 'AAX2SW';
  l_tabname varchar2(256) := 'D_COMMUNICATIONS';
  l_lobname varchar2(256) := 'SYS_LOB0000100033C00003$$';
BEGIN
  DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
    scratchtbsname => l_scratchtbsname,
    tabowner => l_tabowner,
    tabname => l_tabname,
    lobname => l_lobname,
--    partname => ,
    comptype => DBMS_COMPRESSION.COMP_LOB_MEDIUM,
    blkcnt_cmp => l_blkcnt_cmp,
    blkcnt_uncmp => l_blkcnt_uncmp,
    row_cmp => l_row_cmp,
    row_uncmp => l_row_uncmp,
    cmp_ratio => l_cmp_ratio,
    comptype_str => l_cmptype_str,
    subset_numrows => DBMS_COMPRESSION.COMP_RATIO_LOB_MAXROWS /* 5000 rows sampled */
  );

  DBMS_OUTPUT.PUT_LINE('Object = '||l_tabowner||'.'||l_tabname||'.'||l_lobname);
  DBMS_OUTPUT.PUT_LINE('Compression Type = DBMS_COMPRESSION.COMP_LOB_MEDIUM');  
  DBMS_OUTPUT.PUT_LINE('Block count compressed = '|| l_blkcnt_cmp);
  DBMS_OUTPUT.PUT_LINE('Block count uncompressed = '|| l_blkcnt_uncmp);
  DBMS_OUTPUT.PUT_LINE('Row count per block compressed = '|| l_row_cmp);
  DBMS_OUTPUT.PUT_LINE('Row count per block uncompressed = '|| l_row_uncmp);
  DBMS_OUTPUT.PUT_LINE('Compression type = '|| l_cmptype_str);
  DBMS_OUTPUT.PUT_LINE('Compression ratio = '|| l_cmp_ratio);
END;
/

PROMPT Get HIGH LOB COMPRESSION ratios....

DECLARE
  l_blkcnt_cmp pls_integer;
  l_blkcnt_uncmp pls_integer;
  l_row_cmp pls_integer;
  l_row_uncmp pls_integer;
  l_cmp_ratio pls_integer;
  l_cmptype_str varchar2(100);
  l_scratchtbsname varchar2(256) := 'USERS';
  l_tabowner varchar2(256) := 'AAX2SW';
  l_tabname varchar2(256) := 'D_COMMUNICATIONS';
  l_lobname varchar2(256) := 'SYS_LOB0000100033C00003$$';
BEGIN
  DBMS_COMPRESSION.GET_COMPRESSION_RATIO (
    scratchtbsname => l_scratchtbsname,
    tabowner => l_tabowner,
    tabname => l_tabname,
    lobname => l_lobname,
--    partname => ,
    comptype => DBMS_COMPRESSION.COMP_LOB_HIGH,
    blkcnt_cmp => l_blkcnt_cmp,
    blkcnt_uncmp => l_blkcnt_uncmp,
    row_cmp => l_row_cmp,
    row_uncmp => l_row_uncmp,
    cmp_ratio => l_cmp_ratio,
    comptype_str => l_cmptype_str,
    subset_numrows => DBMS_COMPRESSION.COMP_RATIO_LOB_MAXROWS /* 5000 rows sampled */
  );

  DBMS_OUTPUT.PUT_LINE('Object = '||l_tabowner||'.'||l_tabname||'.'||l_lobname);
  DBMS_OUTPUT.PUT_LINE('Compression Type = DBMS_COMPRESSION.COMP_LOB_HIGH');  
  DBMS_OUTPUT.PUT_LINE('Block count compressed = '|| l_blkcnt_cmp);
  DBMS_OUTPUT.PUT_LINE('Block count uncompressed = '|| l_blkcnt_uncmp);
  DBMS_OUTPUT.PUT_LINE('Row count per block compressed = '|| l_row_cmp);
  DBMS_OUTPUT.PUT_LINE('Row count per block uncompressed = '|| l_row_uncmp);
  DBMS_OUTPUT.PUT_LINE('Compression type = '|| l_cmptype_str);
  DBMS_OUTPUT.PUT_LINE('Compression ratio = '|| l_cmp_ratio);
END;
/
