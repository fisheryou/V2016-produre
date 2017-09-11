USE sims2016Proc
	go

IF exists(SELECT 1 FROM sysobjects WHERE name = 'opCalcPortfolioCheckJrnlP')
	DROP PROC opCalcPortfolioCheckJrnlP
go

CREATE PROC opCalcPortfolioCheckJrnlP
  @i_operatorCode          VARCHAR(255)        ,           --����Ա����
  @i_operatorPassword      VARCHAR(255)        ,           --����Ա����
  @i_operateStationText    VARCHAR(4096)       ,           --������Ϣ
  @i_fundAcctCode          VARCHAR(20)         ,           --�ʽ��˻�
  @i_exchangeCode          VARCHAR(20)         ,           --����������
  @i_secuCode              VARCHAR(20)         ,           --֤ȯ����
  @i_beginDate             VARCHAR(10)  =  ' '             --��ʼ����  
AS
SET NOCOUNT ON
  CREATE TABLE #tt_portfolioRawJrnlPHist
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
--matchNetAmt                      NUMERIC(19,4)    DEFAULT 0                         NOT NULL,                                                          
--matchSettlePrice                 NUMERIC(10,4)    DEFAULT 0                         NOT NULL,
  matchSettleAmt                   NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ɽ�������
  matchTradeFeeAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ɽ����׷��ý��
  cashSettleAmt             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ʽ�����
  ------------------------------------------------------------------------------------------------------------
  costChgAmt                       NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲֳɱ����䶯
  occupyCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- �ֲ�ռ�óɱ����䶯
  rlzChgProfit                     NUMERIC(19,4)    DEFAULT 0                         NOT NULL -- �ֲ�ʵ��ӯ���䶯
)

CREATE TABLE #tt_portfolioCheckJrnlPHist
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
--matchNetAmt                      NUMERIC(19,4)    DEFAULT 0                         NOT NULL,                                                          
--matchSettlePrice                 NUMERIC(10,4)    DEFAULT 0                         NOT NULL,
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

 CREATE TABLE #tt_portfolioCreatePosiDateP
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          --��Ʒ��Ԫ����         
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�							
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���							 
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --����������						
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ����							
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־							
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־							
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����							
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,          --���ױ��							 
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --Ͷ�����							
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --��������
  repurchaseDate                   VARCHAR(10)                                        NOT NULL,          --��������							
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����								               
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --�ɱ��䶯���
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --����������
)

