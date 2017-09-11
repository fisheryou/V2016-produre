USE sims2016Proc
  go
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'opCalcPordCheckJrnlDB')
  DROP PROC opCalcPordCheckJrnlDB
go

CREATE PROC opCalcPordCheckJrnlDB
  @i_operatorCode          VARCHAR(255)        ,           --操作员代码
  @i_operatorPassword      VARCHAR(255)        ,           --操作员密码
  @i_operateStationText    VARCHAR(4096)       ,           --留痕信息
  @i_prodCode              VARCHAR(4096)       ,           --产品代码
  @i_fundAcctCode          VARCHAR(20)         ,           --资金账户
  @i_exchangeCode          VARCHAR(20)         ,           --交易所代码
  @i_secuCode              VARCHAR(20)         ,           --证券代码
  @i_beginDate             VARCHAR(10)  =  ' '             --开始日期  
AS
/***************************************************************************
-- Author : yugy
-- Version : 1.0
--    V1.0 ： 支持现券买卖
-- Date : 2017-04-26
-- Description : 
-- Function List : opCalcPordCheckJrnlDB
-- History : 

****************************************************************************/
SET NOCOUNT ON
CREATE TABLE #tt_prodRawJrnlDBHist
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
  matchNetAmt                      NUMERIC(19,4)    DEFAULT 0                         NOT NULL,                                                          
  matchSettlePrice                 NUMERIC(10,4)    DEFAULT 0                         NOT NULL,
  matchSettleAmt                   NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 成交结算金额
  matchTradeFeeAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 成交交易费用金额
  cashSettleAmt             NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 资金发生数
  ------------------------------------------------------------------------------------------------------------
  costChgAmt                       NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 持仓成本金额变动
  occupyCostChgAmt                 NUMERIC(19,4)    DEFAULT 0                         NOT NULL, -- 持仓占用成本金额变动
  rlzChgProfit                     NUMERIC(19,4)    DEFAULT 0                         NOT NULL -- 持仓实现盈亏变动
)

CREATE TABLE #tt_prodCheckJrnlDBHist
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
  matchNetAmt                      NUMERIC(19,4)    DEFAULT 0                         NOT NULL,                                                          
  matchSettlePrice                 NUMERIC(10,4)    DEFAULT 0                         NOT NULL,
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

CREATE TABLE #tt_prodCreatePosiDateDB
(
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --建仓日期
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --持仓数量
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --成本变动金额
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --最后操作日期
)

