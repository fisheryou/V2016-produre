USE sims2016Proc
  go
  
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'opCalcPortfolioCheckJrnlDB')
  DROP PROC opCalcPortfolioCheckJrnlDB
go

CREATE PROC opCalcPortfolioCheckJrnlDB
  @i_operatorCode          VARCHAR(255)        ,           --操作员代码
  @i_operatorPassword      VARCHAR(255)        ,           --操作员密码
  @i_operateStationText    VARCHAR(4096)       ,           --留痕信息
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
-- Function List : opCalcPortfolioCheckJrnlDB
-- History : 

--Other business(未处理)
-- 新债发行
-- 回购交易
    a)质押式回购
    b)买断式回购
-- 债券远期
-- 债券兑付
-- 债券借贷

--ps:
--DVP(Delivery Versus Payment)——券款对付。
--STP(Straight Through Processing)—— 外汇交易商通过直通式处理系统。

--问题：
--1.债券资金证券流水中没有登记日期
--2.单元资金证券流水总表没有投资编号和投资组合字段
****************************************************************************/
SET NOCOUNT ON
CREATE TABLE #tt_portfolioRawJrnlDBHist
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

CREATE TABLE #tt_portfolioCheckJrnlDBHist
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

CREATE TABLE #tt_portfolioCreatePosiDateDB
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- 产品单元代码         
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户             
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码              
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码            
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码             
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志             
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志             
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别             
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- 交易编号              
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --投资组合             
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --建仓日期             
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --持仓数量                              
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --成本变动金额
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --最后操作日期
)

CREATE TABLE #tt_portfolioCreatePosiDateDBSum
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- 产品单元代码
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- 交易编号
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --投资组合
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --建仓日期
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --持仓数量
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --成本变动金额
  lastOperateDate                  VARCHAR(10)                                        NOT NULL           --最后操作日期
)

CREATE TABLE #tt_portfolioDBDetail
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- 产品单元代码
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- 交易编号
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --投资组合
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --建仓日期
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --持仓数量
  matchQty                         NUMERIC(19,4)                                      NOT NULL,          --持仓数量
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --成本变动金额
  rlzChgProfit                     NUMERIC(19,4)     DEFAULT 0                        NOT NULL,          --实现盈亏变动金额
)

CREATE TABLE #tt_portfolioDBSum
(
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- 产品单元代码
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- 交易编号
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --投资组合
  createPosiDate                   VARCHAR(10)                                        NOT NULL,          --建仓日期
  posiQty                          NUMERIC(19,4)                                      NOT NULL,          --持仓数量
  matchQty                         NUMERIC(19,4)                                      NOT NULL,          --持仓数量
  costChgAmt                       NUMERIC(19,4)                                      NOT NULL,          --成本变动金额
  rlzChgProfit                     NUMERIC(19,4)     DEFAULT 0                        NOT NULL,          --实现盈亏变动金额
)

