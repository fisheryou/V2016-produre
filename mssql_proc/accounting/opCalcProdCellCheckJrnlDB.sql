USE sims2016Proc
  go
  
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'opCalcProdCellCheckJrnlDB')
  DROP PROC opCalcProdCellCheckJrnlDB
go

CREATE PROC opCalcProdCellCheckJrnlDB
  @i_operatorCode          VARCHAR(255)        ,           --����Ա����
  @i_operatorPassword      VARCHAR(255)        ,           --����Ա����
  @i_operateStationText    VARCHAR(4096)       ,           --������Ϣ
  @i_fundAcctCode          VARCHAR(20)         ,           --�ʽ��˻�
  @i_exchangeCode          VARCHAR(20)         ,           --����������
  @i_secuCode              VARCHAR(20)         ,           --֤ȯ����
  @i_beginDate             VARCHAR(10)  =  ' '             --��ʼ����  
AS
/***************************************************************************
-- Author : yugy
-- Version : 1.0
--    V1.0 �� ֧����ȯ����
-- Date : 2017-04-26
-- Description : 
-- Function List : opCalcProdCellCheckJrnlDB
-- History : 

--Other business(δ����)
-- ��ծ����
-- �ع�����
    a)��Ѻʽ�ع�
    b)���ʽ�ع�
-- ծȯԶ��
-- ծȯ�Ҹ�
-- ծȯ���

****************************************************************************/
SET NOCOUNT ON
CREATE TABLE #tt_prodCellRawJrnlDBHist
(
  groupID                          SMALLINT         DEFAULT 0                         NOT NULL, --��������ID
  shareRecordDate                  VARCHAR(10)      DEFAULT ' '                           NULL, --�Ǽ�����
  serialNO                         NUMERIC(19,0)                                      NOT NULL, -- ������
  --createPosiDate                 VARCHAR(10)                                        NOT NULL, -- ��������
  settleDate                       VARCHAR(10)                                        NOT NULL, -- ��������
  -----------------------------------------------------------------------------------------------------------
  prodCode                         VARCHAR(30)                                        NOT NULL, -- ��Ʒ����
  prodCellCode                     VARCHAR(30)                                        NOT NULL, -- ��Ʒ��Ԫ����
  fundAcctCode                     VARCHAR(30)                                        NOT NULL, -- �ʽ��˻�����
  secuAcctCode                     VARCHAR(30)                                        NOT NULL, -- ֤ȯ�˻�����
  currencyCode                     VARCHAR(3)       DEFAULT 'CNY'                     NOT NULL, -- ���Ҵ���
  -----------------------------------------------------------------------------------------------------------
  exchangeCode                     VARCHAR(4)                                         NOT NULL, -- ����������
  secuCode                         VARCHAR(40)                                        NOT NULL, -- ֤ȯ����
  originSecuCode                   VARCHAR(40)      DEFAULT ''                            NULL, -- ԭʼ֤ȯ����
  secuTradeTypeCode                VARCHAR(30)                                        NOT NULL, -- ֤ȯ�������ʹ���
  ------------------------------------------------------------------------------------------------------------
  marketLevelCode                  VARCHAR(1)       DEFAULT '2'                       NOT NULL, -- �г���Դ
  transactionNO                    NUMERIC(19,0)    DEFAULT 1                         NOT NULL, -- ���ױ��
  investPortfolioCode              VARCHAR(30)                                        NOT NULL, -- Ͷ����ϴ���
  buySellFlagCode                  VARCHAR(1)                                         NOT NULL, -- ������־
  bizSubTypeCode                   VARCHAR(2)       DEFAULT ''                            NULL, -- ҵ������
  ------------------------------------------------------------------------------------------------------------
  openCloseFlagCode                VARCHAR(1)                                         NOT NULL, -- ��ƽ�ֱ�־
  longShortFlagCode                VARCHAR(1)                                         NOT NULL, -- �ֲַ����־
  hedgeFlagCode                    VARCHAR(1)                                         NOT NULL, -- Ͷ����־
  secuBizTypeCode                  VARCHAR(30)                                        NOT NULL, -- ֤ȯҵ��������
  ------------------------------------------------------------------------------------------------------------
  matchQty                         NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ɽ�����
  matchNetPrice                    NUMERIC(10,4)    DEFAULT 0                         NOT NULL, -- �ɽ��۸�
  matchNetAmt                      NUMERIC(19,4)    DEFAULT 0                         NOT NULL,                                                          
  matchSettlePrice                 NUMERIC(10,4)    DEFAULT 0                         NOT NULL,
  matchSettleAmt                   NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ɽ�������
  matchTradeFeeAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ɽ����׷��ý��
  cashSettleAmt             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ʽ�����
  ------------------------------------------------------------------------------------------------------------
  costChgAmt                       NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲֳɱ����䶯
  occupyCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲ�ռ�óɱ����䶯
  rlzChgProfit                     NUMERIC(19,4)    DEFAULT 0                         NOT NULL  -- �ֲ�ʵ��ӯ���䶯
)

