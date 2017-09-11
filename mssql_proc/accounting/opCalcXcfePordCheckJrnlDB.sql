USE sims2016Proc
  go
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'opCalcXcfePordCheckJrnlDB')
  DROP PROC opCalcXcfePordCheckJrnlDB
go

CREATE PROC opCalcXcfePordCheckJrnlDB
  @i_operatorCode          VARCHAR(255)        ,           --����Ա����
  @i_operatorPassword      VARCHAR(255)        ,           --����Ա����
  @i_operateStationText    VARCHAR(4096)       ,           --������Ϣ
  @i_prodCode              VARCHAR(4096)       ,           --��Ʒ����
  @i_currencyCode          VARCHAR(256)        ,           --���Ҵ���
  @i_fundAcctCode          VARCHAR(20)         ,           --�ʽ��˻�
  @i_exchangeCode          VARCHAR(20)         ,           --����������
  @i_secuCode              VARCHAR(20)         ,           --֤ȯ����
  @i_beginDate             VARCHAR(10)  =  ' '             --��ʼ����  
AS
/***************************************************************************
-- Author : yugy
-- Version : 1.0
--    V1.0 �� ֧�����м���ȯ����
-- Date : 2017-08-29
-- Description : 
--   �����ҵ�����:��ȯ����,��ȯ����,ծȯ��Ϣ,ծȯ����
--1.��Ϣ�����Ϣ�ɱ��ͳֲֳɱ�,����ӯ�����仯
--2.��������ֲֳɱ���Ͷ�ʳɱ�,����ӯ�����仯
--   �������Ҫ��Ŀ: ���ڵ���������, �ʽ�����,
                     �ֲֳɱ��䶯,�ֲ�ռ�óɱ��䶯,�ֲ�ʵ��ӯ��,
								     Ͷ�ʳɱ��䶯,Ͷ��ռ�óɱ��䶯,Ͷ��ʵ��ӯ��,
								     ��Ϣ�ɱ��䶯,��Ϣ����(��Ϣʵ��ӯ��).
-- Function List : opCalcXcfePordCheckJrnlDB
-- History : 
-- note:


****************************************************************************/
SET NOCOUNT ON
CREATE TABLE #tt_prodRawJrnlDBHist
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
  cashCurrentSettleAmt             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ʽ�����
  ------------------------------------------------------------------------------------------------------------
  costChgAmt                       NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲֳɱ����䶯
  occupyCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲ�ռ�óɱ����䶯
  rlzChgProfit                     NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲ�ʵ��ӯ���䶯
  interestCostChgAmt               NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- ��Ϣ�ɱ��䶯
  interestRlzChgProfit             NUMERIC(19,4)    DEFAULT 0                         NOT NULL  -- ��Ϣʵ��ӯ���䶯
  
)

CREATE TABLE #tt_prodCheckJrnlDBHist
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
  cashCurrentSettleAmt             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ʽ�����
  ------------------------------------------------------------------------------------------------------------
  costChgAmt                       NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲֳɱ����䶯
  occupyCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲ�ռ�óɱ����䶯
  rlzChgProfit                     NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲ�ʵ��ӯ���䶯
  investCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- Ͷ�ʳֲֳɱ����䶯
  investOccupyCostChgAmt           NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- Ͷ�ʳֲ�ռ�óɱ����䶯
  investRlzChgProfit               NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- Ͷ�ʳֲ�ʵ��ӯ���䶯
  interestCostChgAmt               NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- ��Ϣ�ɱ��䶯
  interestRlzChgProfit             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- ��Ϣʵ��ӯ���䶯
  originInvestCostChgAmt           NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- ���ױ�Ͷ�ʳɱ��䶯
  originInvestRlzChgProfit         NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- ���ױ�Ͷ��ʵ��ӯ���䶯
  forexRlzChgProfit                NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �������
  operateRemarkText                VARCHAR(255)     DEFAULT ' '                       NOT NULL
)


CREATE TABLE #tt_prodCreatePosiDateDB
(
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --���������� 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ���� 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־ 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --��������
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --�ɱ��䶯���
  investCostChgAmt                 NUMERIC(19,4)                                      NOT NULL,          --Ͷ�ʳɱ��䶯���
  interestCostChgAmt               NUMERIC(19,4)    DEFAULT 0                         NOT NULL,          --��Ϣ�ɱ��䶯
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --����������
)