CREATE TABLE #tt_portfolioDBCheckJrnl_old
(
  settleDate                       VARCHAR(10)                                        NOT NULL,          -- 交收日期
  prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- 产品单元代码
  secuAcctCode                     VARCHAR(30)                                        NOT NULL,          --证券账户
  currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码
  exchangeCode                     VARCHAR(4)                                         NOT NULL,          --交易所代码 
  secuCode                         VARCHAR(30)                                        NOT NULL,          --证券代码 
  longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志 
  hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志
  marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别
  transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- 交易编号
  investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --投资组合
  posiQty                          NUMERIC(19,4)                                      NOT NULL           -- 持仓数量
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
  DELETE sims2016TradeHist..portfolioCheckJrnlDBHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
                           
  DELETE sims2016TradeHist..prodCellRawJrnlDBHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
               AND secuBizTypeCode IN('311', '312')
               
  DELETE sims2016TradeHist..prodCellRawJrnlHist
       WHERE settleDate >= @v_realBeginDate
             AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
             AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
             AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
             AND secuBizTypeCode IN('311', '312')             
                            
  --汇总现券交易成交
  --301债现券买入  
  --302债现券卖出
  INSERT INTO #tt_portfolioRawJrnlDBHist(groupID, shareRecordDate, serialNO, settleDate,
                                         prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                         exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                         marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                         openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                         matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                         costChgAmt, occupyCostChgAmt, rlzChgProfit)  
                                  SELECT 0 AS groupID, ' ' AS shareRecordDate, MAX(serialNO), settleDate,
                                         prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,   
                                         exchangeCode, secuCode, MAX(originSecuCode), MAX(secuTradeTypeCode),
                                         marketLevelCode, transactionNO , investPortfolioCode, MAX(buySellFlagCode), MAX(bizSubTypeCode),
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
                                GROUP BY settleDate, prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, investPortfolioCode, transactionNO, secuBizTypeCode, openCloseFlagCode
                                ORDER BY fundAcctCode, settleDate, prodCode, prodCellCode, investPortfolioCode, secuAcctCode, currencyCode, exchangeCode, secuCode, hedgeFlagCode, marketLevelCode, transactionNO, secuBizTypeCode, openCloseFlagCode  
                                                                
       --付息兑付流水处理  
       INSERT INTO #tt_portfolioRawJrnlDBHist(groupID, shareRecordDate, serialNO, settleDate,
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
                                               AND secuBizTypeCode  IN ('311', '312')  
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
  DEClARE dbzh_mccjb CURSOR FOR SELECT groupID, shareRecordDate, serialNO, settleDate, 
                                       prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                       exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                       marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                       openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode,
                                       matchQty, matchNetPrice,matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt,
                                       costChgAmt, occupyCostChgAmt, rlzChgProfit 
                                  FROM #tt_portfolioRawJrnlDBHist  
                                 ORDER BY fundAcctCode, settleDate, prodCode, secuAcctCode, currencyCode, 
                                       exchangeCode, secuCode, longShortFlagCode, hedgeFlagCode,
                                       marketLevelCode, secuBizTypeCode,  groupID, openCloseFlagCode DESC                                                                                       
                             
  OPEN dbzh_mccjb  
  FETCH dbzh_mccjb INTO @v_groupID,@v_shareRecordDate,@v_serialNO,@v_settleDate,
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
          INSERT sims2016TradeHist..portfolioCheckJrnlDBHist(createPosiDate, settleDate, 
                                                            prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                            exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                            marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                            openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                            matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                            costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                            investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit, 
                                                            operatorCode, operateDatetime, operateRemarkText)
                                                     SELECT createPosiDate, settleDate, 
                                                            prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                            exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                            marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                            openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                            matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                            costChgAmt, occupyCostChgAmt, rlzChgProfit, 
                                                            investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit,  
                                                            @i_operatorCode, GETDATE(), operateRemarkText FROM #tt_portfolioCheckJrnlDBHist                                                                                                              
                                                                                                    
         INSERT INTO sims2016TradeHist..prodCellRawJrnlHist(originSerialNO, settleDate, secuBizTypeCode, buySellFlagCode, 
                                                            bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, coveredFlagCode, originSecuBizTypeCode, 
                                                            brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, prodCode, prodCellCode, 
                                                            fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, 
                                                            secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty, 
                                                            posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode, 
                                                            operatorCode, operateDatetime, operateRemarkText)  
                                                     SELECT 0 AS originSerialNO, settleDate, secuBizTypeCode, buySellFlagCode, 
                                                            bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, ' ' AS coveredFlagCode, ' ' AS originSecuBizTypeCode, 
                                                            ' ' AS brokerSecuBizTypeCode, ' ' AS brokerSecuBizTypeName, ' ' AS brokerJrnlSerialID, prodCode, prodCellCode, 
                                                            fundAcctCode, currencyCode, cashSettleAmt, 0 AS cashBalanceAmt, exchangeCode, 
                                                            secuAcctCode, secuCode, originSecuCode, ' ' AS secuName, secuTradeTypeCode, matchQty, 
                                                             0 AS posiBalanceQty, matchNetPrice, ' ' AS dataSourceFlagCode, marketLevelCode, 
                                                            ' ' AS operatorCode, ' ' AS operateDatetime, operateRemarkText FROM #tt_portfolioCheckJrnlDBHist 
                                                      WHERE secuBizTypeCode IN('311', '312')   
                                                                                                                                                                                                                                    
          INSERT INTO sims2016TradeHist..prodCellRawJrnlDBHist(serialNO,settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,
                                                                openCloseFlagCode,hedgeFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,
                                                                brokerSecuBizTypeName,brokerJrnlSerialID,
                                                                prodCode,prodCellCode,fundAcctCode,currencyCode,
                                                                cashSettleAmt,cashBalanceAmt,
                                                                exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,
                                                                matchQty,posiBalanceQty,matchNetPrice,matchNetAmt,
                                                                matchSettlePrice,matchSettleAmt,matchTradeFeeAmt,
                                                                matchDate,matchTime,matchID,
                                                                repoSettleDate,repoSettleAmt,brokerOrderID,brokerOriginOrderID,
                                                                brokerErrorMsg,dataSourceFlagCode,
                                                                transactionNO,investPortfolioCode,assetLiabilityTypeCode,
                                                                investInstrucNO,traderInstrucNO,orderNO,marketLevelCode,
                                                                orderNetAmt,orderNetPrice,orderQty,orderSettleAmt,
                                                                orderSettlePrice,orderTradeFeeAmt,directorCode,traderCode,operatorCode,
                                                                operateDatetime,operateRemarkText) 
                                                        SELECT  b.serialNO,a.settleDate,a.secuBizTypeCode,a.buySellFlagCode,a.bizSubTypeCode,
                                                                a.openCloseFlagCode,a.hedgeFlagCode,' ' AS originSecuBizTypeCode,' ' AS brokerSecuBizTypeCode,
                                                                ' ' AS brokerSecuBizTypeName,' ' AS brokerJrnlSerialID,
                                                                a.prodCode,a.prodCellCode,a.fundAcctCode,a.currencyCode,
                                                                a.cashSettleAmt,0 AS cashBalanceAmt,
                                                                a.exchangeCode,a.secuAcctCode,a.secuCode,a.originSecuCode,' ' AS secuName,a.secuTradeTypeCode,
                                                                a.matchQty,0 AS posiBalanceQty,a.matchNetPrice,matchNetAmt,
                                                                matchSettlePrice,matchSettleAmt,matchTradeFeeAmt,
                                                                ' ' AS matchDate,' ' AS matchTime,' ' AS matchID,
                                                                ' ' AS repoSettleDate,0 AS repoSettleAmt,' ' AS brokerOrderID,' ' AS brokerOriginOrderID,
                                                                ' ' AS brokerErrorMsg,' ' AS dataSourceFlagCode,
                                                                transactionNO,investPortfolioCode,' ' AS assetLiabilityTypeCode,
                                                                0 AS investInstrucNO,0 AS traderInstrucNO,0 AS orderNO,a.marketLevelCode,
                                                                0 AS orderNetAmt,0 AS orderNetPrice,0 AS orderQty,0 AS orderSettleAmt,
                                                                0 AS orderSettlePrice,0 AS orderTradeFeeAmt,' ' AS directorCode,' ' AS traderCode,' ' AS operatorCode,
                                                                ' ' AS operateDatetime,a.operateRemarkText 
                                                           FROM #tt_portfolioCheckJrnlDBHist a INNER JOIN sims2016TradeHist..prodCellRawJrnlHist b 
                                                             ON b.secuCode = @v_secuCode          
                                                             AND a.prodCellCode = b.prodCellCode
                                                             AND a.settleDate = b.settleDate
                                                             --AND a.investPortfolioCode = b.investPortfolioCode
                                                             --AND a.transactionNO = b.transactionNO                 
                                                             AND a.secuAcctCode = b.secuAcctCode
                                                             AND a.currencyCode = b.currencyCode
                                                             AND a.exchangeCode = b.exchangeCode
                                                             AND a.hedgeFlagCode = b.hedgeFlagCode
                                                             AND a.marketLevelCode = b.marketLevelCode
                                                             AND a.secuBizTypeCode = b.secuBizTypeCode   
                                                           WHERE a.secuBizTypeCode IN('311', '312')
                                                                          
          TRUNCATE TABLE #tt_portfolioCheckJrnlDBHist         
        END 
        
      IF @@FETCH_STATUS != 0
        break
      
      IF @loop_fundAcctCode IS NULL OR (@v_fundAcctCode != @loop_fundAcctCode)
        BEGIN
          SELECT @loop_fundAcctCode = @v_fundAcctCode
          TRUNCATE TABLE #tt_portfolioCreatePosiDateDBSum
          TRUNCATE TABLE #tt_portfolioCreatePosiDateDB
          
          INSERT INTO #tt_portfolioCreatePosiDateDB(prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                     longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,  
                                                     createPosiDate, posiQty, costChgAmt, lastOperateDate)
                                              SELECT prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                     longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,  
                                                     MAX(createPosiDate), SUM(matchQty), SUM(costChgAmt), MAX(settleDate)
                                               FROM sims2016TradeHist..portfolioCheckJrnlDBHist
                                              WHERE settleDate < @v_realBeginDate -- AND settleDate > 快照日期 (待后续快照表设计好后加上此条件)
                                                AND fundAcctCode = @v_fundAcctCode
                                                AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                                AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
                                              GROUP BY prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                    longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode
                                              HAVING SUM(matchQty) > 0
    
        INSERT INTO #tt_portfolioCreatePosiDateDBSum(prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                     longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode, 
                                                     createPosiDate, posiQty, costChgAmt, lastOperateDate)
                                              SELECT prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                     longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode,  
                                                     MAX(createPosiDate), SUM(posiQty), SUM(costChgAmt), MAX(lastOperateDate)
                                                FROM #tt_portfolioCreatePosiDateDB
                                               GROUP BY prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                     longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode
                                             HAVING SUM(posiQty) > 0
                  
        END
        
      ---------------------------------------债券付息----------------------------------------------------------
      IF @v_secuBizTypeCode = '311' or (@v_secuBizTypeCode = '312' and @v_matchQty = 0)
        BEGIN
          IF @i_operatorPassword = '0'
            SELECT @v_rlzChgProfit = -@v_costChgAmt, @v_costChgAmt = 0
          ELSE
            SELECT @v_rlzChgProfit = 0

          TRUNCATE TABLE #tt_portfolioDBDetail
          TRUNCATE TABLE #tt_portfolioDBSum     
                          
          INSERT INTO #tt_portfolioDBDetail(prodCellCode,secuAcctCode,currencyCode,
                                            exchangeCode,secuCode,longShortFlagCode,
                                            hedgeFlagCode,marketLevelCode,transactionNO,
                                            investPortfolioCode,createPosiDate,posiQty,
                                            matchQty,costChgAmt,rlzChgProfit) 
                                     SELECT prodCellCode,secuAcctCode,currencyCode,
                                            exchangeCode,secuCode,longShortFlagCode,
                                            hedgeFlagCode,marketLevelCode,transactionNO,
                                            investPortfolioCode,@v_settleDate,SUM(posiQty),
                                            0,0,0
                                        FROM #tt_portfolioDBCheckJrnl_old
                                       WHERE settleDate <= @v_shareRecordDate
                                         AND exchangeCode = @v_exchangeCode
                                         AND secuCode = @v_secuCode   
                                      GROUP BY prodCellCode,secuAcctCode,currencyCode,exchangeCode,secuCode,longShortFlagCode,
                                            hedgeFlagCode,marketLevelCode,transactionNO,investPortfolioCode                                 
                                    HAVING SUM(posiQty) > 0                                                             
                                    
            INSERT INTO #tt_portfolioDBDetail(prodCellCode,secuAcctCode,currencyCode,
                                              exchangeCode,secuCode,longShortFlagCode,
                                              hedgeFlagCode,marketLevelCode,transactionNO,
                                              investPortfolioCode,createPosiDate,posiQty,
                                              matchQty,costChgAmt,rlzChgProfit) 
                                       SELECT prodCellCode,secuAcctCode,currencyCode,
                                              exchangeCode,secuCode,longShortFlagCode,
                                              hedgeFlagCode,marketLevelCode,transactionNO,
                                              investPortfolioCode,@v_settleDate,SUM(matchQty),
                                              0,0,0
                                          FROM #tt_portfolioCheckJrnlDBHist
                                         WHERE settleDate <= @v_shareRecordDate
                                           AND exchangeCode = @v_exchangeCode
                                           AND secuCode = @v_secuCode
                                        GROUP BY prodCellCode,secuAcctCode,currencyCode,exchangeCode,secuCode,longShortFlagCode,
                                              hedgeFlagCode,marketLevelCode,transactionNO,investPortfolioCode                                 
                                      HAVING SUM(matchQty) > 0                                                            
                                      
          INSERT INTO #tt_portfolioDBSum(prodCellCode,secuAcctCode,currencyCode,
                                          exchangeCode,secuCode,longShortFlagCode,
                                          hedgeFlagCode,marketLevelCode,transactionNO,
                                          investPortfolioCode,createPosiDate,posiQty,
                                          matchQty,costChgAmt,rlzChgProfit) 
                                   SELECT prodCellCode,secuAcctCode,currencyCode,
                                          exchangeCode,secuCode,longShortFlagCode,
                                          hedgeFlagCode,marketLevelCode,transactionNO,
                                          investPortfolioCode,@v_settleDate,SUM(posiQty),
                                          0,0,0
                                     FROM #tt_portfolioDBDetail
                                 GROUP BY prodCellCode,secuAcctCode,currencyCode,exchangeCode,secuCode,longShortFlagCode,
                                          hedgeFlagCode,marketLevelCode,transactionNO,investPortfolioCode
                                          
          SELECT @v_posiQty = SUM(posiQty) FROM #tt_portfolioDBDetail
                    
          UPDATE #tt_portfolioDBSum SET matchQty = floor(round((posiQty * @v_matchQty / convert(money, @v_posiQty)), 4)),
                                      costChgAmt = round(round((posiQty * @v_costChgAmt / convert(money, @v_posiQty)), 4), 2, 1),
                                      rlzChgProfit = round(round((posiQty * @v_rlzChgProfit / convert(money, @v_posiQty)), 4), 2, 1)
                                                                   
          SELECT @v_matchQty = @v_matchQty - sum(matchQty), @v_costChgAmt = @v_costChgAmt - sum(costChgAmt), @v_rlzChgProfit = @v_rlzChgProfit - sum(rlzChgProfit) FROM #tt_portfolioDBSum                              
                                          
          IF @v_matchQty != 0 or @v_costChgAmt != 0 or @v_rlzChgProfit != 0 -- 尾数
            BEGIN
              DECLARE @t_investPortfolioCode VARCHAR(20)
              SELECT TOP 1 @t_investPortfolioCode = investPortfolioCode FROM #tt_portfolioDBSum ORDER BY posiQty DESC
              SET ROWCOUNT 1
              UPDATE #tt_portfolioDBSum SET matchQty = matchQty + @v_matchQty, costChgAmt = costChgAmt + @v_costChgAmt, rlzChgProfit = rlzChgProfit + @v_rlzChgProfit WHERE investPortfolioCode = @t_investPortfolioCode
              SET ROWCOUNT 0
            END   
            
          UPDATE #tt_portfolioDBSum SET createPosiDate = b.createPosiDate
                FROM #tt_portfolioDBSum a, #tt_portfolioCreatePosiDateDBSum b
                WHERE b.exchangeCode = @v_exchangeCode
                 AND  b.secuCode = @v_secuCode          
                 AND a.prodCellCode = b.prodCellCode
                 AND a.investPortfolioCode = b.investPortfolioCode
                 AND a.transactionNO = b.transactionNO                 
                 AND a.secuAcctCode = b.secuAcctCode
                 AND a.currencyCode = b.currencyCode
                 AND a.exchangeCode = b.exchangeCode
                 AND a.hedgeFlagCode = b.hedgeFlagCode
                 AND a.marketLevelCode = b.marketLevelCode                              
                 AND  b.posiQty > 0 
                 
        UPDATE #tt_portfolioCreatePosiDateDBSum SET posiQty = a.posiQty + b.matchQty,
                              costChgAmt = a.costChgAmt + b.costChgAmt,
                              createPosiDate = CASE WHEN a.posiQty <= 0 THEN b.createPosiDate ELSE a.createPosiDate END
                        FROM #tt_portfolioCreatePosiDateDBSum a, #tt_portfolioDBSum b
                        WHERE a.exchangeCode = @v_exchangeCode
                              AND a.secuCode = @v_secuCode
                              AND a.prodCellCode = b.prodCellCode
                              AND a.investPortfolioCode = b.investPortfolioCode
                              AND a.transactionNO = b.transactionNO                 
                              AND a.secuAcctCode = b.secuAcctCode
                              AND a.currencyCode = b.currencyCode
                              AND a.exchangeCode = b.exchangeCode
                              AND a.hedgeFlagCode = b.hedgeFlagCode
                              AND a.marketLevelCode = b.marketLevelCode  
                                                            
        INSERT INTO #tt_portfolioCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                                 prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                 exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                 marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                 openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                 matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                 costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                                 investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                          SELECT @v_serialNO, @v_createPosiDate, @v_settleDate,
                                                 @v_prodCode, prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                                 @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                                 @v_marketLevelCode,@v_transactionNO,investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                                 @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                                 matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,-(costChgAmt-rlzChgProfit),
                                                 costChgAmt,@v_occupyCostChgAmt,rlzChgProfit,
                                                 costChgAmt,@v_occupyCostChgAmt,rlzChgProfit
                                            FROM #tt_portfolioDBSum                           
                                                                                        
        END  
      ---------------------------------------债券兑付-----------------------------------------------------------
      ELSE IF @v_secuBizTypeCode = '312' AND @v_matchQty <> 0
        BEGIN
          TRUNCATE TABLE #tt_portfolioDBDetail
          TRUNCATE TABLE #tt_portfolioDBSum
                                    
          INSERT INTO #tt_portfolioDBDetail(prodCellCode,secuAcctCode,currencyCode,
                                            exchangeCode,secuCode,longShortFlagCode,
                                            hedgeFlagCode,marketLevelCode,transactionNO,
                                            investPortfolioCode,createPosiDate,posiQty,
                                            matchQty,costChgAmt,rlzChgProfit) 
                                     SELECT prodCellCode,secuAcctCode,currencyCode,
                                            exchangeCode,secuCode,longShortFlagCode,
                                            hedgeFlagCode,marketLevelCode,transactionNO,
                                            investPortfolioCode,@v_settleDate,SUM(posiQty),
                                            0,0,0
                                        FROM #tt_portfolioDBCheckJrnl_old
                                       WHERE settleDate <= @v_shareRecordDate
                                         AND exchangeCode = @v_exchangeCode
                                         AND secuCode = @v_secuCode   
                                      GROUP BY prodCellCode,secuAcctCode,currencyCode,exchangeCode,secuCode,longShortFlagCode,
                                            hedgeFlagCode,marketLevelCode,transactionNO,investPortfolioCode                                 
                                    HAVING SUM(posiQty) > 0
                                    
            INSERT INTO #tt_portfolioDBDetail(prodCellCode,secuAcctCode,currencyCode,
                                              exchangeCode,secuCode,longShortFlagCode,
                                              hedgeFlagCode,marketLevelCode,transactionNO,
                                              investPortfolioCode,createPosiDate,posiQty,
                                              matchQty,costChgAmt,rlzChgProfit) 
                                      SELECT prodCellCode,secuAcctCode,currencyCode,
                                              exchangeCode,secuCode,longShortFlagCode,
                                              hedgeFlagCode,marketLevelCode,transactionNO,
                                              investPortfolioCode,@v_settleDate,SUM(matchQty),
                                              0,0,0
                                          FROM #tt_portfolioCheckJrnlDBHist
                                         WHERE settleDate <= @v_shareRecordDate
                                           AND exchangeCode = @v_exchangeCode
                                           AND secuCode = @v_secuCode
                                        GROUP BY prodCellCode,secuAcctCode,currencyCode,exchangeCode,secuCode,longShortFlagCode,
                                              hedgeFlagCode,marketLevelCode,transactionNO,investPortfolioCode                                 
                                      HAVING SUM(matchQty) > 0
                                      
          INSERT INTO #tt_portfolioDBSum(prodCellCode,secuAcctCode,currencyCode,
                                          exchangeCode,secuCode,longShortFlagCode,
                                          hedgeFlagCode,marketLevelCode,transactionNO,
                                          investPortfolioCode,createPosiDate,posiQty,
                                          matchQty,costChgAmt,rlzChgProfit) 
                                   SELECT prodCellCode,secuAcctCode,currencyCode,
                                          exchangeCode,secuCode,longShortFlagCode,
                                          hedgeFlagCode,marketLevelCode,transactionNO,
                                          investPortfolioCode,@v_settleDate,SUM(matchQty),
                                          0,0,0
                                     FROM #tt_portfolioDBDetail
                                 GROUP BY prodCellCode,secuAcctCode,currencyCode,exchangeCode,secuCode,longShortFlagCode,
                                          hedgeFlagCode,marketLevelCode,transactionNO,investPortfolioCode                                         
                                                                            
         UPDATE a SET createPosiDate = b.createPosiDate, 
                         matchQty = -b.posiQty, 
                         costChgAmt = -b.costChgAmt
                    FROM #tt_portfolioDBSum a 
                    INNER JOIN #tt_portfolioCreatePosiDateDBSum b on a.prodCellCode = b.prodCellCode AND a.investPortfolioCode = b.investPortfolioCode
                    WHERE b.exchangeCode = @v_exchangeCode AND  b.secuCode = @v_secuCode
                    
         DELETE b FROM #tt_portfolioDBSum a 
                   inner join #tt_portfolioCreatePosiDateDBSum b on a.prodCellCode = b.prodCellCode and a.investPortfolioCode = b.investPortfolioCode
                   where b.exchangeCode = @v_exchangeCode AND  b.secuCode = @v_secuCode                                                 
                                      
          SELECT @v_posiQty = SUM(posiQty) FROM #tt_portfolioDBDetail
          
          UPDATE #tt_portfolioDBSum SET rlzChgProfit = ABS(@v_costChgAmt) * ABS(matchQty) / @v_posiQty + costChgAmt
                                                                                                                                                        
          INSERT INTO #tt_portfolioCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
                                                   prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, 
                                                   exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, 
                                                   marketLevelCode, transactionNO, investPortfolioCode, buySellFlagCode, bizSubTypeCode, 
                                                   openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, 
                                                   matchQty, matchNetPrice, matchNetAmt, matchSettlePrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, 
                                                   costChgAmt, occupyCostChgAmt, rlzChgProfit,
                                                   investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                            SELECT @v_serialNO, @v_createPosiDate, @v_settleDate,
                                                   @v_prodCode, prodCellCode,@v_fundAcctCode,@v_secuAcctCode,@v_currencyCode,
                                                   @v_exchangeCode,@v_secuCode,@v_originSecuCode,@v_secuTradeTypeCode,
                                                   @v_marketLevelCode,@v_transactionNO,investPortfolioCode,@v_buySellFlagCode,@v_bizSubTypeCode,
                                                   @v_openCloseFlagCode,@v_longShortFlagCode,@v_hedgeFlagCode,@v_secuBizTypeCode,
                                                   matchQty,@v_matchNetPrice,@v_matchNetAmt,@v_matchSettlePrice,@v_matchSettleAmt,@v_matchTradeFeeAmt,@v_cashCurrentSettleAmt * -matchQty/@v_posiQty,
                                                   costChgAmt,@v_occupyCostChgAmt,rlzChgProfit,
                                                   costChgAmt,@v_occupyCostChgAmt,rlzChgProfit
                                              FROM #tt_portfolioDBSum      
                                                                              
        END
      
      ---------------------------------------现券买入处理-------------------------------------------------------  
      ELSE IF @v_secuBizTypeCode = '301'
        BEGIN
          SELECT @v_createPosiDate  = NULL
          SELECT @v_posiQty         = NULL
          SELECT @v_lastOperateDate = NULL          
          
          SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastOperateDate = lastOperateDate
                 FROM #tt_portfolioCreatePosiDateDBSum
                 WHERE prodCellCode = @v_prodCellCode
                       AND investPortfolioCode = @v_investPortfolioCode
                       AND transactionNO = @v_transactionNO                 
                       AND secuAcctCode = @v_secuAcctCode
                       AND currencyCode = @v_currencyCode
                       AND exchangeCode = @v_exchangeCode
                       AND secuCode = @v_secuCode
                       AND longShortFlagCode = @v_longShortFlagCode
                       AND hedgeFlagCode = @v_hedgeFlagCode
                       AND marketLevelCode = @v_marketLevelCode         
          IF @v_createPosiDate IS NULL
            BEGIN
              INSERT INTO #tt_portfolioCreatePosiDateDBSum(prodCellCode, secuAcctCode, currencyCode, exchangeCode, secuCode, 
                                                           longShortFlagCode, hedgeFlagCode, marketLevelCode, transactionNO, investPortfolioCode, 
                                                           createPosiDate, posiQty, costChgAmt, lastOperateDate)
                                                    VALUES(@v_prodCellCode, @v_secuAcctCode, @v_currencyCode, @v_exchangeCode, @v_secuCode, 
                                                           @v_longShortFlagCode, @v_hedgeFlagCode, @v_marketLevelCode, @v_transactionNO, @v_investPortfolioCode, 
                                                           @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate)
              SELECT @v_createPosiDate = @v_settleDate                                           
            END
          ELSE IF @v_posiQty <= 0 AND @v_lastOperateDate != @v_settleDate
            BEGIN
              UPDATE #tt_portfolioCreatePosiDateDBSum SET createPosiDate = @v_settleDate, posiQty =   @v_matchQty, costChgAmt = @v_costChgAmt, lastOperateDate = @v_settleDate
                                                       WHERE prodCellCode = @v_prodCellCode
                                                             AND investPortfolioCode = @v_investPortfolioCode
                                                             AND transactionNO = @v_transactionNO                 
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
              UPDATE #tt_portfolioCreatePosiDateDBSum SET createPosiDate = @v_settleDate, 
                                                     posiQty = posiQty + @v_matchQty, 
                                                     costChgAmt = costChgAmt + @v_costChgAmt, 
                                                     lastOperateDate = @v_settleDate
                                               WHERE prodCellCode = @v_prodCellCode
                                                     AND investPortfolioCode = @v_investPortfolioCode
                                                     AND transactionNO = @v_transactionNO                 
                                                     AND secuAcctCode = @v_secuAcctCode
                                                     AND currencyCode = @v_currencyCode
                                                     AND exchangeCode = @v_exchangeCode
                                                     AND secuCode = @v_secuCode
                                                     AND longShortFlagCode = @v_longShortFlagCode
                                                     AND hedgeFlagCode = @v_hedgeFlagCode
                                                     AND marketLevelCode = @v_marketLevelCode   
            END
                      
          INSERT INTO #tt_portfolioCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
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
                               FROM #tt_portfolioCreatePosiDateDBSum
                              WHERE prodCellCode = @v_prodCellCode
                                     AND investPortfolioCode = @v_investPortfolioCode
                                     AND transactionNO = @v_transactionNO                 
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
              PRINT '卖出现券数量不足'
              RETURN
            END
            
          SElECT @v_costChgAmt = -ABS(@v_unitCost*@v_matchQty)
          SELECT @v_rlzChgProfit = ABS(@v_cashCurrentSettleAmt)-ABS(@v_unitCost*@v_matchQty)    
            
          UPDATE #tt_portfolioCreatePosiDateDBSum SET costChgAmt = costChgAmt - ABS(@v_unitCost*@v_matchQty), posiQty = posiQty - ABS(@v_matchQty) 
                               WHERE prodCellCode = @v_prodCellCode
                                     AND investPortfolioCode = @v_investPortfolioCode
                                     AND transactionNO = @v_transactionNO                 
                                     AND secuAcctCode = @v_secuAcctCode
                                     AND currencyCode = @v_currencyCode
                                     AND exchangeCode = @v_exchangeCode
                                     AND secuCode = @v_secuCode
                                     AND longShortFlagCode = @v_longShortFlagCode
                                     AND hedgeFlagCode = @v_hedgeFlagCode
                                     AND marketLevelCode = @v_marketLevelCode   
                                     AND posiQty > 0  
                                                                                                          
          INSERT INTO #tt_portfolioCheckJrnlDBHist(serialNO, createPosiDate, settleDate,
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