CREATE TABLE #tt_prodCellCheckJrnlDBHist
(
  serialNO                         NUMERIC(19,0)                                      NOT NULL, -- ������
  createPosiDate                   VARCHAR(10)                                        NOT NULL, -- ��������
  settleDate                       VARCHAR(10)                                        NOT NULL, -- ��������
  -----------------------------------------------------------------------------------------------------------
  prodCode                         VARCHAR(30)                                        NOT NULL, -- ��Ʒ����
  prodCellCode                     VARCHAR(30)                                        NOT NULL, -- ��Ʒ��Ԫ����
  fundAcctCode                     VARCHAR(30)                                        NOT NULL, -- �ʽ��˻�����
  secuAcctCode                     VARCHAR(30)                                        NOT NULL, -- ֤ȯ�˻�����
  currencyCode                     VARCHAR(3)       DEFAULT 'CNY'                     NOT NULL, -- ���Ҵ���
  -----------------------------------------------------------------------------------------------------------
  exchangeCode                     VARCHAR(4)                                         NOT NULL, -- ����������
  secuCode                         VARCHAR(40)                                        NOT NULL, -- ֤ȯ����
  originSecuCode                   VARCHAR(40)      DEFAULT ''                            NULL, -- ԭʼ֤ȯ����
  secuTradeTypeCode                VARCHAR(30)                                        NOT NULL, -- ֤ȯ�������ʹ���
  ------------------------------------------------------------------------------------------------------------
  marketLevelCode                  VARCHAR(1)       DEFAULT '2'                       NOT NULL, -- �г���Դ
  transactionNO                    NUMERIC(19,0)    DEFAULT 1                         NOT NULL, -- ���ױ��
  investPortfolioCode              VARCHAR(30)                                        NOT NULL, -- Ͷ����ϴ���
  buySellFlagCode                  VARCHAR(1)                                         NOT NULL, -- ������־
  bizSubTypeCode                   VARCHAR(2)       DEFAULT ''                            NULL, -- ҵ������
  ------------------------------------------------------------------------------------------------------------
  openCloseFlagCode                VARCHAR(1)                                         NOT NULL, -- ��ƽ�ֱ�־
  longShortFlagCode                VARCHAR(1)                                         NOT NULL, -- �ֲַ����־
  hedgeFlagCode                    VARCHAR(1)                                         NOT NULL, -- Ͷ����־
  secuBizTypeCode                  VARCHAR(30)                                        NOT NULL, -- ֤ȯҵ��������
  ------------------------------------------------------------------------------------------------------------
  matchQty                         NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ɽ�����
  matchNetPrice                    NUMERIC(10,4)    DEFAULT 0                         NOT NULL, -- �ɽ��۸�
  matchNetAmt                      NUMERIC(19,4)    DEFAULT 0                         NOT NULL,                                                          
  matchSettlePrice                 NUMERIC(10,4)    DEFAULT 0                         NOT NULL,
  matchSettleAmt                   NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ɽ�������
  matchTradeFeeAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ɽ����׷��ý��
  cashSettleAmt             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ʽ�����
  ------------------------------------------------------------------------------------------------------------
  costChgAmt                       NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲֳɱ����䶯
  occupyCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲ�ռ�óɱ����䶯
  rlzChgProfit                     NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲ�ʵ��ӯ���䶯
  investCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- Ͷ�ʳֲֳɱ����䶯
  investOccupyCostChgAmt           NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- Ͷ�ʳֲ�ռ�óɱ����䶯
  investRlzChgProfit               NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- Ͷ�ʳֲ�ʵ��ӯ���䶯
  operateRemarkText                VARCHAR(255)     DEFAULT ' '                       NOT NULL
)