CREATE TABLE #tt_portfolioCreatePosiDatePSum
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          --��Ʒ��Ԫ����
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --֤ȯ�˻�
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --���Ҵ���
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --���������� 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --֤ȯ���� 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --��ձ�־ 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --Ͷ����־
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --�г�����
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,          -- ���ױ��
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --Ͷ�����
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --��������
  repurchaseDate                   VARCHAR(10)                                        NOT NULL,          --��������
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --�ֲ�����
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --�ɱ��䶯���
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --����������
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
  DELETE sims2016TradeHist..portfolioCheckJrnlPHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
               
   --������Ѻʽ��ع�
   --333 ��ع� 335��ع�����
  INSERT INTO #tt_portfolioRawJrnlPHist (groupID, shareRecordDate, serialNO, settleDate,
                                         prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                         exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                         marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                         openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                         matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                         costChgAmt, occupyCostChgAmt, rlzChgProfit)  
                                  SELECT 0 AS groupID, ' ' AS shareRecordDate, MAX(serialNO), settleDate,
                                         prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,   
                                         exchangeCode, secuCode, MAX(originSecuCode), MAX(secuTradeTypeCode),
                                         marketLevelCode, transactionNO , investPortfolioCode, MAX(buySellFlagCode), MAX(bizSubTypeCode),
                                         openCloseFlagCode, '1' AS longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                         SUM(ABS(matchQty)), CASE WHEN SUM(matchQty) = 0 THEN 0
                                         ELSE SUM(matchQty * matchNetPrice) / SUM(matchQty)END AS matchNetPrice,                                                        
                                         SUM(matchSettleAmt), SUM(matchTradeFeeAmt), SUM(cashSettleAmt),
                                         SUM(-cashSettleAmt) AS costChgAmt , SUM(-cashSettleAmt) AS occupyCostChgAmt , 0 AS rlzChgProfit     
                                    FROM sims2016TradeHist..prodCellRawJrnlPHist a        
                                   WHERE settleDate >= @v_realBeginDate
                                         AND settleDate >= @i_beginDate
                                         AND settleDate <= @v_today  
                                         AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                         AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                         AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(originSecuCode, @i_secuCode) > 0) 
                                GROUP BY settleDate, prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, investPortfolioCode, transactionNO, secuBizTypeCode, openCloseFlagCode
                                ORDER BY fundAcctCode, settleDate, prodCode, prodCellCode, investPortfolioCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, transactionNO, secuBizTypeCode, openCloseFlagCode                                        

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
  DEClARE dr_mccjb CURSOR FOR SELECT groupID, shareRecordDate, serialNO, settleDate, 
                                       prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                       exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                       marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                       openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                       matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt,
                                       costChgAmt, occupyCostChgAmt, rlzChgProfit 
                                  FROM #tt_portfolioRawJrnlPHist  
                                 ORDER BY fundAcctCode, settleDate, prodCode, secuAcctCode, currencyCode, 
                                       exchangeCode, secuCode, longShortFlagCode, hedgeFlagCode,
                                       marketLevelCode, secuBizTypeCode,  groupID, openCloseFlagCode DESC                                                                                       
                             
  OPEN dr_mccjb  
  FETCH dr_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
                      @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                      @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                      @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                      @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                      @v_matchQty,@v_matchNetPrice, @v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                      @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit 
                       
   --��������
  DECLARE @loop_fundAcctCode VARCHAR(20)
  SELECT @loop_fundAcctCode = NULL 
  
   WHILE 1 = 1
    BEGIN
      IF @loop_fundAcctCode IS NOT NULL AND (@loop_fundAcctCode != @v_fundAcctCode OR @@FETCH_STATUS != 0)
        BEGIN
          INSERT sims2016TradeHist..portfolioCheckJrnlPHist(createPosiDate, settleDate, 
                                                            prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                            exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                            marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                            openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                            matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                            costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                            investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, 
                                                            operatorCode, operateDatetime, operateRemarkText)
                                                     SELECT createPosiDate, settleDate, 
                                                            prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                            exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                            marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                            openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                            matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                            costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                            investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit,  
                                                            @i_operatorCode, GETDATE(), operateRemarkText FROM #tt_portfolioCheckJrnlPHist
          TRUNCATE TABLE #tt_portfolioCheckJrnlPHist         
        END 
        
      IF @@FETCH_STATUS != 0
        break
      
      IF @loop_fundAcctCode IS NULL OR (@v_fundAcctCode != @loop_fundAcctCode)
        BEGIN
          SELECT @loop_fundAcctCode = @v_fundAcctCode
          
          TRUNCATE TABLE #tt_portfolioCreatePosiDateP
          TRUNCATE TABLE #tt_portfolioCreatePosiDatePSum
          
          INSERT INTO #tt_portfolioCreatePosiDateP(prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
																									 longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,  
																									 createPosiDate, repurchaseDate, posiQty, costChgAmt, lastOperateDate)
																						SELECT prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
																									 longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,  
																									 settleDate, MAX(dbo.fn_get_ghrq(settleDate, exchangeCode, secuCode)),SUM(matchQty), SUM(costChgAmt), MAX(settleDate)
																						 FROM sims2016TradeHist..portfolioCheckJrnlPHist
																						WHERE settleDate < @v_realBeginDate -- AND settleDate > �������� (���������ձ���ƺú���ϴ�����)
																							AND fundAcctCode = @v_fundAcctCode
																							AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
																							AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
																							AND secuBizTypeCode = '333'    --��ع�
																						GROUP BY prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
																									longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode, settleDate
																					 HAVING SUM(matchQty) > 0
																																																																		
          INSERT INTO #tt_portfolioCreatePosiDatePSum(prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
																											longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode, 
																											createPosiDate, repurchaseDate, posiQty, costChgAmt, lastOperateDate)
																							 SELECT prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
																											longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,  
																											createPosiDate, repurchaseDate, SUM(posiQty), SUM(costChgAmt), MAX(lastOperateDate)
																								 FROM #tt_portfolioCreatePosiDateP
																								GROUP BY prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
																											longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,createPosiDate, repurchaseDate
																							 HAVING SUM(posiQty) > 0                         
                                                                          
            
        END
      
      ---------------------------------------��ع�-------------------------------------------------------  
      IF @v_secuBizTypeCode = '333'
        BEGIN        
       
					INSERT INTO #tt_portfolioCreatePosiDatePSum(prodCellCode, secuAcctCode, currencyCode,
																										 exchangeCode, secuCode, longShortFlagCode,
																										 hedgeFlagCode, marketLevelCode, transactionNO,
																										 investPortfolioCode, createPosiDate, repurchaseDate,
																										 posiQty, costChgAmt, lastOperateDate)
																							values(@v_prodCellCode, @v_secuAcctCode, @v_currencyCode,
																										 @v_exchangeCode, @v_secuCode, @v_longShortFlagCode,
																										 @v_hedgeFlagCode, @v_marketLevelCode, @v_transactionNO,
																										 @v_investPortfolioCode, @v_settleDate, dbo.fn_get_ghrq(@v_settleDate, @v_exchangeCode, @v_secuCode),
																										 @v_matchQty, @v_matchSettleAmt, ' ')
         						                     
          INSERT INTO #tt_portfolioCheckJrnlPHist(serialNO, createPosiDate, settleDate,
                                                   prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                   exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                   marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                   openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                   matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                   costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                                   investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                           values (@v_serialNO, @v_settleDate, @v_settleDate,
                                                   @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                                   @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                                   @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                                   @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                                   @v_matchQty,@v_matchNetPrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                                   0, 0, 0,
                                                   0, 0, 0)    
        END
      ------------------------------------------------��ع�����-------------------------------------------------
      ELSE IF @v_secuBizTypeCode = '335' 
        BEGIN
        
					DECLARE @costChgAmt NUMERIC(19,4)
					SELECT @costChgAmt = costChgAmt FROM #tt_portfolioCreatePosiDatePSum
												                      WHERE secuAcctCode      =  @v_secuAcctCode
																								AND currencyCode      =  @v_currencyCode
																								AND	exchangeCode      =  @v_exchangeCode
																								AND	secuCode          =  @v_secuCode
																								AND	longShortFlagCode =  @v_longShortFlagCode
																								AND	hedgeFlagCode     =  @v_hedgeFlagCode
																								AND	marketLevelCode   =  @v_marketLevelCode
																								AND repurchaseDate    =  @v_settleDate		
																								
				 	select * from #tt_portfolioCreatePosiDatePSum																																								 	
					                        
          INSERT INTO #tt_portfolioCheckJrnlPHist(serialNO, createPosiDate, settleDate,
                                                   prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                   exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                   marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                   openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                   matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                   costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                                   investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                           values (@v_serialNO, @v_settleDate, @v_settleDate,
                                                   @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                                   @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                                   @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                                   @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                                   @v_matchQty,@v_matchNetPrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                                   0,@v_occupyCostChgAmt,@v_matchSettleAmt - @costChgAmt,
                                                   0,@v_occupyCostChgAmt,@v_matchSettleAmt - @costChgAmt)                              
        END
                
			FETCH dr_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
													@v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
													@v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
													@v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
													@v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
													@v_matchQty,@v_matchNetPrice, @v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
													@v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit     
    END                    
                       
  CLOSE dr_mccjb  
  DEALLOCATE dr_mccjb                 
	
	SELECT 0,'ִ�гɹ�!'
	RETURN 0