--exec sims2016Proc..opCalcPortfolioCheckJrnlDB '9999', '1', '','', '', '', ''
--select * from sims2016TradeHist..portfolioCheckJrnlDBHist where secuBizTypeCode in('311', '312') order by serialNO 
--TRUNCATE TABLE sims2016TradeHist..portfolioCheckJrnlDBHist

--select * from sims2016TradeToday..prodCellPosiDB 

--债券买卖功能mock
--组合代码 1000-0001   债券代码 '110032', '三一转债', 'XSHG'
--         1000-0021            '110030', '格力转债', 'XSHG'
--         1000-0022            '019539', '16国债11', 'XSHG'
--         1000-0004
--股份校验
--select min(createPosiDate) as createPosiDate,prodCode, prodCellCode, investPortfolioCode,secuCode,SUM(matchQty) as posiQty, sum(costChgAmt) as costChgAmt, sum(rlzChgProfit) as rlzChgProfit from sims2016TradeHist..portfolioCheckJrnlDBHist
--  group by prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode, longShortFlagCode, hedgeFlagCode, marketLevelCode, investPortfolioCode, transactionNO



--select min(createPosiDate) as createPosiDate,prodCode, prodCellCode, investPortfolioCode,secuCode,SUM(matchQty) as posiQty, sum(costChgAmt) as costChgAmt, sum(rlzChgProfit) as rlzChgProfit from sims2016TradeHist..portfolioCheckJrnlDBHist
--where investPortfolioCode = '1000-0022'
--  group by prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode, longShortFlagCode, hedgeFlagCode, marketLevelCode, investPortfolioCode, transactionNO  


