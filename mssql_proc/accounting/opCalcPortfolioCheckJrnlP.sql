USE sims2016Proc
	go

IF exists(SELECT 1 FROM sysobjects WHERE name = 'opCalcPortfolioCheckJrnlP')
	DROP PROC opCalcPortfolioCheckJrnlP
go

CREATE PROC opCalcPortfolioCheckJrnlP
  @i_operatorCode          VARCHAR(255)        ,           --操作员代码
  @i_operatorPassword      VARCHAR(255)        ,           --操作员密码
  @i_operateStationText    VARCHAR(4096)       ,           --留痕信息
  @i_fundAcctCode          VARCHAR(20)         ,           --资金账户
  @i_exchangeCode          VARCHAR(20)         ,           --交易所代码
  @i_secuCode              VARCHAR(20)         ,           --证券代码
  @i_beginDate             VARCHAR(10)  =  ' '             --开始日期  
AS
SET NOCOUNT ON
  CREATE TABLE #tt_portfolioRawJrnlPHist
(
  groupID                          SMALLINT         DEFAULT 0                         NOT NULL, --分组排序ID
  shareRecordDate                  VARCHAR(10)      DEFAULT ' '                           NULL, --登记日期
  serialNO                         NUMERIC(19,0)                                      NOT NULL, -- 自增长
  --createPosiDate                 VARCHAR(10)                                        NOT NULL, -- 建仓日期
  settleDate                       VARCHAR(10)                                        NOT NULL, -- 交收日期
  -----------------------------------------------------------------------------------------------------------
  prodCode                         VARCHAR(30)                                        NOT NULL, -- 产品代码
  prodCellCode                     VARCHAR(30)                                        NOT NULL, -- 产品单元代码
  fundAcctCode                     VARCHAR(30)                                        NOT NULL, -- 资金账户代码
  secuAcctCode                     VARCHAR(30)                                        NOT NULL, -- 证券账户代码
  currencyCode                     VARCHAR(3)       DEFAULT 'CNY'                     NOT NULL, -- 货币代码
  -----------------------------------------------------------------------------------------------------------
  exchangeCode                     VARCHAR(4)                                         NOT NULL, -- 交易所代码
  secuCode                         VARCHAR(40)                                        NOT NULL, -- 证券代码
  originSecuCode                   VARCHAR(40)      DEFAULT ''                            NULL, -- 原始证券代码
  secuTradeTypeCode                VARCHAR(30)                                        NOT NULL, -- 证券交易类型代码
  ------------------------------------------------------------------------------------------------------------
  marketLevelCode                  VARCHAR(1)       DEFAULT '2'                       NOT NULL, -- 市场来源
  transactionNO                    NUMERIC(19,0)    DEFAULT 1                         NOT NULL, -- 交易编号
  investPortfolioCode              VARCHAR(30)                                        NOT NULL, -- 投资组合代码
  buySellFlagCode                  VARCHAR(1)                                         NOT NULL, -- 买卖标志
  bizSubTypeCode                   VARCHAR(2)       DEFAULT ''                            NULL, -- 业务子类
  ------------------------------------------------------------------------------------------------------------
  openCloseFlagCode                VARCHAR(1)                                         NOT NULL, -- 开平仓标志
  longShortFlagCode                VARCHAR(1)                                         NOT NULL, -- 持仓方向标志
  hedgeFlagCode                    VARCHAR(1)                                         NOT NULL, -- 投保标志
  secuBizTypeCode                  VARCHAR(30)                                        NOT NULL, -- 证券业务类别代码
  ------------------------------------------------------------------------------------------------------------
  matchQty                         NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 成交数量
  matchNetPrice                    NUMERIC(10,4)    DEFAULT 0                         NOT NULL, -- 成交价格
--matchNetAmt                      NUMERIC(19,4)    DEFAULT 0                         NOT NULL,                                                          
--matchSettlePrice                 NUMERIC(10,4)    DEFAULT 0                         NOT NULL,
  matchSettleAmt                   NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 成交结算金额
  matchTradeFeeAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 成交交易费用金额
  cashSettleAmt             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 资金发生数
  ------------------------------------------------------------------------------------------------------------
  costChgAmt                       NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 持仓成本金额变动
  occupyCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 持仓占用成本金额变动
  rlzChgProfit                     NUMERIC(19,4)    DEFAULT 0                         NOT NULL -- 持仓实现盈亏变动
)