CREATE TABLE #tt_prodCellCreatePosiDateDB
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- ��Ʒ��Ԫ����
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --���������� 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ���� 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־ 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- ���ױ��
  investPortfolioCode              VARCHAR(40)        DEFAULT ''                      NOT NULL,          --Ͷ�����
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --��������
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --�ɱ��䶯���
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --����������
)

CREATE TABLE #tt_prodCellCreatePosiDateDBSum
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- ��Ʒ��Ԫ����
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --���������� 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ���� 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־ 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- ���ױ��
  investPortfolioCode              VARCHAR(40)        DEFAULT ''                      NOT NULL,          --Ͷ�����
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --��������
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --�ɱ��䶯���
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --����������
)

CREATE TABLE #tt_prodCellDBDetail
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- ��Ʒ��Ԫ����
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --���������� 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ���� 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־ 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- ���ױ��
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --Ͷ�����
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --��������
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  matchQty                         NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --�ɱ��䶯���
  rlzChgProfit                     NUMERIC(19,4)     DEFAULT 0                        NOT NULL,          --ʵ��ӯ���䶯���
)

CREATE TABLE #tt_prodCellDBSum
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- ��Ʒ��Ԫ����
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --���������� 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ���� 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־ 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- ���ױ��
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --Ͷ�����
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --��������
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  matchQty                         NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --�ɱ��䶯���
  rlzChgProfit                     NUMERIC(19,4)     DEFAULT 0                        NOT NULL,          --ʵ��ӯ���䶯���
)