--
--mock_buysell '2017-04-20','1000-0022','b','019539',100 ,112.18
--go
--mock_buysell '2017-04-20','1000-0022','b','019539',100 ,107.82
--go
--mock_buysell '2017-04-21','1000-0022','s','019539',200 ,115.82
--go
--mock_buysell '2017-04-22','1000-0022','b','019539',1000,118.82
--go
--mock_buysell '2017-04-22','1000-0021','b','019539',1000,118.82
--go
--mock_buysell '2017-04-23','1000-0022','s','019539',300 ,115.00
--go
--mock_buysell '2017-04-23','1000-0021','s','019539',800 ,121.82
--go
--mock_buysell '2017-04-23','1000-0004','b','019539',300 ,115.00
--go
--mock_buysell '2017-04-23','1000-0021','b','110030',500 ,107.56
--go
--mock_buysell '2017-04-24','1000-0021','s','019539',100 ,121.82
--go
--mock_buysell '2017-04-24','1000-0004','s','019539',100 ,115.00
--go
--
--mock_buysell '2017-05-04','1000-0022','s','110030',700 ,108
--go
--delete from sims2016TradeHist..prodCellRawJrnlDBHist where operatorCode = 'GGSMD'
/***************************************************************************

jrnl01  2017-04-20  1000    1000-01    b    100        1000-002    1000-0022   019539   16国债11  

jrnl02  2017-04-20  1000    1000-01    b    100        1000-002    1000-0022   019539   16国债11  

jrnl03  2017-04-21  1000    1000-01    s    200        1000-002    1000-0022   019539   16国债11  

jrnl04  2017-04-22  1000    1000-01    b    1000       1000-002    1000-0022   019539   16国债11

jrnl05  2017-04-22  1000    1000-01    b    1000       1000-002    1000-0021   019539   16国债11

jrnl06  2017-04-23  1000    1000-01    s    300        1000-002    1000-0022   019539   16国债11

jrnl07  2017-04-23  1000    1000-01    s    800        1000-002    1000-0021   019539   16国债11

jrnl08  2017-04-23  1000    1000-01    b    300        1000-003    1000-0004   019539   16国债11

jrnl09  2017-04-23  1000    1000-01    b    500        1000-002    1000-0021   110030   格力转债

jrnl10  2017-04-24  1000    1000-01    s    100        1000-002    1000-0021   019539   16国债11

jrnl11  2017-04-24  1000    1000-01    s    100        1000-003    1000-0004   019539   16国债11

***************************************************************************/
--USE master
--go
--IF exists (SELECT 1 FROM sysobjects WHERE name = 'mock_buysell')
--  DROP PROC mock_buysell
--go