CREATE TABLE #tt_prodCreatePosiDateDBSum
(
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --���������� 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ���� 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־ 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --��������
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --�ɱ��䶯���
  investCostChgAmt                 NUMERIC(19,4)                                      NOT NULL,          --Ͷ�ʳɱ��䶯���
  interestCostChgAmt               NUMERIC(19,4)    DEFAULT 0                         NOT NULL,          --��Ϣ�ɱ��䶯
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --����������
)

 --ȡ��ǰ����
  DECLARE @v_today CHAR(10)
  SELECT @v_today = CONVERT(CHAR(10), GETDATE(), 20)
 --����ɱ����㿪ʼ����
 --todo
  DECLARE @v_realBeginDate CHAR(10) = '2000-01-01'
 
 --�ж��ʽ��˻��Ƿ�������
 --todo

  --ɾ����Ʒծȯ������ˮ
  DELETE sims2016TradeHist..prodCheckJrnlDBHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_prodCode = '' OR CHARINDEX(prodCode, @i_prodCode) > 0)               
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
                            
  --������ȯ���׳ɽ�
  --301ծ��ȯ����
  --302ծ��ȯ����
  INSERT INTO #tt_prodRawJrnlDBHist(groupID, shareRecordDate, serialNO, settleDate,
                                    prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                    exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                    marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                    openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                    matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashCurrentSettleAmt, 
                                    costChgAmt, occupyCostChgAmt, rlzChgProfit, interestCostChgAmt, interestRlzChgProfit)
                             -- ��Ʒ���� ��Ԫ�����ÿ�,��ϴ����ÿ�,Ͷ�ʱ���ó�1      
                             SELECT 0 AS groupID, ' ' AS shareRecordDate, MAX(serialNO), settleDate,
                                    prodCode, ' ' AS prodCellCode, fundAcctCode, secuAcctCode, currencyCode,   
                                    exchangeCode, secuCode, MAX(originSecuCode), MAX(secuTradeTypeCode),
                                    marketLevelCode, 1 AS transactionNo , ' ' AS investPortfolioCode, MAX(buySellFlagCode), MAX(bizSubTypeCode),
                                    openCloseFlagCode, '1' AS longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                    SUM(ABS(matchQty)), CASE WHEN SUM(matchQty) = 0 THEN 0
                                    ELSE SUM(matchQty * matchNetPrice) / SUM(matchQty)END AS matchNetPrice,
                                      SUM(matchNetAmt),                                                          
                               CASE WHEN SUM(matchQty) = 0 THEN 0
                                    ELSE SUM(matchQty * matchSettlePrice) / SUM(matchQty)END AS matchSettlePrice,
                                    SUM(matchSettleAmt), SUM(matchTradeFeeAmt), SUM(cashSettleAmt),
                                    SUM(-cashSettleAmt) AS costChgAmt , SUM(-cashSettleAmt) AS occupyCostChgAmt , 0 AS rlzChgProfit, SUM(accrueInterestAmt) AS interestCostChgAmt, 0  
                               FROM sims2016TradeHist..prodRawJrnlDBHist a        
                           WHERE settleDate >= @v_realBeginDate
                                     AND settleDate >= @i_beginDate
                                     AND settleDate <= @v_today
                                     AND secuBizTypeCode  IN ('301', '302')   
                                     AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                     AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                     AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(originSecuCode, @i_secuCode) > 0)
                           GROUP BY settleDate, prodCode, fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, secuBizTypeCode, openCloseFlagCode
                           ORDER BY fundAcctCode, settleDate, prodCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, secuBizTypeCode, openCloseFlagCode                            
  
    --��������ˮ  
       INSERT INTO #tt_prodRawJrnlDBHist(groupID, shareRecordDate, serialNO, settleDate,
                                         prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                         exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                         marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                         openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                         matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashCurrentSettleAmt, 
                                         costChgAmt, occupyCostChgAmt, rlzChgProfit, interestCostChgAmt, interestRlzChgProfit)  
                                  SELECT 0 AS groupID, settleDate AS shareRecordDate, serialNO, settleDate,
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
                                         -cashSettleAmt AS costChgAmt , -cashSettleAmt AS occupyCostChgAmt , 0 AS rlzChgProfit , accrueInterestAmt AS interestCostChgAmt , 0   
                                    FROM sims2016TradeHist..prodRawJrnlDBHist a        
                                   WHERE settleDate >= @v_realBeginDate
                                         AND settleDate >= @i_beginDate
                                         AND settleDate <= @v_today
                                         AND secuBizTypeCode NOT IN ('301', '302')  
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
    @v_interestCostChgAmt               NUMERIC(19,4)  ,-- ��Ϣ�ɱ����䶯
    @v_occupyCostChgAmt                 NUMERIC(19,4)  ,-- �ֲ�ռ�óɱ����䶯
    @v_rlzChgProfit                     NUMERIC(19,4)  ,-- �ֲ�ʵ��ӯ���䶯  
  --�α����end
  --�������begin
    @v_createPosiDate                   VARCHAR(10)    ,--��������
    @v_posiQty                          NUMERIC(19,4)  ,--�ֲ�����
    @v_lastOperateDate                  VARCHAR(10)    ,--��󽨲�����
    @v_investCostChgAmt                 NUMERIC(19,4)  ,
    @v_investRlzProfit                  NUMERIC(19,4)  ,
    @v_interestRlzProfit                NUMERIC(19,4)  ,
    @v_netMatchAmt                      NUMERIC(19,4)  ,
    @v_unitCost                         NUMERIC(19,4)  ,--��λ�ɱ�
    @v_unitNetCost                      NUMERIC(19,4)  ,--��λ���ɱ�
    @v_unitInterestCost                 NUMERIC(19,4)  , --��λ��Ϣ�ɱ�
    @v_interestCostChgAmt_sell          NUMERIC(19,4)
   
  --�������end    
  DEClARE db_mccjb CURSOR FOR SELECT groupID, shareRecordDate, serialNO, settleDate, 
                                     prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                     exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                     marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                     openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                     matchQty, matchNetPrice,matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashCurrentSettleAmt,
                                     costChgAmt, occupyCostChgAmt, rlzChgProfit, interestCostChgAmt 
                                FROM #tt_prodRawJrnlDBHist  
                               ORDER BY fundAcctCode, prodCode, secuAcctCode, currencyCode, 
                                     exchangeCode, secuCode, longShortFlagCode, hedgeFlagCode,
                                     marketLevelCode, settleDate, secuBizTypeCode,  groupID, openCloseFlagCode DESC 
                                                             
  OPEN db_mccjb  
  FETCH db_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
                      @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                      @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                      @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                      @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                      @v_matchQty,@v_matchNetPrice, @v_matchNetAmt, @v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                      @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit, @v_interestCostChgAmt 
                       
   --��������
  DECLARE @loop_fundAcctCode VARCHAR(20)
  SELECT @loop_fundAcctCode = NULL                         
                       
  WHILE 1 = 1
    BEGIN
      IF @loop_fundAcctCode IS NOT NULL AND (@loop_fundAcctCode != @v_fundAcctCode OR @@FETCH_STATUS != 0)
        BEGIN
          INSERT sims2016TradeHist..prodCheckJrnlDBHist(createPosiDate, settleDate, 
                                                        prodCode, fundAcctCode, currencyCode, secuAcctCode,
                                                        exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                        marketLevelCode, buySellFlagCode, bizSubTypeCode, 
                                                        openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                        matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                        costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                        investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, interestCostChgAmt, interestRlzChgProfit,
                                                        operatorCode, operateDatetime, operateRemarkText)
                                                 SELECT createPosiDate, settleDate, 
                                                        prodCode, fundAcctCode, currencyCode, secuAcctCode,
                                                        exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                        marketLevelCode, buySellFlagCode, bizSubTypeCode, 
                                                        openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                        matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashCurrentSettleAmt, 
                                                        costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                        investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, interestCostChgAmt, interestRlzChgProfit,
                                                        @i_operatorCode, GETDATE(), operateRemarkText FROM #tt_prodCheckJrnlDBHist
          TRUNCATE TABLE #tt_prodCheckJrnlDBHist          
        END 
        
      IF @@FETCH_STATUS != 0
        break
      
      IF @loop_fundAcctCode IS NULL OR (@v_fundAcctCode != @loop_fundAcctCode)
        BEGIN
          SELECT @loop_fundAcctCode = @v_fundAcctCode
          TRUNCATE TABLE #tt_prodCreatePosiDateDBSum
          TRUNCATE TABLE #tt_prodCreatePosiDateDB
    
        INSERT INTO #tt_prodCreatePosiDateDBSum(secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                longShortFlagCode, hedgeFlagCode, marketLevelCode, 
                                                createPosiDate, posiQty, costChgAmt, lastOperateDate)
                                        SELECT secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                               longShortFlagCode, hedgeFlagCode, marketLevelCode, 
                                                MAX(createPosiDate), SUM(posiQty), SUM(costChgAmt), MAX(lastOperateDate)
                                          FROM #tt_prodCreatePosiDateDB
                                         GROUP BY secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                               longShortFlagCode, hedgeFlagCode, marketLevelCode
                                        HAVING SUM(posiQty) > 0
        END
      
      
      -----------------------------ծȯ��Ϣ,��������------------------------------  
      IF @v_secuBizTypeCode = '311' OR (@v_secuBizTypeCode = '312' and @v_matchQty = 0) 
        BEGIN    
          --UPDATE #tt_prodCreatePosiDateDBSum SET posiQty = a.posiQty + @v_matchQty,
          --                  costChgAmt = a.costChgAmt + @v_costChgAmt,
          --                  createPosiDate = CASE WHEN a.posiQty <= 0 THEN @v_settleDate ELSE a.createPosiDate END
          --            FROM #tt_prodCreatePosiDateDBSum a
          --            WHERE exchangeCode = @v_exchangeCode
          --                  AND secuCode = @v_secuCode
          --                  --AND prodCellCode = @v_prodCellCode
          --                  --AND a.investPortfolioCode = b.investPortfolioCode
          --                  --AND a.transactionNO = b.transactionNO                 
          --                  AND secuAcctCode = @v_secuAcctCode
          --                  AND currencyCode = @v_currencyCode
          --                  AND exchangeCode = @v_exchangeCode
          --                  AND hedgeFlagCode = @v_hedgeFlagCode
          --                  AND marketLevelCode = @v_marketLevelCode
          
         --��Ϣ�����Ϣ�ɱ�,�ֲֳɱ�,ӯ������
         --��������ֲֳɱ�,Ͷ�ʳɱ�,ӯ������
         IF @v_secuBizTypeCode = '311' 
           SELECT @v_netMatchAmt = 0, @v_interestCostChgAmt = @v_costChgAmt
         ElSE
					 SELECT @v_netMatchAmt = @v_costChgAmt, @v_interestCostChgAmt = 0
					                                                                           
         ----------------------------------------------------------------------------------------------------------------------------------------------------                   
				 UPDATE #tt_prodCreatePosiDateDBSum SET /*createPosiDate = @v_settleDate,*/
				                                        costChgAmt = costChgAmt + @v_costChgAmt,
																								interestCostChgAmt= interestCostChgAmt +  @v_interestCostChgAmt,
																								investCostChgAmt = investCostChgAmt + @v_netMatchAmt,
																								lastOperateDate = @v_settleDate
																						 WHERE secuAcctCode = @v_secuAcctCode
																									 AND currencyCode = @v_currencyCode
																									 AND exchangeCode = @v_exchangeCode
																									 AND secuCode = @v_secuCode
																									 AND longShortFlagCode = @v_longShortFlagCode
																									 AND hedgeFlagCode = @v_hedgeFlagCode
																									 AND marketLevelCode = @v_marketLevelCode                              
          ---------------------------------------------------------------------------------------------------------------------------------------------------
          INSERT INTO #tt_prodCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                               prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                               exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                               marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                               openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                               matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashCurrentSettleAmt, 
                                               costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                               investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, 
                                               interestCostChgAmt, interestRlzChgProfit)
                                        SELECT @v_serialNO, @v_createPosiDate, @v_settleDate,
                                               @v_prodCode, @v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                               @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                               @v_marketLevelCode,@v_transactionNO,' ' AS investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                               @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                               @v_matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,-(@v_costChgAmt-@v_rlzChgProfit),
                                               @v_costChgAmt,@v_costChgAmt,0,
                                               @v_netMatchAmt,@v_netMatchAmt,0,
                                               @v_interestCostChgAmt, 0
                            
        END
     ------------------------------ծȯ�Ҹ�------------------------------   
     ELSE IF @v_secuBizTypeCode = '312' and @v_matchQty <> 0
       BEGIN
       
         SELECT @v_costChgAmt = -costChgAmt FROM #tt_prodCreatePosiDateDBSum
                 WHERE --prodCellCode = @v_prodCellCode
                       --AND investPortfolioCode = @v_investPortfolioCode
                       --AND transactionNO = @v_transactionNO                 
                        secuAcctCode = @v_secuAcctCode
                       AND currencyCode = @v_currencyCode
                       AND exchangeCode = @v_exchangeCode
                       AND secuCode = @v_secuCode
                       AND longShortFlagCode = @v_longShortFlagCode
                       AND hedgeFlagCode = @v_hedgeFlagCode
                       AND marketLevelCode = @v_marketLevelCode 
          
          DELETE FROM #tt_prodCreatePosiDateDBSum 
                 WHERE --prodCellCode = @v_prodCellCode
                       --AND investPortfolioCode = @v_investPortfolioCode
                       --AND transactionNO = @v_transactionNO                 
                        secuAcctCode = @v_secuAcctCode
                       AND currencyCode = @v_currencyCode
                       AND exchangeCode = @v_exchangeCode
                       AND secuCode = @v_secuCode
                       AND longShortFlagCode = @v_longShortFlagCode
                       AND hedgeFlagCode = @v_hedgeFlagCode
                       AND marketLevelCode = @v_marketLevelCode   
          
          INSERT INTO #tt_prodCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                             prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                             exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                             marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                             openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                             matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashCurrentSettleAmt, 
                                             costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                             investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                      SELECT @v_serialNO,' ' AS createPosiDate, @v_settleDate,
                                             @v_prodCode, @v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                             @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                             @v_marketLevelCode,@v_transactionNO, ' ' AS investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                             @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                             @v_matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                             @v_costChgAmt,@v_occupyCostChgAmt,@v_costChgAmt + @v_cashCurrentSettleAmt,
                                             @v_costChgAmt,@v_occupyCostChgAmt,@v_costChgAmt + @v_cashCurrentSettleAmt
       END 
      ---------------------------------------��ȯ���봦��-------------------------------------------------------  
     ELSE IF @v_secuBizTypeCode = '301'
        BEGIN
          SELECT @v_createPosiDate  = NULL
          SELECT @v_posiQty         = NULL
          SELECT @v_lastOperateDate = NULL
          SELECT @v_netMatchAmt = ABS(@v_matchNetAmt) + ABS(@v_matchTradeFeeAmt)
          
          
          SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastOperateDate = lastOperateDate
                 FROM #tt_prodCreatePosiDateDBSum
                 WHERE secuAcctCode = @v_secuAcctCode
                       AND currencyCode = @v_currencyCode
                       AND exchangeCode = @v_exchangeCode
                       AND secuCode = @v_secuCode
                       AND longShortFlagCode = @v_longShortFlagCode
                       AND hedgeFlagCode = @v_hedgeFlagCode
                       AND marketLevelCode = @v_marketLevelCode         
          IF @v_createPosiDate IS NULL
            BEGIN
              INSERT INTO #tt_prodCreatePosiDateDBSum(secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                      longShortFlagCode, hedgeFlagCode, marketLevelCode, 
                                                      createPosiDate, posiQty, costChgAmt, interestCostChgAmt, investCostChgAmt, lastOperateDate)
                                               VALUES(@v_secuAcctCode, @v_currencyCode, @v_exchangeCode, @v_secuCode, 
                                                      @v_longShortFlagCode, @v_hedgeFlagCode, @v_marketLevelCode, 
                                                      @v_settleDate, @v_matchQty, @v_costChgAmt, @v_interestCostChgAmt, @v_netMatchAmt, @v_settleDate)
              SELECT @v_createPosiDate = @v_settleDate                                           
            END
          ELSE IF @v_posiQty <= 0 AND @v_lastOperateDate != @v_settleDate
            BEGIN
              UPDATE #tt_prodCreatePosiDateDBSum SET createPosiDate = @v_settleDate, posiQty = @v_matchQty, costChgAmt = @v_costChgAmt,
                                                     interestCostChgAmt= @v_interestCostChgAmt,investCostChgAmt = @v_netMatchAmt, lastOperateDate = @v_settleDate
                                                 WHERE secuAcctCode = @v_secuAcctCode
                                                       AND currencyCode = @v_currencyCode
                                                       AND exchangeCode = @v_exchangeCode
                                                       AND secuCode = @v_secuCode
                                                       AND longShortFlagCode = @v_longShortFlagCode
                                                       AND hedgeFlagCode = @v_hedgeFlagCode
                                                       AND marketLevelCode = @v_marketLevelCode
            END
          ELSE
            BEGIN
              UPDATE #tt_prodCreatePosiDateDBSum SET createPosiDate = @v_settleDate, 
                                                     posiQty = posiQty + @v_matchQty, 
                                                     costChgAmt = costChgAmt + @v_costChgAmt,
                                                     interestCostChgAmt = interestCostChgAmt + @v_interestCostChgAmt, 
                                                     investCostChgAmt = investCostChgAmt + @v_netMatchAmt,
                                                     lastOperateDate = @v_settleDate
                                               WHERE secuAcctCode = @v_secuAcctCode
                                                     AND currencyCode = @v_currencyCode
                                                     AND exchangeCode = @v_exchangeCode
                                                     AND secuCode = @v_secuCode
                                                     AND longShortFlagCode = @v_longShortFlagCode
                                                     AND hedgeFlagCode = @v_hedgeFlagCode
                                                     AND marketLevelCode = @v_marketLevelCode
            END
            
            
          INSERT INTO #tt_prodCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                              prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                              exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                              marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                              openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                              matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashCurrentSettleAmt, 
                                              costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                              investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, interestCostChgAmt)
                                      values (@v_serialNO, @v_createPosiDate, @v_settleDate,
                                              @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                              @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                              @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                              @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                              @v_matchQty, @v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                              @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit,
                                              @v_netMatchAmt,@v_netMatchAmt,@v_rlzChgProfit, @v_interestCostChgAmt)    
        END
      ------------------------------------------------��ȯ��������-------------------------------------------------
      ELSE IF @v_secuBizTypeCode = '302' 
        BEGIN         
        
          SELECT @v_unitCost = costChgAmt/posiQty,
                 @v_unitNetCost = investCostChgAmt/posiQty,
                 @v_unitInterestCost = interestCostChgAmt/posiQty,
                                     @v_posiQty = posiQty
                               FROM #tt_prodCreatePosiDateDBSum
                               WHERE secuAcctCode = @v_secuAcctCode
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
              RETURN
            END
            
          SElECT @v_costChgAmt = -(@v_unitCost*@v_matchQty)
          SELECT @v_rlzChgProfit = ABS(@v_cashCurrentSettleAmt)-(@v_unitCost*@v_matchQty)
          
          SElECT @v_investCostChgAmt = -(@v_unitNetCost*@v_matchQty)
          SELECT @v_investRlzProfit = ABS(@v_matchNetAmt + @v_matchTradeFeeAmt)-(@v_unitNetCost*@v_matchQty)  
          
          SElECT @v_interestCostChgAmt_sell = -(@v_unitInterestCost*@v_matchQty)
          SELECT @v_interestRlzProfit = -(@v_unitInterestCost*@v_matchQty) - @v_interestCostChgAmt
                                       
          UPDATE #tt_prodCreatePosiDateDBSum SET costChgAmt = costChgAmt - ABS(@v_unitCost*@v_matchQty), posiQty = posiQty - ABS(@v_matchQty) 
              WHERE secuAcctCode = @v_secuAcctCode
                    AND currencyCode = @v_currencyCode
                    AND exchangeCode = @v_exchangeCode
                    AND secuCode = @v_secuCode
                    AND longShortFlagCode = @v_longShortFlagCode
                    AND hedgeFlagCode = @v_hedgeFlagCode
                    AND marketLevelCode = @v_marketLevelCode
                    AND posiQty > 0  
                                     
          INSERT INTO #tt_prodCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                              prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                              exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                              marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                              openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                              matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashCurrentSettleAmt, 
                                              costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                              investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, interestCostChgAmt, interestRlzChgProfit)
                                      values (@v_serialNO, @v_createPosiDate, @v_settleDate,
                                              @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                              @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                              @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                              @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                              @v_matchQty,@v_matchNetPrice,@v_matchNetAmt, @v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                              @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit,
                                              @v_investCostChgAmt,-ABS(@v_matchNetAmt) - ABS(@v_matchTradeFeeAmt),@v_investRlzProfit, 
                                              @v_interestCostChgAmt_sell, @v_interestRlzProfit)                              
        END
        
                
      FETCH db_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
                          @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                          @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                          @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                          @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                          @v_matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                          @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit, @v_interestCostChgAmt        
    END                    
                       
  CLOSE db_mccjb  
  DEALLOCATE db_mccjb                                                                                             
  RETURN 0
go