CREATE TABLE #tt_portfolioCheckJrnlPHist
(
  serialNO                         NUMERIC(19,0)                                      NOT NULL, -- 自增长
  createPosiDate                   VARCHAR(10)                                        NOT NULL, -- 建仓日期
  settleDate                       VARCHAR(10)                                        NOT NULL, -- 交收日期
  -----------------------------------------------------------------------------------------------------------
  prodCode                         VARCHAR(30)                                        NOT NULL, -- 产品代码
  prodCellCode                     VARCHAR(30)                                        NOT NULL, -- 产品单元代码
  fundAcctCode                     VARCHAR(30)                                        NOT NULL, -- 资金账户代码
  secuAcctCode                     VARCHAR(30)                                        NOT NULL, -- 证券账户代码
  currencyCode                     VARCHAR(3)       DEFAULT 'CNY'                     NOT NULL, -- 货币代码
  -----------------------------------------------------------------------------------------------------------
  exchangeCode                     VARCHAR(4)                                         NOT NULL, -- 交易所代码
  secuCode                         VARCHAR(40)                                        NOT NULL, -- 证券代码
  originSecuCode                   VARCHAR(40)      DEFAULT ''                            NULL, -- 原始证券代码
  secuTradeTypeCode                VARCHAR(30)                                        NOT NULL, -- 证券交易类型代码
  ------------------------------------------------------------------------------------------------------------
  marketLevelCode                  VARCHAR(1)       DEFAULT '2'                       NOT NULL, -- 市场来源
  transactionNO                    NUMERIC(19,0)    DEFAULT 1                         NOT NULL, -- 交易编号
  investPortfolioCode              VARCHAR(30)                                        NOT NULL, -- 投资组合代码
  buySellFlagCode                  VARCHAR(1)                                         NOT NULL, -- 买卖标志
  bizSubTypeCode                   VARCHAR(2)       DEFAULT ''                            NULL, -- 业务子类
  ------------------------------------------------------------------------------------------------------------
  openCloseFlagCode                VARCHAR(1)                                         NOT NULL, -- 开平仓标志
  longShortFlagCode                VARCHAR(1)                                         NOT NULL, -- 持仓方向标志
  hedgeFlagCode                    VARCHAR(1)                                         NOT NULL, -- 投保标志
  secuBizTypeCode                  VARCHAR(30)                                        NOT NULL, -- 证券业务类别代码
  ------------------------------------------------------------------------------------------------------------
  matchQty                         NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 成交数量
  matchNetPrice                    NUMERIC(10,4)    DEFAULT 0                         NOT NULL, -- 成交价格
--matchNetAmt                      NUMERIC(19,4)    DEFAULT 0                         NOT NULL,                                                          
--matchSettlePrice                 NUMERIC(10,4)    DEFAULT 0                         NOT NULL,
  matchSettleAmt                   NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 成交结算金额
  matchTradeFeeAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 成交交易费用金额
  cashSettleAmt             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 资金发生数
  ------------------------------------------------------------------------------------------------------------
  costChgAmt                       NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 持仓成本金额变动
  occupyCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 持仓占用成本金额变动
  rlzChgProfit                     NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 持仓实现盈亏变动
  investCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 投资持仓成本金额变动
  investOccupyCostChgAmt           NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 投资持仓占用成本金额变动
  investRlzChgProfit               NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 投资持仓实现盈亏变动
  operateRemarkText                VARCHAR(255)     DEFAULT ' '                       NOT NULL
)

 CREATE TABLE #tt_portfolioCreatePosiDateP
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          --产品单元代码         
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户							
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码							 
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码						
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码							
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志							
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志							
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别							
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,          --交易编号							 
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --投资组合							
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --建仓日期
  repurchaseDate                   VARCHAR(10)                                        NOT NULL,          --购回日期							
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --持仓数量								               
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --成本变动金额
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --最后操作日期
)