--CREATE PROC mock_buysell
--  @p_settleDate        VARCHAR(10),
--  @p_investPofiloCode  VARCHAR(255),
--  @p_buySellCode       VARCHAR(2),  --'b'买, 's'卖
--  @p_secuCode          VARCHAR(50),
--  @p_matchQty          INT,
--  @p_matchPrice        NUMERIC(19,4) 
--AS
--SET NOCOUNT ON
--  CREATE TABLE #tt_accout(
--      prodCode                         VARCHAR(30)                                        NOT NULL,          -- 产品代码
--      prodCellCode                     VARCHAR(30)                                        NOT NULL,          -- 产品单元代码
--      fundAccountCode                  VARCHAR(30)                                        NOT NULL,
--      currencyCode                     VARCHAR(3)         DEFAULT 'CNY'                   NOT NULL,          --货币代码
--      longShortFlagCode                VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --多空标志 
--      hedgeFlagCode                    VARCHAR(1)         DEFAULT '1'                     NOT NULL,          --投保标志
--      marketLevelCode                  VARCHAR(1)         DEFAULT '2'                     NOT NULL,          --市场级别
--      transactionNO                    NUMERIC(19,0)      DEFAULT 1                       NOT NULL,         -- 交易编号
--      investPortfolioCode              VARCHAR(40)                                        NOT NULL,          --投资组合
--  )
--  TRUNCATE TABLE #tt_accout
--  INSERT INTO #tt_accout(prodCode,fundAccountCode, prodCellCode, investPortfolioCode)VALUES('1000', '1000-01', '1000-001', '1000-0001')
--  INSERT INTO #tt_accout(prodCode,fundAccountCode, prodCellCode, investPortfolioCode)VALUES('1000', '1000-01', '1000-002', '1000-0021')
--  INSERT INTO #tt_accout(prodCode,fundAccountCode, prodCellCode, investPortfolioCode)VALUES('1000', '1000-01', '1000-002', '1000-0022')  
--  INSERT INTO #tt_accout(prodCode,fundAccountCode, prodCellCode, investPortfolioCode)VALUES('1000', '1000-01', '1000-003', '1000-0004')
  