go

--FUNTION
--USE sims2016Proc
-- go
--IF object_id (N'fn_get_ghrq', N'FN') IS NOT NULL
--  DROP FUNCTION fn_get_ghrq
--go

--CREATE FUNCTION fn_get_ghrq
--(
--  @i_fsrq CHAR(10),
--  @i_exchangeCode VARCHAR(4),
--  @i_secuCode VARCHAR(8)
--)
--  RETURNS CHAR(10)
--AS
--  BEGIN
--    DECLARE @ghts INT
--    DECLARE @ghrq CHAR(10)

--    SELECT @ghts = repoMaturityValue FROM sims2016TradeToday..secuDetailCfgP WHERE exchangeCode = @i_exchangeCode and secuCode = @i_secuCode

--    SELECT @ghrq = convert(CHAR(10), dateadd(day, @ghts, @i_fsrq), 20)
--    SELECT @ghrq = min(tradeDate) FROM sims2016TradeToday..tradeCalender WHERE tradeDate >= @ghrq 

--    RETURN isnull(@ghrq, '')
--  END
--go
--select dbo.fn_get_ghrq ('2017-01-21', 'XSHG', '204001')
--select * from  sims2016TradeToday..tradeCalender
exec opCalcPortfolioCheckJrnlP '','', '', '', '', '', ''

select * from sims2016TradeToday..secuDetailCfgP
update sims2016TradeToday..secuDetailCfgP set repoMaturityValue = 7 where secuCode = '204007'

--select * from sims2016TradeHist..prodCellRawJrnlPHist
select * from sims2016TradeHist..portfolioCheckJrnlPHist