CREATE TABLE #tt_portfolioCreatePosiDatePSum
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          --产品单元代码
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,          -- 交易编号
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --投资组合
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --建仓日期
  repurchaseDate                   VARCHAR(10)                                        NOT NULL,          --购回日期
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --持仓数量
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --成本变动金额
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --最后操作日期
)

  --取当前日期
  DECLARE @v_today CHAR(10)
  SELECT @v_today = CONVERT(CHAR(10), GETDATE(), 20)
 --计算成本计算开始日期
 --todo
  DECLARE @v_realBeginDate CHAR(10) = '2000-01-01'
  
  IF @i_beginDate > @v_realBeginDate
    SELECT @v_realBeginDate = @i_beginDate
 
 --判断资金账户是否上下线
 --todo

  --删除产品债券核算流水
  DELETE sims2016TradeHist..portfolioCheckJrnlPHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
               
   --汇总质押式逆回购
   --333 逆回购 335逆回购购回
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

	  --游标变量begin 
  DECLARE
    @v_groupID                          SMALLINT       ,--分组排序ID
    @v_shareRecordDate                  VARCHAR(10)    ,--登记日期
    @v_serialNO                         NUMERIC(19,0)  ,-- 自增长
    --createPosiDate                    VARCHAR(10)    ,-- 建仓日期
    @v_settleDate                       VARCHAR(10)    ,-- 交收日期
    -------------------------------------------------------------
    @v_prodCode                         VARCHAR(30)    ,-- 产品代码
    @v_prodCellCode                     VARCHAR(30)    ,-- 产品单元代码
    @v_fundAcctCode                     VARCHAR(30)    ,-- 资金账户代码
    @v_secuAcctCode                     VARCHAR(30)    ,-- 证券账户代码
    @v_currencyCode                     VARCHAR(3)     ,-- 货币代码
    -------------------------------------------------------------
    @v_exchangeCode                     VARCHAR(4)     ,-- 交易所代码
    @v_secuCode                         VARCHAR(40)    ,-- 证券代码
    @v_originSecuCode                   VARCHAR(40)    ,-- 原始证券代码
    @v_secuTradeTypeCode                VARCHAR(30)    ,-- 证券交易类型代码
    --------------------------------------------------------------
    @v_marketLevelCode                  VARCHAR(1)     ,-- 市场来源
    @v_transactionNO                    NUMERIC(19,0)  ,-- 交易编号
    @v_investPortfolioCode              VARCHAR(30)    ,-- 投资组合代码
    @v_buySellFlagCode                  VARCHAR(1)     ,-- 买卖标志
    @v_bizSubTypeCode                   VARCHAR(2)     ,-- 业务子类
    --------------------------------------------------------------
    @v_openCloseFlagCode                VARCHAR(1)     ,-- 开平仓标志
    @v_longShortFlagCode                VARCHAR(1)     ,-- 持仓方向标志
    @v_hedgeFlagCode                    VARCHAR(1)     ,-- 投保标志
    @v_secuBizTypeCode                  VARCHAR(30)    ,-- 证券业务类别代码
    --------------------------------------------------------------
    @v_matchQty                         NUMERIC(19,4)  ,-- 成交数量
    @v_matchNetPrice                    NUMERIC(10,4)  ,-- 成交价格
    @v_matchSettleAmt                   NUMERIC(19,4)  ,-- 成交结算金额
    @v_matchTradeFeeAmt                 NUMERIC(19,4)  ,-- 成交交易费用金额
    @v_cashCurrentSettleAmt             NUMERIC(19,4)  ,-- 资金发生数
    --------------------------------------------------------------
    @v_costChgAmt                       NUMERIC(19,4)  ,-- 持仓成本金额变动
    @v_occupyCostChgAmt                 NUMERIC(19,4)  ,-- 持仓占用成本金额变动
    @v_rlzChgProfit                     NUMERIC(19,4)  ,-- 持仓实现盈亏变动  
  --游标变量end
  --计算变量begin
    @v_createPosiDate                   VARCHAR(10)    ,--建仓日期
    @v_posiQty                          NUMERIC(19,4)  ,--持仓数量
    @v_lastOperateDate                  VARCHAR(10)    ,--最后建仓日期
    @v_unitCost                         NUMERIC(19,4)   --单位成本
            
  --计算变量end    
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
                       
   --逐条处理
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
																						WHERE settleDate < @v_realBeginDate -- AND settleDate > 快照日期 (待后续快照表设计好后加上此条件)
																							AND fundAcctCode = @v_fundAcctCode
																							AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
																							AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
																							AND secuBizTypeCode = '333'    --逆回购
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
      
      ---------------------------------------逆回购-------------------------------------------------------  
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
      ------------------------------------------------逆回购购回-------------------------------------------------
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
	
	SELECT 0,'执行成功!'
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