--  CREATE TABLE #tt_secu(
--    secuCode                       VARCHAR(30)                        NOT NULL,
--    secuName                       VARCHAR(30)                        NOT NULL,
--    exchangeCode                   VARCHAR(4)                         NOT NULL
--  ) 
--  INSERT #tt_secu(secuCode, secuName, exchangeCode) VALUES('110032', '三一转债', 'XSHG')
--  INSERT #tt_secu(secuCode, secuName, exchangeCode) VALUES('110030', '格力转债', 'XSHG')
--  INSERT #tt_secu(secuCode, secuName, exchangeCode) VALUES('019539', '16国债11', 'XSHG')
  
--  DECLARE @serialNo int
--  SELECT @serialNo = cast(floor(rand()*100000)AS INT)
--  SELECT * INTO #temp_record FROM sims2016TradeHist..prodRawJrnlDBHist WHERE 0=1
--  INSERT INTO #temp_record(serialNO, settleDate, secuBizTypeCode, buySellFlagCode, 
--                           bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
--                           originSecuBizTypeCode, brokerSecuBizTypeCode, 
--                           brokerSecuBizTypeName, brokerJrnlSerialID, prodCode,
--                           prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, 
--                           cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, 
--                           originSecuCode, secuName, secuTradeTypeCode, matchQty,
--                           posiBalanceQty, matchNetPrice, matchNetAmt, 
--                           dataSourceFlagCode, marketLevelCode, matchSettlePrice, 
--                           matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, 
--                           matchID, repoSettleDate, repoSettleAmt, brokerOrderID, 
--                           brokerOriginOrderID, brokerErrorMsg, transactionNO, investPortfolioCode,
--                           assetLiabilityTypeCode, investInstrucNO, traderInstrucNO, orderNO, 
--                           orderNetAmt, orderNetPrice, orderQty, orderSettleAmt, orderSettlePrice, 
--                           orderTradeFeeAmt, directorCode, traderCode, 
--                           operatorCode, operateDatetime, operateRemarkText)
--                     VALUES(@serialNo, '2017-04-25', '301', '1', 'B1',
--                           '1', '1', 'XQMR', 'XQMR', '现券买入',
--                           cast(floor(rand()*100000)as Varchar(10)),
--                           '1000', '1000-002', '1000-01', 'CNY', 0, 0,
--                           'XSHG', 'A20160919', '110030', '', '格力转债',
--                           'DBV', 200, 0, 105.20, 21040, '0', '2', 200,
--                           21040, 0, '2017-04-25', '', '000000021', '',
--                           0, '', '', '', 0, '1000-0002', '', 0,
--                           1, 0, 0, 0, 0, 0, 0, 0, '', '', '', getDate(), '')
    