CREATE TABLE #tt_prodCellDBCheckJrnl_old
(
  settleDate                       VARCHAR(10)                                        NOT NULL,          -- ��������
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- ��Ʒ��Ԫ����
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --���������� 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ���� 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־ 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- ���ױ��
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --Ͷ�����
  posiQty                          NUMERIC(19,4)                                      NOT NULL           -- �ֲ�����
)

 --ȡ��ǰ����
  DECLARE @v_today CHAR(10)
  SELECT @v_today = CONVERT(CHAR(10), GETDATE(), 20)
 --����ɱ����㿪ʼ����
 --todo
  DECLARE @v_realBeginDate CHAR(10) = '2000-01-01'
  
  IF @i_beginDate > @v_realBeginDate
    SELECT @v_realBeginDate = @i_beginDate
 
 --�ж��ʽ��˻��Ƿ�������
 --todo

  --ɾ����Ʒծȯ������ˮ
  DELETE sims2016TradeHist..prodCellCheckJrnlDBHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
                            
  --������ȯ���׳ɽ�
  --301ծ��ȯ����  
  --302ծ��ȯ����
  INSERT INTO #tt_prodCellRawJrnlDBHist(groupID, shareRecordDate, serialNO, settleDate,
                                      prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                      exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                      marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                      openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                      matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                      costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                      --��Ԫծȯ���㽻�ױ����Ϊ1,Ͷ����ϴ�����Ϊ' ' 
                               SELECT 0 AS groupID, ' ' AS shareRecordDate, MAX(serialNO), settleDate,
                                      prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,   
                                      exchangeCode, secuCode, MAX(originSecuCode), MAX(secuTradeTypeCode),
                                      marketLevelCode, 1 AS transactionNO , ' ' AS investPortfolioCode, MAX(buySellFlagCode), MAX(bizSubTypeCode),
                                      openCloseFlagCode, '1' AS longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                      SUM(ABS(matchQty)), CASE WHEN SUM(matchQty) = 0 THEN 0
                                      ELSE SUM(matchQty * matchNetPrice) / SUM(matchQty)END AS matchNetPrice,
                                        SUM(matchNetAmt),                                                          
                                 CASE WHEN SUM(matchQty) = 0 THEN 0
                                      ELSE SUM(matchQty * matchSettlePrice) / SUM(matchQty)END AS matchSettlePrice ,
                                      SUM(matchSettleAmt), SUM(matchTradeFeeAmt), SUM(cashSettleAmt),
                                      SUM(-cashSettleAmt) AS costChgAmt , SUM(-cashSettleAmt) AS occupyCostChgAmt , 0 AS rlzChgProfit     
                                 FROM sims2016TradeHist..prodCellRawJrnlDBHist a        
                                WHERE settleDate >= @v_realBeginDate
                                       AND settleDate >= @i_beginDate
                                       AND settleDate <= @v_today  
                                       AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                       AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(originSecuCode, @i_secuCode) > 0) 
                                       AND secuBizTypeCode NOT IN('311', '312')
                             GROUP BY settleDate, prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, secuBizTypeCode, openCloseFlagCode
                             ORDER BY fundAcctCode, settleDate, prodCode, prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, secuBizTypeCode, openCloseFlagCode                            
  
       --��Ϣ�Ҹ���ˮ����  
       INSERT INTO #tt_prodCellRawJrnlDBHist(groupID, shareRecordDate, serialNO, settleDate,
                                             prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                             exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                             marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                             openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                             matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                             costChgAmt, occupyCostChgAmt, rlzChgProfit)  
                                      SELECT 0 AS groupID, '2017-05-04' AS shareRecordDate, serialNO, settleDate,
                                             prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,   
                                             exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                             marketLevelCode, transactionNO , investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                             openCloseFlagCode, '1' AS longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                             ABS(matchQty), CASE WHEN matchQty = 0 THEN 0
                                             ELSE matchQty * matchNetPrice / matchQty END AS matchNetPrice,
                                               matchNetAmt,                                                          
                                        CASE WHEN matchQty = 0 THEN 0
                                             ELSE matchQty * matchSettlePrice / matchQty END AS matchSettlePrice ,
                                             matchSettleAmt, matchTradeFeeAmt, cashSettleAmt,
                                             -cashSettleAmt AS costChgAmt , -cashSettleAmt AS occupyCostChgAmt , 0 AS rlzChgProfit     
                                        FROM sims2016TradeHist..prodCellRawJrnlDBHist a        
                                       WHERE settleDate >= @v_realBeginDate
                                             AND settleDate >= @i_beginDate
                                             AND settleDate <= @v_today
                                             AND secuBizTypeCode IN ('311', '312')  
                                             AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                             AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                             AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(originSecuCode, @i_secuCode) > 0) 
                                    ORDER BY fundAcctCode, settleDate, prodCode
                                    
                                    
  --�α����begin 
  DECLARE
    @v_groupID                          SMALLINT       ,--��������ID
    @v_shareRecordDate                  VARCHAR(10)    ,--�Ǽ�����
    @v_serialNO                         NUMERIC(19,0)  ,-- ������
    --createPosiDate                    VARCHAR(10)    ,-- ��������
    @v_settleDate                       VARCHAR(10)    ,-- ��������
    -------------------------------------------------------------
    @v_prodCode                         VARCHAR(30)    ,-- ��Ʒ����
    @v_prodCellCode                     VARCHAR(30)    ,-- ��Ʒ��Ԫ����
    @v_fundAcctCode                     VARCHAR(30)    ,-- �ʽ��˻�����
    @v_secuAcctCode                     VARCHAR(30)    ,-- ֤ȯ�˻�����
    @v_currencyCode                     VARCHAR(3)     ,-- ���Ҵ���
    -------------------------------------------------------------
    @v_exchangeCode                     VARCHAR(4)     ,-- ����������
    @v_secuCode                         VARCHAR(40)    ,-- ֤ȯ����
    @v_originSecuCode                   VARCHAR(40)    ,-- ԭʼ֤ȯ����
    @v_secuTradeTypeCode                VARCHAR(30)    ,-- ֤ȯ�������ʹ���
    --------------------------------------------------------------
    @v_marketLevelCode                  VARCHAR(1)     ,-- �г���Դ
    @v_transactionNO                    NUMERIC(19,0)  ,-- ���ױ��
    @v_investPortfolioCode              VARCHAR(30)    ,-- Ͷ����ϴ���
    @v_buySellFlagCode                  VARCHAR(1)     ,-- ������־
    @v_bizSubTypeCode                   VARCHAR(2)     ,-- ҵ������
    --------------------------------------------------------------
    @v_openCloseFlagCode                VARCHAR(1)     ,-- ��ƽ�ֱ�־
    @v_longShortFlagCode                VARCHAR(1)     ,-- �ֲַ����־
    @v_hedgeFlagCode                    VARCHAR(1)     ,-- Ͷ����־
    @v_secuBizTypeCode                  VARCHAR(30)    ,-- ֤ȯҵ��������
    --------------------------------------------------------------
    @v_matchQty                         NUMERIC(19,4)  ,-- �ɽ�����
    @v_matchNetPrice                    NUMERIC(10,4)  ,-- �ɽ��۸�
    @v_matchNetAmt                      NUMERIC(19,4)  , 
    @v_matchSettlePrice                 NUMERIC(10,4)  ,
    @v_matchSettleAmt                   NUMERIC(19,4)  ,-- �ɽ�������
    @v_matchTradeFeeAmt                 NUMERIC(19,4)  ,-- �ɽ����׷��ý��
    @v_cashCurrentSettleAmt             NUMERIC(19,4)  ,-- �ʽ�����
    --------------------------------------------------------------
    @v_costChgAmt                       NUMERIC(19,4)  ,-- �ֲֳɱ����䶯
    @v_occupyCostChgAmt                 NUMERIC(19,4)  ,-- �ֲ�ռ�óɱ����䶯
    @v_rlzChgProfit                     NUMERIC(19,4)  ,-- �ֲ�ʵ��ӯ���䶯  
  --�α����end
  --�������begin
    @v_createPosiDate                   VARCHAR(10)    ,--��������
    @v_posiQty                          NUMERIC(19,4)  ,--�ֲ�����
    @v_lastOperateDate                  VARCHAR(10)    ,--��󽨲�����
    @v_unitCost                         NUMERIC(19,4)   --��λ�ɱ�
   
  --�������end    
  DEClARE dbzh_mccjb CURSOR FOR SELECT groupID, shareRecordDate, serialNO, settleDate, 
                                       prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                       exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                       marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                       openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                       matchQty, matchNetPrice,matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt,
                                       costChgAmt, occupyCostChgAmt, rlzChgProfit 
                                  FROM #tt_prodCellRawJrnlDBHist  
                                 ORDER BY fundAcctCode, prodCode, secuAcctCode, currencyCode, 
                                       exchangeCode, secuCode, longShortFlagCode, hedgeFlagCode,
                                       marketLevelCode, secuBizTypeCode, settleDate, groupID, openCloseFlagCode DESC                                                                                       
                             
  OPEN dbzh_mccjb  
  FETCH dbzh_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
                        @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                        @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                        @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                        @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                        @v_matchQty,@v_matchNetPrice, @v_matchNetAmt, @v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                        @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit 
                       
   --��������
  DECLARE @loop_fundAcctCode VARCHAR(20)
  SELECT @loop_fundAcctCode = NULL                         
                       
  WHILE 1 = 1
    BEGIN
      IF @loop_fundAcctCode IS NOT NULL AND (@loop_fundAcctCode != @v_fundAcctCode OR @@FETCH_STATUS != 0)
        BEGIN
          INSERT sims2016TradeHist..prodCellCheckJrnlDBHist(createPosiDate, settleDate, 
                                                            prodCode, prodCellCode, fundAcctCode, secuAcctCode,  currencyCode, 
                                                            exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                            marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                            openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                            matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                            costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                            investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, 
                                                            operatorCode, operateDatetime, operateRemarkText)
                                                     SELECT createPosiDate, settleDate, 
                                                            prodCode, prodCellCode, fundAcctCode, 'DEFAULT' AS secuAcctCode, currencyCode, 
                                                            exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                            marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                            openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                            matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                            costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                            investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit,  
                                                            @i_operatorCode, GETDATE(), operateRemarkText FROM #tt_prodCellCheckJrnlDBHist
          TRUNCATE TABLE #tt_prodCellCheckJrnlDBHist          
        END 
        
      IF @@FETCH_STATUS != 0
        break
      
      IF @loop_fundAcctCode IS NULL OR (@v_fundAcctCode != @loop_fundAcctCode)
        BEGIN
          SELECT @loop_fundAcctCode = @v_fundAcctCode
          TRUNCATE TABLE #tt_prodCellCreatePosiDateDBSum
          TRUNCATE TABLE #tt_prodCellCreatePosiDateDB
          
          INSERT INTO #tt_prodCellCreatePosiDateDB(prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                     longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,  
                                                     createPosiDate, posiQty, costChgAmt, lastOperateDate)
                                              SELECT prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                     longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,  
                                                      MAX(createPosiDate), SUM(matchQty), SUM(costChgAmt), MAX(settleDate)
                                                 FROM sims2016TradeHist..prodCellCheckJrnlDBHist
                                                WHERE settleDate < @v_realBeginDate -- AND settleDate > �������� (���������ձ���ƺú���ϴ�����)
                                                  AND fundAcctCode = @v_fundAcctCode
                                                  AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                                  AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
                                                GROUP BY prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                      longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode
                                                HAVING SUM(matchQty) > 0
    
        INSERT INTO #tt_prodCellCreatePosiDateDBSum(prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                    longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode, 
                                                    createPosiDate, posiQty, costChgAmt, lastOperateDate)
                                             SELECT prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                    longShortFlagCode, hedgeFlagCode, marketLevelCode, 1  AS transactionNO,' ' AS investPortfolioCode,  
                                                    MAX(createPosiDate), SUM(posiQty), SUM(costChgAmt), MAX(lastOperateDate)
                                               FROM #tt_prodCellCreatePosiDateDB
                                              GROUP BY prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                    longShortFlagCode, hedgeFlagCode, marketLevelCode
                                             HAVING SUM(posiQty) > 0
          
          
        END
      -----------------------------ծȯ��Ϣ------------------------------  
      IF @v_secuBizTypeCode = '311' or (@v_secuBizTypeCode = '312' and @v_matchQty = 0)
        BEGIN   
         
          UPDATE #tt_prodCellCreatePosiDateDBSum SET posiQty = a.posiQty + @v_matchQty,
                            costChgAmt = a.costChgAmt + @v_costChgAmt,
                            createPosiDate = CASE WHEN a.posiQty <= 0 THEN @v_settleDate ELSE a.createPosiDate END
                      FROM #tt_prodCellCreatePosiDateDBSum a
                      WHERE exchangeCode = @v_exchangeCode
                            AND secuCode = @v_secuCode
                            AND prodCellCode = @v_prodCellCode
                            --AND a.investPortfolioCode = b.investPortfolioCode
                            --AND a.transactionNO = b.transactionNO                 
                            AND secuAcctCode = @v_secuAcctCode
                            AND currencyCode = @v_currencyCode
                            AND exchangeCode = @v_exchangeCode
                            AND hedgeFlagCode = @v_hedgeFlagCode
                            AND marketLevelCode = @v_marketLevelCode            
          
          INSERT INTO #tt_prodCellCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                                   prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                   exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                   marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                   openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                   matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                   costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                                   investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                            SELECT @v_serialNO, @v_createPosiDate, @v_settleDate,
                                                   @v_prodCode, @v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                                   @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                                   @v_marketLevelCode,@v_transactionNO,' ' AS investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                                   @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                                   @v_matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,-(@v_costChgAmt-@v_rlzChgProfit),
                                                   @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit,
                                                   @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit
                            
        END
     ------------------------------ծȯ�Ҹ�------------------------------   
     ELSE IF @v_secuBizTypeCode = '312' and @v_matchQty <> 0
       BEGIN    
              
          SELECT @v_costChgAmt = -costChgAmt FROM #tt_prodCellCreatePosiDateDBSum 
                 WHERE prodCellCode = @v_prodCellCode
                       --AND investPortfolioCode = @v_investPortfolioCode
                       --AND transactionNO = @v_transactionNO                 
                       AND secuAcctCode = @v_secuAcctCode
                       AND currencyCode = @v_currencyCode
                       AND exchangeCode = @v_exchangeCode
                       AND secuCode = @v_secuCode
                       AND longShortFlagCode = @v_longShortFlagCode
                       AND hedgeFlagCode = @v_hedgeFlagCode
                       AND marketLevelCode = @v_marketLevelCode    
        
          DELETE FROM #tt_prodCellCreatePosiDateDBSum 
                 WHERE prodCellCode = @v_prodCellCode
                       --AND investPortfolioCode = @v_investPortfolioCode
                       --AND transactionNO = @v_transactionNO                 
                       AND secuAcctCode = @v_secuAcctCode
                       AND currencyCode = @v_currencyCode
                       AND exchangeCode = @v_exchangeCode
                       AND secuCode = @v_secuCode
                       AND longShortFlagCode = @v_longShortFlagCode
                       AND hedgeFlagCode = @v_hedgeFlagCode
                       AND marketLevelCode = @v_marketLevelCode   
          
          INSERT INTO #tt_prodCellCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                                 prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                 exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                 marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                 openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                 matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                 costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                                 investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                          SELECT @v_serialNO,' ' AS createPosiDate, @v_settleDate,
                                                 @v_prodCode, @v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                                 @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                                 @v_marketLevelCode,@v_transactionNO, ' ' AS investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                                 @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                                 @v_matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                                 @v_costChgAmt,@v_occupyCostChgAmt,@v_costChgAmt + @v_cashCurrentSettleAmt ,
                                                 @v_costChgAmt,@v_occupyCostChgAmt,@v_costChgAmt + @v_cashCurrentSettleAmt 
       END
      
      ---------------------------------------��ȯ���봦��-------------------------------------------------------  
      ELSE IF @v_secuBizTypeCode = '301'
        BEGIN
          SELECT @v_createPosiDate  = NULL
          SELECT @v_posiQty         = NULL
          SELECT @v_lastOperateDate = NULL
          
          SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastOperateDate = lastOperateDate
                 FROM #tt_prodCellCreatePosiDateDBSum
                 WHERE prodCellCode = @v_prodCellCode
                       --AND investPortfolioCode = @v_investPortfolioCode
                       --AND transactionNO = @v_transactionNO                 
                       AND secuAcctCode = @v_secuAcctCode
                       AND currencyCode = @v_currencyCode
                       AND exchangeCode = @v_exchangeCode
                       AND secuCode = @v_secuCode
                       AND longShortFlagCode = @v_longShortFlagCode
                       AND hedgeFlagCode = @v_hedgeFlagCode
                       AND marketLevelCode = @v_marketLevelCode         
          IF @v_createPosiDate IS NULL
            BEGIN
              INSERT INTO #tt_prodCellCreatePosiDateDBSum(prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                          longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode, 
                                                          createPosiDate, posiQty, costChgAmt, lastOperateDate)
                                                   VALUES(@v_prodCellCode, @v_secuAcctCode, @v_currencyCode, @v_exchangeCode, @v_secuCode, 
                                                          @v_longShortFlagCode, @v_hedgeFlagCode, @v_marketLevelCode, @v_transactionNO, @v_investPortfolioCode, 
                                                          @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate)
              SELECT @v_createPosiDate = @v_settleDate                                           
            END
          ELSE IF @v_posiQty <= 0 AND @v_lastOperateDate != @v_settleDate
            BEGIN
              UPDATE #tt_prodCellCreatePosiDateDBSum SET createPosiDate = @v_settleDate, posiQty = @v_matchQty, costChgAmt = @v_costChgAmt, lastOperateDate = @v_settleDate
                                                       WHERE prodCellCode = @v_prodCellCode
                                                             --AND investPortfolioCode = @v_investPortfolioCode
                                                             --AND transactionNO = @v_transactionNO                 
                                                             AND secuAcctCode = @v_secuAcctCode
                                                             AND currencyCode = @v_currencyCode
                                                             AND exchangeCode = @v_exchangeCode
                                                             AND secuCode = @v_secuCode
                                                             AND longShortFlagCode = @v_longShortFlagCode
                                                             AND hedgeFlagCode = @v_hedgeFlagCode
                                                             AND marketLevelCode = @v_marketLevelCode   
            END
          ELSE
            BEGIN
              UPDATE #tt_prodCellCreatePosiDateDBSum SET createPosiDate = @v_settleDate, 
                                                     posiQty = posiQty + @v_matchQty, 
                                                     costChgAmt = costChgAmt + @v_costChgAmt, 
                                                     lastOperateDate = @v_settleDate
                                               WHERE prodCellCode = @v_prodCellCode
                                                     --AND investPortfolioCode = @v_investPortfolioCode
                                                     --AND transactionNO = @v_transactionNO                 
                                                     AND secuAcctCode = @v_secuAcctCode
                                                     AND currencyCode = @v_currencyCode
                                                     AND exchangeCode = @v_exchangeCode
                                                     AND secuCode = @v_secuCode
                                                     AND longShortFlagCode = @v_longShortFlagCode
                                                     AND hedgeFlagCode = @v_hedgeFlagCode
                                                     AND marketLevelCode = @v_marketLevelCode   
            END
                      
          INSERT INTO #tt_prodCellCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                                  prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                  exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                  marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                  openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                  matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                  costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                                  investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                          values (@v_serialNO, @v_createPosiDate, @v_settleDate,
                                                  @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                                  @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                                  @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                                  @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                                  @v_matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                                  @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit,
                                                  @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit)    
        END
      ------------------------------------------------��ȯ��������-------------------------------------------------
      ELSE IF @v_secuBizTypeCode = '302' 
        BEGIN         
          SELECT @v_unitCost = costChgAmt/posiQty, @v_posiQty = posiQty
                               FROM #tt_prodCellCreatePosiDateDBSum
                              WHERE prodCellCode = @v_prodCellCode
                                     --AND investPortfolioCode = @v_investPortfolioCode
                                     --AND transactionNO = @v_transactionNO                 
                                     AND secuAcctCode = @v_secuAcctCode
                                     AND currencyCode = @v_currencyCode
                                     AND exchangeCode = @v_exchangeCode
                                     AND secuCode = @v_secuCode
                                     AND longShortFlagCode = @v_longShortFlagCode
                                     AND hedgeFlagCode = @v_hedgeFlagCode
                                     AND marketLevelCode = @v_marketLevelCode   
                                     AND posiQty > 0
                                                                                
          IF @v_unitCost IS NULL OR @v_posiQty < @v_matchQty
            BEGIN
              PRINT '������ȯ��������'
                CLOSE dbzh_mccjb  
                DEALLOCATE dbzh_mccjb   
              RETURN
            END
            
          SElECT @v_costChgAmt = -ABS(@v_unitCost*@v_matchQty)
          SELECT @v_rlzChgProfit = ABS(@v_cashCurrentSettleAmt)-ABS(@v_unitCost*@v_matchQty)    
            
          UPDATE #tt_prodCellCreatePosiDateDBSum SET costChgAmt = costChgAmt - ABS(@v_unitCost*@v_matchQty), posiQty = posiQty - ABS(@v_matchQty) 
                               WHERE prodCellCode = @v_prodCellCode
                                     --AND investPortfolioCode = @v_investPortfolioCode
                                     --AND transactionNO = @v_transactionNO                 
                                     AND secuAcctCode = @v_secuAcctCode
                                     AND currencyCode = @v_currencyCode
                                     AND exchangeCode = @v_exchangeCode
                                     AND secuCode = @v_secuCode
                                     AND longShortFlagCode = @v_longShortFlagCode
                                     AND hedgeFlagCode = @v_hedgeFlagCode
                                     AND marketLevelCode = @v_marketLevelCode   
                                     AND posiQty > 0                                       
                                     
          INSERT INTO #tt_prodCellCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                                  prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                  exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                  marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                  openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                  matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                  costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                                  investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                          values (@v_serialNO, @v_createPosiDate, @v_settleDate,
                                                  @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                                  @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                                  @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                                  @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                                  -@v_matchQty,@v_matchNetPrice,@v_matchNetAmt, @v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                                  @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit,
                                                  @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit)                              
        END
                
      FETCH dbzh_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
                            @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                            @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                            @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                            @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                            @v_matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                            @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit        
    END                    
                       
  CLOSE dbzh_mccjb  
  DEALLOCATE dbzh_mccjb                                                                                             
  RETURN 0
go
   
--exec opCalcProdCellCheckJrnlDB '9999', '', '', '','', '', ''

----truncate table sims2016TradeHist..prodCellCheckJrnlDBHist
--select * from sims2016TradeHist..prodCellCheckJrnlDBHist where secuBizTypeCode in('311', '312')

--select * from sims2016TradeHist..portfolioCheckJrnlDBHist where secuBizTypeCode in('311', '312')

--select * from sims2016TradeHist..prodCellRawJrnlDBHist where secuBizTypeCode in('311', '312')

--select * FROM sims2016TradeHist..prodCellRawJrnlDBHist a where secuBizTypeCode in('311', '312')