CREATE TABLE #tt_prodCreatePosiDateDBSum
(
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --建仓日期
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
 
 --判断资金账户是否上下线
 --todo

  --删除产品债券核算流水
  DELETE sims2016TradeHist..prodCheckJrnlDBHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_prodCode = '' OR CHARINDEX(prodCode, @i_prodCode) > 0)               
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
                            
  --汇总现券交易成交
  --301债现券买入
  --302债现券卖出
  INSERT INTO #tt_prodRawJrnlDBHist(groupID, shareRecordDate, serialNO, settleDate,
                                    prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                    exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                    marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                    openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                    matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                    costChgAmt, occupyCostChgAmt, rlzChgProfit)
                             -- 产品核算 单元代码置空,组合代码置空,投资编号置成1      
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
                                    SUM(-cashSettleAmt) AS costChgAmt , SUM(-cashSettleAmt) AS occupyCostChgAmt , 0 AS rlzChgProfit     
                               FROM sims2016TradeHist..prodRawJrnlDBHist a        
                           WHERE settleDate >= @v_realBeginDate
                                     AND settleDate >= @i_beginDate
                                     AND settleDate <= @v_today
                                     AND secuBizTypeCode NOT IN ('311', '312')   
                                     AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                     AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                     AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(originSecuCode, @i_secuCode) > 0)
                           GROUP BY settleDate, prodCode, fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, secuBizTypeCode, openCloseFlagCode
                           ORDER BY fundAcctCode, settleDate, prodCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, secuBizTypeCode, openCloseFlagCode                            
  
  
    --付息兑付流水处理  
       INSERT INTO #tt_prodRawJrnlDBHist(groupID, shareRecordDate, serialNO, settleDate,
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
                                    FROM sims2016TradeHist..prodRawJrnlDBHist a        
                                   WHERE settleDate >= @v_realBeginDate
                                         AND settleDate >= @i_beginDate
                                         AND settleDate <= @v_today
                                         AND secuBizTypeCode IN ('311', '312')  
                                         AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                         AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                         AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(originSecuCode, @i_secuCode) > 0) 
                                ORDER BY fundAcctCode, settleDate, prodCode
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
    @v_matchNetAmt                      NUMERIC(19,4)  , 
    @v_matchSettlePrice                 NUMERIC(10,4)  ,
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
  DEClARE db_mccjb CURSOR FOR SELECT groupID, shareRecordDate, serialNO, settleDate, 
                                     prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                     exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                     marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                     openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                     matchQty, matchNetPrice,matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt,
                                     costChgAmt, occupyCostChgAmt, rlzChgProfit 
                                FROM #tt_prodRawJrnlDBHist  
                               ORDER BY fundAcctCode, prodCode, secuAcctCode, currencyCode, 
                                     exchangeCode, secuCode, longShortFlagCode, hedgeFlagCode,
                                     marketLevelCode, secuBizTypeCode, settleDate, groupID, openCloseFlagCode DESC                                                                                       
                             
  OPEN db_mccjb  
  FETCH db_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
                      @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                      @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                      @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                      @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                      @v_matchQty,@v_matchNetPrice, @v_matchNetAmt, @v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                      @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit 
                       
   --逐条处理
  DECLARE @loop_fundAcctCode VARCHAR(20)
  SELECT @loop_fundAcctCode = NULL                         
                       
  WHILE 1 = 1
    BEGIN
      IF @loop_fundAcctCode IS NOT NULL AND (@loop_fundAcctCode != @v_fundAcctCode OR @@FETCH_STATUS != 0)
        BEGIN
          INSERT sims2016TradeHist..prodCheckJrnlDBHist(createPosiDate, settleDate, 
                                                        prodCode, fundAcctCode, currencyCode, 
                                                        exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                        marketLevelCode, buySellFlagCode, bizSubTypeCode, 
                                                        openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                        matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                        costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                        investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, 
                                                        operatorCode, operateDatetime, operateRemarkText)
                                                 SELECT createPosiDate, settleDate, 
                                                        prodCode, fundAcctCode, currencyCode, 
                                                        exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                        marketLevelCode, buySellFlagCode, bizSubTypeCode, 
                                                        openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                        matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                        costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                        investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, 
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
          
          --INSERT INTO #tt_prodCreatePosiDateDB(secuAcctCode, currencyCode, exchangeCode, secuCode, 
            --                                   longShortFlagCode, hedgeFlagCode, marketLevelCode, 
            --                                   createPosiDate, posiQty, costChgAmt, lastOperateDate)
      --                                  SELECT secuAcctCode, currencyCode, exchangeCode, secuCode, 
            --                                   longShortFlagCode, hedgeFlagCode, marketLevelCode, 
      --                                          MAX(createPosiDate), SUM(matchQty), SUM(costChgAmt), MAX(settleDate)
      --                                     FROM sims2016TradeHist..prodCheckJrnlDBHist
      --                                    WHERE settleDate < @v_realBeginDate -- AND settleDate > 快照日期 (待后续快照表设计好后加上此条件)
      --                                      AND fundAcctCode = @v_fundAcctCode
      --                                      AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
      --                                      AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
      --                                    GROUP BY secuAcctCode, currencyCode, exchangeCode, secuCode, 
            --                                    longShortFlagCode, hedgeFlagCode, marketLevelCode
      --                                    HAVING SUM(matchQty) > 0
    
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
      
      
      -----------------------------债券付息------------------------------  
      IF @v_secuBizTypeCode = '311' or (@v_secuBizTypeCode = '312' and @v_matchQty = 0)
        BEGIN       
          UPDATE #tt_prodCreatePosiDateDBSum SET posiQty = a.posiQty + @v_matchQty,
                            costChgAmt = a.costChgAmt + @v_costChgAmt,
                            createPosiDate = CASE WHEN a.posiQty <= 0 THEN @v_settleDate ELSE a.createPosiDate END
                      FROM #tt_prodCreatePosiDateDBSum a
                      WHERE exchangeCode = @v_exchangeCode
                            AND secuCode = @v_secuCode
                            --AND prodCellCode = @v_prodCellCode
                            --AND a.investPortfolioCode = b.investPortfolioCode
                            --AND a.transactionNO = b.transactionNO                 
                            AND secuAcctCode = @v_secuAcctCode
                            AND currencyCode = @v_currencyCode
                            AND exchangeCode = @v_exchangeCode
                            AND hedgeFlagCode = @v_hedgeFlagCode
                            AND marketLevelCode = @v_marketLevelCode            
          
          INSERT INTO #tt_prodCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
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
     ------------------------------债券兑付------------------------------   
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
                                             matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
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
      ---------------------------------------现券买入处理-------------------------------------------------------  
     ELSE IF @v_secuBizTypeCode = '301'
        BEGIN
          SELECT @v_createPosiDate  = NULL
          SELECT @v_posiQty         = NULL
          SELECT @v_lastOperateDate = NULL
          
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
                                                      createPosiDate, posiQty, costChgAmt, lastOperateDate)
                                               VALUES(@v_secuAcctCode, @v_currencyCode, @v_exchangeCode, @v_secuCode, 
                                                      @v_longShortFlagCode, @v_hedgeFlagCode, @v_marketLevelCode, 
                                                      @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate)
              SELECT @v_createPosiDate = @v_settleDate                                           
            END
          ELSE IF @v_posiQty <= 0 AND @v_lastOperateDate != @v_settleDate
            BEGIN
              UPDATE #tt_prodCreatePosiDateDBSum SET createPosiDate = @v_settleDate, posiQty = @v_matchQty, costChgAmt = @v_costChgAmt, lastOperateDate = @v_settleDate
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
      ------------------------------------------------现券卖出处理-------------------------------------------------
      ELSE IF @v_secuBizTypeCode = '302' 
        BEGIN         
          SELECT @v_unitCost = costChgAmt/posiQty, @v_posiQty = posiQty
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
              PRINT '卖出现券数量不足'
              RETURN
            END
            
          SElECT @v_costChgAmt = -ABS(@v_unitCost*@v_matchQty)
          SELECT @v_rlzChgProfit = ABS(@v_cashCurrentSettleAmt)-ABS(@v_unitCost*@v_matchQty)    
            
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
                                              matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                              costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                              investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                      values (@v_serialNO, @v_createPosiDate, @v_settleDate,
                                              @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                              @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                              @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                              @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                              @v_matchQty,@v_matchNetPrice,@v_matchNetAmt, @v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                                              @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit,
                                              @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit)                              
        END
                
      FETCH db_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
                          @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                          @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                          @v_marketLevelCode,@v_transactionNO,@v_investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                          @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                          @v_matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt,
                          @v_costChgAmt,@v_occupyCostChgAmt,@v_rlzChgProfit        
    END                    
                       
  CLOSE db_mccjb  
  DEALLOCATE db_mccjb                                                                                             
  RETURN 0
go

--exec opCalcPordCheckJrnlDB '9999', '', '', '','', '', '', ''


--TRUNCATE TABLE sims2016TradeHist..prodCheckJrnlDBHist

----SUM(cashSettleAmt)
--select SUM(cashSettleAmt) from sims2016TradeHist..prodCheckJrnlDBHist  where secuCode = '110030'
--select SUM(rlzChgProfit) from sims2016TradeHist..prodCheckJrnlDBHist  where secuCode = '110030' 
--select * from sims2016TradeHist..prodCheckJrnlDBHist  where  prodCode = '1000' order by settleDate 
--select * from sims2016TradeToday..prodCellPosiDB

----select secuAcctCode from sims2016TradeHist..prodCheckJrnlDBHist
----select secuAcctCode from sims2016TradeHist..prodCellCheckJrnlDBHist
----select secuAcctCode from sims2016TradeHist..portfolioCheckJrnlDBHist

----select secuAcctCode from sims2016TradeHist..prodCheckJrnlFHist
--select * from sims2016TradeHist..prodRawJrnlDBHist
--select * from sims2016TradeHist..prodCellRawJrnlDBHist

--select * from sims2016TradeHist..prodCellRawJrnlDBHist