--   DECLARE 
--     @secuBizTypeCode VARCHAR(30) = '301',
--     @originSecuBizTypeCode VARCHAR(30) = 'XQMR',
--     @brokerSecuBizTypeCode VARCHAR(30) = 'XQMR',
--     @brokerSecuBizTypeName VARCHAR(30) = '现券买入',
--     @openCloseFlageCode    VARCHAR(10) = '1'
   
--   IF @p_buySellCode = 's'
--     BEGIN
--       SELECT @secuBizTypeCode  = '302',
--              @originSecuBizTypeCode  = 'XQMC',
--              @brokerSecuBizTypeCode  = 'XQMC',
--              @brokerSecuBizTypeName  = '现券买出',
--              @openCloseFlageCode     = 'A' ,
--              @p_matchQty = -@p_matchQty            
--     END
     
--  DECLARE
--    @prodCode VARCHAR(30),
--    @prodCellCode VARCHAR(30),
--    @fundAccoutCode VARCHAR(30)
    
--  SELECT @prodCode = prodCode, @prodCellCode = prodCellCode, @fundAccoutCode = fundAccountCode FROM #tt_accout WHERE investPortfolioCode = @p_investPofiloCode
  
--  IF @prodCode IS NULL
--    BEGIN
--      SELECT @prodCode = SUBSTRING(@p_investPofiloCode,1,4)
--      SELECT @prodCellCode = SUBSTRING(@p_investPofiloCode,1,5) + SUBSTRING(@p_investPofiloCode,7,10)
--      SELECT @fundAccoutCode = SUBSTRING(@p_investPofiloCode,1,5) + SUBSTRING(@p_investPofiloCode,8,10) 
--    END
    
--  DECLARE 
--    @secuName VARCHAR(30),
--    @exchangeCode VARCHAR(30)
    
--  SELECT @secuName = secuName, @exchangeCode = exchangeCode FROM #tt_secu WHERE secuCode = @p_secuCode    

--  UPDATE #temp_record SET secuBizTypeCode = @secuBizTypeCode,
--                          originSecuBizTypeCode = @originSecuBizTypeCode,
--                          brokerSecuBizTypeCode = @brokerSecuBizTypeCode,
--                          brokerSecuBizTypeName = @brokerSecuBizTypeName,
--                          prodCode = @prodCode,
--                          prodCellCode = @prodCellCode,
--                          fundAcctCode = @fundAccoutCode,
--                          matchQty = @p_matchQty,
--                          matchNetPrice = @p_matchPrice,
--                          matchNetAmt = @p_matchQty * @p_matchPrice,
--                          matchSettlePrice = @p_matchPrice,
--                          matchSettleAmt = @p_matchQty * @p_matchPrice,
--                          cashSettleAmt = -@p_matchQty * @p_matchPrice,
--                          settleDate = @p_settleDate,
--                          matchDate = @p_settleDate,
--                          secuCode = @p_secuCode,
--                          secuName = @secuName,
--                          exchangeCode = @exchangeCode,
--                          openCloseFlagCode = @openCloseFlageCode,
--                          investPortfolioCode =@p_investPofiloCode,
--                          operatorCode = 'GGSMD'                   
--   INSERT INTO sims2016TradeHist..prodCellRawJrnlDBHist(serialNO, settleDate, secuBizTypeCode, buySellFlagCode, 
--                                                        bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
--                                                        originSecuBizTypeCode, brokerSecuBizTypeCode, 
--                                                        brokerSecuBizTypeName, brokerJrnlSerialID, prodCode,
--                                                        prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, 
--                                                        cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, 
--                                                        originSecuCode, secuName, secuTradeTypeCode, matchQty,
--                                                        posiBalanceQty, matchNetPrice, matchNetAmt, 
--                                                        dataSourceFlagCode, marketLevelCode, matchSettlePrice, 
--                                                        matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, 
--                                                        matchID, repoSettleDate, repoSettleAmt, brokerOrderID, 
--                                                        brokerOriginOrderID, brokerErrorMsg, transactionNO, investPortfolioCode,
--                                                        assetLiabilityTypeCode, investInstrucNO, traderInstrucNO, orderNO, 
--                                                        orderNetAmt, orderNetPrice, orderQty, orderSettleAmt, orderSettlePrice, 
--                                                        orderTradeFeeAmt, directorCode, traderCode, 
--                                                        operatorCode, operateDatetime, operateRemarkText) 
--                                                 SELECT serialNO, settleDate, secuBizTypeCode, buySellFlagCode, 
--                                                        bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
--                                                        originSecuBizTypeCode, brokerSecuBizTypeCode, 
--                                                        brokerSecuBizTypeName, brokerJrnlSerialID, prodCode,
--                                                        prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, 
--                                                        cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, 
--                                                        originSecuCode, secuName, secuTradeTypeCode, matchQty,
--                                                        posiBalanceQty, matchNetPrice, matchNetAmt, 
--                                                        dataSourceFlagCode, marketLevelCode, matchSettlePrice, 
--                                                        matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, 
--                                                        matchID, repoSettleDate, repoSettleAmt, brokerOrderID, 
--                                                        brokerOriginOrderID, brokerErrorMsg, transactionNO, investPortfolioCode,
--                                                        assetLiabilityTypeCode, investInstrucNO, traderInstrucNO, orderNO, 
--                                                        orderNetAmt, orderNetPrice, orderQty, orderSettleAmt, orderSettlePrice, 
--                                                        orderTradeFeeAmt, directorCode, traderCode, 
--                                                        operatorCode, operateDatetime, operateRemarkText FROM #temp_record
--   SELECT @serialNo                          
-- RETURN 0
--go

--select * from sims2016TradeHist..prodCellRawJrnlDBHist where investPortfolioCode = '1000-0022' --27870
--delete from sims2016TradeHist..prodCellRawJrnlDBHist where serialNO = 27870
--select cashSettleAmt from sims2016TradeHist..prodRawJrnlDBHist where investPortfolioCode = '1000-0022'

--select * from sims2016TradeHist..portfolioCheckJrnlDBHist where investPortfolioCode = '1000-0022' order by settleDate
----delete from sims2016TradeHist..prodCellRawJrnlDBHist where operatorCode = 'GGSMD'

--select * from sims2016TradeHist..prodRawJrnlDBHist where secuBizTypeCode in( '311', '312')
--select * from sims2016TradeHist..prodCellRawJrnlDBHist where secuBizTypeCode in ( '311', '312')

--insert into sims2016TradeHist..prodRawJrnlDBHist select * from sims2016TradeHist..prodRawJrnlDBHist where secuBizTypeCode in( '311')

--select * from sims2016TradeHist..portfolioCheckJrnlDBHist where secuBizTypeCode = '312'

--select costChgAmt,* from sims2016TradeHist..portfolioCheckJrnlDBHist where secuCode = '110030' and prodCellCode = '1000-002' and investPortfolioCode ='1000-0021'