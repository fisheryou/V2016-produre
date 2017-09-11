USE sims2016Proc
  go
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'opCalcPortfolioCheckJrnlES')
  DROP PROC opCalcPortfolioCheckJrnlES
go

CREATE PROC opCalcPortfolioCheckJrnlES
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
--    V1.0 ： 支持股票买卖成交、送股派息、转入转出业务
-- Date : 2017-04-06
-- Description : 产品单元组合股票买入卖出成本的核算、送股派息处理、转入传出处理,相应流水生成
-- Function List : opCalcPortfolioCheckJrnlES
-- History : 

****************************************************************************/
SET NOCOUNT ON
 
CREATE TABLE #tt_portfolioRawJrnl(
  serialNO                  NUMERIC(20,0)                            ,          --记录序号
  orderID                   NUMERIC(5, 0)     DEFAULT 0      NOT NULL,          --排序Id
  occurDate                 VARCHAR(10)                      NOT NULL,          --发生日期
  shareRecordDate           VARCHAR(10)       DEFAULT ' '    NULL    ,          --登记日期
  ----------------------------------------------------------------------------------------------------------------------
  fundAcctCode              VARCHAR(20)                      NOT NULL,          --资金账户
  secuAcctCode              VARCHAR(20)       DEFAULT ' '    NOT NULL,
  prodCode                  VARCHAR(20)                      NOT NULL,          --产品代码
  prodCellCode              VARCHAR(20)       DEFAULT ' '    NOT NULL,          --产品单元代码
  investPortfolioCode       VARCHAR(20)       DEFAULT ' '    NOT NULL,          --投资组合代码
  transactionNO             NUMERIC(20, 0)    DEFAULT 1      NOT NULL,          --交易编号
  ----------------------------------------------------------------------------------------------------------------------
  currencyCode              VARCHAR(6)                       NOT NULL,          --货币代码
  marketLevelCode           VARCHAR(1)        DEFAULT '2'    NOT NULL,          --市场来源
  exchangeCode              VARCHAR(6)                       NOT NULL,          --交易所代码
  secuCode                  VARCHAR(6)                       NOT NULL,          --证券代码
  originSecuCode            VARCHAR(15)                      NOT NULL,          --原始证券代码
  secuTradeTypeCode         VARCHAR(5)                       NOT NULL,          --证券类别
  ----------------------------------------------------------------------------------------------------------------------
  secuBizTypeCode           VARCHAR(16)                      NOT NULL,          --业务类型
  bizSubTypeCode            VARCHAR(16)       DEFAULT 'S1'   NOT NULL,          --业务子类
  openCloseFlagCode         VARCHAR(16)                      NOT NULL,          --开平标志
  longShortFlagCode         VARCHAR(16)       DEFAULT '1'    NOT NULL,          --多空标志
  hedgeFlagCode             VARCHAR(16)       DEFAULT ''     NOT NULL,          --投保标志
  buySellFlagCode           VARCHAR(1)        DEFAULT '1'    NOT NULL,          --买卖类别
  ------------------------------------------------------------------------------------------------------------------------
  matchQty                  NUMERIC(10,0)     DEFAULT 0      NOT NULL,          --成交数量
  matchNetPrice             NUMERIC(10,2)     DEFAULT 0      NOT NULL,          --成交价格
  matchSettleAmt            NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --成交结算金额
  matchTradeFeeAmt          NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --手续费
  cashSettleAmt      NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --资金发生数
  ------------------------------------------------------------------------------------------------------------------------
  costChgAmt                NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --移动平均成本变动
  rlzChgProfit              NUMERIC(19,2)     DEFAULT 0      NOT NULL           --实现盈亏变动
 )
 
CREATE TABLE #tt_portfolioCheckJrnlES
(
  serialNO                  NUMERIC(20, 0)                           ,          --记录序号
  createPosiDate            VARCHAR(10)                      NOT NULL,          --建仓日期
  occurDate                 VARCHAR(10)                      NOT NULL,          --发生日期
  shareRecordDate           VARCHAR(10)       DEFAULT ' '        NULL,          --登记日期
  fundAcctCode              VARCHAR(20)                      NOT NULL,          --资金账户
  secuAcctCode              VARCHAR(20)       DEFAULT ' '    NOT NULL,          
  exchangeCode              VARCHAR(6)                       NOT NULL,          --交易所代码
  secuCode                  VARCHAR(6)                       NOT NULL,          --证券代码
  originSecuCode            VARCHAR(15)                      NOT NULL,          --原始证券代码
  secuName                  VARCHAR(15)                      NOT NULL,          --证券名称
  secuTradeTypeCode         VARCHAR(5)                       NOT NULL,          --证券类别
  prodCellCode              VARCHAR(20)       DEFAULT ' '    NOT NULL,          --产品单元代码
  prodCode                  VARCHAR(20)       DEFAULT ' '    NOT NULL,          --产品代码
  investPortfolioCode       VARCHAR(20)       DEFAULT ' '    NOT NULL,          --投资组合代码
  buySellFlagCode           VARCHAR(1)                       NOT NULL,          --买卖类别
  openCloseFlagCode         VARCHAR(1)                       NOT NULL,          --开平标志
  secuBizTypeCode           VARCHAR(16)                      NOT NULL,          --业务类型
  currencyCode              VARCHAR(6)                       NOT NULL,          --货币代码
  marketLevelCode           VARCHAR(1)        DEFAULT '2'    NOT NULL,          --市场来源
  hedgeFlagCode             VARCHAR(16)       DEFAULT ''     NOT NULL,          --投保标志
  matchQty                  NUMERIC(10, 0)    DEFAULT 0      NOT NULL,          --成交数量
  matchNetPrice             NUMERIC(10, 2)    DEFAULT 0      NOT NULL,          --成交价格
  cashSettleAmt      NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --资金发生数
  matchSettleAmt            NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --成交结算金额
  matchTradeFeeAmt          NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --手续费
  costChgAmt                NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --移动平均成本变动
  occupyCostChgAmt          NUMERIC(19,2)     DEFAULT 0      NOT NULL,          --持仓成本变动
  rlzChgProfit              NUMERIC(19,2)     DEFAULT 0      NOT NULL           --实现盈亏变动
)
 
CREATE TABLE #tt_portfolioCreatePosiDate
(
  exchangeCode              VARCHAR(4)                       NOT NULL,          --交易所代码
  secuCode                  VARCHAR(30)                      NOT NULL,          --证券代码
  prodCellCode              VARCHAR(30)                      NOT NULL,          --单元代码
  investPortfolioCode       VARCHAR(20)                      NOT NULL,          --组合代码
  createPosiDate            VARCHAR(10)                      NOT NULL,          --建仓日期
  posiQty                   NUMERIC(19,4)                    NOT NULL,          --持仓数量
  costChgAmt                NUMERIC(19,4)                    NOT NULL,          --成本变动金额
  lastCreatePosiDate        VARCHAR(10)                      NOT NULL           --最后操作日期
)

CREATE TABLE #tt_portfolioCreatePosiDateSum
(
  exchangeCode              VARCHAR(4)                       NOT NULL,          --交易所代码
  secuCode                  VARCHAR(30)                      NOT NULL,          --证券代码
  prodCellCode              VARCHAR(30)                      NOT NULL,          --单元代码
  investPortfolioCode       VARCHAR(20)                      NOT NULL,          --组合代码
  createPosiDate            VARCHAR(10)                      NOT NULL,          --建仓日期
  posiQty                   NUMERIC(19,4)                    NOT NULL,          --持仓数量
  costChgAmt                NUMERIC(19,4)                    NOT NULL,          --成本变动金额
  lastestoperateDate        VARCHAR(10)                      NOT NULL           --最后操作日期
)

CREATE TABLE #tt_portfolioCreatePosiDateAllotment
(
  exchangeCode              VARCHAR(4)                       NOT NULL,          --交易所代码
  secuCode                  VARCHAR(30)                      NOT NULL,          --证券代码
  secuCode0                 VARCHAR(30)                      NOT NULL,          --证券代码
  secuBizTypeCode           VARCHAR(30)                      NOT NULL,          
  prodCellCode              VARCHAR(30)                      NOT NULL,          --单元代码
  investPortfolioCode       VARCHAR(20)     DEFAULT  ''      NOT NULL ,          --组合代码
  createPosiDate            VARCHAR(10)                      NOT NULL,          --建仓日期
  posiQty                   NUMERIC(19,4)                    NOT NULL,          --持仓数量
  costChgAmt                NUMERIC(19,4)                    NOT NULL,          --成本变动金额
  lastestoperateDate        VARCHAR(10)                      NOT NULL           --最后操作日期
)

CREATE TABLE #tt_portfolioCheckJrnl_old
(
  operateDate               VARCHAR(10)                      NOT NULL,          -- 发生日期
  exchangeCode              VARCHAR(4)                       NOT NULL,          -- 交易所代码
  secuCode                  VARCHAR(30)                      NOT NULL,          -- 证券代码
  prodCellCode              VARCHAR(30)                      NOT NULL,          -- 单元代码
  investPortfolioCode       VARCHAR(30)                      NOT NULL,          -- 组合代码
  posiQty                   NUMERIC(19,4)                    NOT NULL           -- 持仓数量
)

CREATE TABLE #tt_portfolioPosiQtyDetial
(
  createPosiDate           VARCHAR(10)                       NOT NULL,          --建仓日期
  prodCellCode             VARCHAR(30)                       NOT NULL,          --单元代码
  investPortfolioCode      VARCHAR(30)                       NOT NULL,          -- 组合代码
  posiQty                  NUMERIC(19,4)                     NOT NULL,          --持仓数量
  matchQty                 NUMERIC(19,4)                     NOT NULL,          --成交数量
  costChgAmt               NUMERIC(19,4)                     NOT NULL           --成本变动金额
)

CREATE TABLE #tt_portfolioPosiQtySum
(
  createPosiDate           VARCHAR(10)                       NOT NULL,          --建仓日期
  prodCellCode             VARCHAR(30)                       NOT NULL,          --单元代码
  investPortfolioCode      VARCHAR(30)                       NOT NULL,          -- 组合代码
  posiQty                  NUMERIC(19,4)                     NOT NULL,          --持仓数量
  matchQty                 NUMERIC(19,4)                     NOT NULL,          --成交数量
  costChgAmt               NUMERIC(19,4)                     NOT NULL,          --成本变动金额
  rlzChgProfit             NUMERIC(19,4)                     NOT NULL           --盈亏变动金额
)

CREATE TABLE #tt_sgwtb
(
  settleDate               VARCHAR(10)                       NOT NULL,
  occurTime                DATETIME                          NOT NULL, 
  exchangeCode             VARCHAR(4)                        NOT NULL,           -- 交易所代码
  secuCode                 VARCHAR(10)                       NOT NULL,           --
  fundAcctCode             VARCHAR(10)                       NOT NULL,           
  prodCellCode             VARCHAR(20)                       NOT NULL,           
  investPortfolioCode      VARCHAR(30)                       NOT NULL,           -- 组合代码
  macthQty                 DECIMAL(19, 2)                    NOT NULL,
)
--
DECLARE 
  @v_createPosiDate                 VARCHAR(10),           --建仓日期
  @v_posiQty                        NUMERIC(19,4),         --持仓数量
  @v_lastSettleDate                 VARCHAR(10),           --最后建仓日期

  @temp_prodCellCode                VARCHAR(20),           --产品单元代码
  @temp_shareRecordDate             VARCHAR(10),           --登记日期(临时变量)
  @temp_mc_matchQty                 NUMERIC(10,0),         --卖出成交数量(临时变量)
  @temp_mc_per_costChgAmt           NUMERIC(19,2),         --卖出移动平均成本变动(临时变量)
  @temp_mc_costChgAmt               NUMERIC(19,2),         --买入移动平均成本变动(临时变量)
  @temp_mc_per_rlzChgProfit         NUMERIC(19,2),         --卖出实现盈亏变动(临时变量)
  @temp_mc_rlzChgProfit             NUMERIC(19,2),         --卖出实现盈亏变动(临时变量)
  @temp_mc_per_cashCurrSettleAmt    NUMERIC(19,2),         --卖出资金发生数(临时变量)
  @temp_mc_cashCurrSettleAmt        NUMERIC(19,2),         --卖出资金发生数(临时变量)
  @temp_mc_per_matchTradeFeeAmt     NUMERIC(19,2),         --卖出交易费用(临时变量)
  @temp_mc_matchTradeFeeAmt         NUMERIC(19,2),         --卖出交易费用(临时变量)
  
  @temp_mr_prodCellCode             VARCHAR(20),           --买入产品单元代码(临时变量)
  @temp_mr_investPortfolioCode      VARCHAR(20),           --买入产品单元代码(临时变量)
  @temp_mr_secuCode                 VARCHAR(20),           --买入证券代码(临时变量)
  @temp_mr_matchQty                 NUMERIC(10,0),         --买入成交数量(临时变量)
  @temp_mr_per_costChgAmt           NUMERIC(19,2),         --买入移动平均成本变动1(临时变量)
  @temp_mr_costChgAmt               NUMERIC(19,2),         --买入移动平均成本变动(临时变量)
  @temp_mr_createPosiDate           VARCHAR(10),           --买入建仓日期(临时变量)

  @v_tempCellCode                   VARCHAR(30),  
  @sgwtzsl                          NUMERIC(10,0),
  @mr_lastestUnit                   INT                     

--取当前日期
  DECLARE @v_today CHAR(10)
  SELECT @v_today = CONVERT(CHAR(10), GETDATE(), 20)
--计算成本计算开始日期
 --todo
  DECLARE @v_realBeginDate CHAR(10) = '2000-01-01'
 
 --判断资金账户是否上下线
 --todo
  --删除产品单元股票核算流水
  DELETE sims2016TradeHist..portfolioCheckJrnlESHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
 
  --删除非交易类流水
  DELETE sims2016TradeHist..prodCellRawJrnlESHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
               AND  secuBizTypeCode  IN ('183', '187', '188')

  
  --删除非交易类流水
  DELETE sims2016TradeHist..prodCellRawJrnlHist
         WHERE settleDate >= @v_realBeginDate
               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
               AND secuBizTypeCode  IN ('183', '187', '188')
               
  --汇总成交
  INSERT INTO #tt_portfolioRawJrnl(serialNO, orderID, occurDate, fundAcctCode, secuAcctCode, 
                                   prodCode, prodCellCode, investPortfolioCode,
                                   transactionNO, currencyCode, marketLevelCode, 
                                   exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, bizSubTypeCode,
                                   openCloseFlagCode, longShortFlagCode, hedgeFlagCode,
                                   buySellFlagCode, matchQty,
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, costChgAmt, rlzChgProfit)
                            SELECT MAX(serialNO), 0, settleDate, fundAcctCode, secuAcctCode,
                                   MAX(prodCode), prodCellCode, investPortfolioCode,
                                   MAX(transactionNO), MAX(currencyCode), MAX(marketLevelCode),
                                   exchangeCode, secuCode, MAX(originSecuCode),
                                   MAX(secuTradeTypeCode), secuBizTypeCode, MAX(bizSubTypeCode),
                                   openCloseFlagCode, '1', MAX(hedgeFlagCode),
                                   MAX(buySellFlagCode), SUM(ABS(matchQty)),
                                   CASE WHEN SUM(matchQty) = 0 THEN 0
                                        ELSE SUM(matchQty * matchNetPrice) / SUM(matchQty)END,
                                   SUM(matchSettleAmt), SUM(matchTradeFeeAmt),
                                   SUM(cashSettleAmt), SUM(-cashSettleAmt), 0
                              FROM sims2016TradeHist..prodCellRawJrnlESHist a
                             WHERE settleDate >= @v_realBeginDate
                                       AND settleDate >= @i_beginDate
                                       AND settleDate <= @v_today  
                                       AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                       AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                             GROUP BY settleDate, fundAcctCode, secuAcctCode, prodCellCode, exchangeCode, secuCode, openCloseFlagCode, secuBizTypeCode, investPortfolioCode
                             ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, investPortfolioCode, secuBizTypeCode, openCloseFlagCode
                             
     
     select * from #tt_portfolioRawJrnl
                             
                                                                                                             
  --取产品股票送股派息流水
  INSERT INTO #tt_portfolioRawJrnl(serialNO, orderID, occurDate,--记录序号, 处理排序编号, 业务发生日期                                    
                                   shareRecordDate,fundAcctCode, secuAcctCode, prodCode,--送红派息登记日期, 资金账户代码, 产品代码
                                   prodCellCode, investPortfolioCode, transactionNO,--产品单元代码, 投资组合代码, 交易编号
                                   currencyCode, marketLevelCode, exchangeCode,--货币代码, 市场来源代码, 交易所代码
                                   secuCode, originSecuCode, secuTradeTypeCode,--证券代码, 原始证券代码,证券交易类型代码 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,--证券业务类别代码, 业务之类, 开平标志
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,--多空标志, 投保标志, 买卖标志
                                   matchQty, matchNetPrice, matchSettleAmt,--成交数量, 成交价格, 成交金额
                                   matchTradeFeeAmt, cashSettleAmt,--成交费用, 资金发生数
                                   costChgAmt, rlzChgProfit--持仓成本金额变动, 持仓实现盈亏变动
                                   )
                            SELECT serialNO, 100, settleDate,
                                   shareRecordDate, fundAcctCode, secuAcctCode, prodCode,
                                   prodCellCode, investPortfolioCode, transactionNO,
                                   currencyCode, marketLevelCode, exchangeCode,
                                   secuCode, originSecuCode, secuTradeTypeCode,
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,
                                   '1', hedgeFlagCode, buySellFlagCode,
                                   ABS(matchQty), matchNetPrice, matchSettleAmt,
                                   matchTradeFeeAmt, cashSettleAmt,
                                   0, 0
                              FROM sims2016TradeHist..prodRawJrnlESHist a
                             WHERE settleDate >= @v_realBeginDate
                               AND settleDate <= @v_today
                               AND shareRecordDate != ' '
                               AND secuBizTypeCode  IN ('183', '187', '188', '122')
                               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                               AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                            ORDER BY fundAcctCode, settleDate
                            
  --SELECT * FROM #tt_portfolioRawJrnl WHERE secuBizTypeCode  IN ('183', '187', '188')
    
  --申购买入,申购卖出,申购中签,新股上市
  INSERT INTO #tt_portfolioRawJrnl(serialNO, orderID, occurDate, fundAcctCode, secuAcctCode, 
                                   prodCode, prodCellCode, investPortfolioCode,
                                   transactionNO, currencyCode, marketLevelCode, 
                                   exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, bizSubTypeCode,
                                   openCloseFlagCode, longShortFlagCode, hedgeFlagCode,
                                   buySellFlagCode, matchQty,
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, costChgAmt, rlzChgProfit)
                            SELECT MAX(serialNO), 0, settleDate, fundAcctCode, secuAcctCode,
                                   MAX(prodCode), prodCellCode, investPortfolioCode,
                                   MAX(transactionNO), MAX(currencyCode), MAX(marketLevelCode),
                                   exchangeCode, secuCode, MAX(originSecuCode),
                                   MAX(secuTradeTypeCode), secuBizTypeCode, MAX(bizSubTypeCode),
                                   openCloseFlagCode, '1', MAX(hedgeFlagCode),
                                   MAX(buySellFlagCode), SUM(ABS(matchQty)),
                                   CASE WHEN SUM(matchQty) = 0 THEN 0
                                        ELSE SUM(matchQty * matchNetPrice) / SUM(matchQty)END,
                                   SUM(matchSettleAmt), SUM(matchTradeFeeAmt),
                                   SUM(cashSettleAmt), SUM(-cashSettleAmt), 0
                              FROM sims2016TradeHist..prodRawJrnlESHist a 
                             WHERE settleDate >= @i_beginDate
                               AND settleDate <= @v_today
                               AND (@i_exchangeCode = '' OR CHARINDEX(a.exchangeCode, @i_exchangeCode) > 0) 
                               AND (@i_secuCode = '' OR CHARINDEX(a.secuCode, @i_secuCode) > 0 OR CHARINDEX(a.secuCode, @i_secuCode) > 0)
                               AND exchangeCode != ''
                               AND secuCode != ''
                               AND secuBizTypeCode IN ('103', '105', '106', '107')
                               AND matchQty != 0
                          GROUP BY settleDate, fundAcctCode, secuAcctCode, prodCellCode, exchangeCode, secuCode, openCloseFlagCode, secuBizTypeCode, investPortfolioCode
                          ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, investPortfolioCode, secuBizTypeCode, openCloseFlagCode
                                   
  --配股缴款
  INSERT INTO #tt_portfolioRawJrnl(serialNO, orderID, occurDate, fundAcctCode, secuAcctCode, 
                                   prodCode, prodCellCode, investPortfolioCode,
                                   transactionNO, currencyCode, marketLevelCode, 
                                   exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, bizSubTypeCode,
                                   openCloseFlagCode, longShortFlagCode, hedgeFlagCode,
                                   buySellFlagCode, matchQty,
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, costChgAmt, rlzChgProfit)
                            SELECT MAX(serialNO), 0, settleDate, fundAcctCode, secuAcctCode,
                                   MAX(prodCode), prodCellCode, investPortfolioCode,
                                   MAX(transactionNO), MAX(currencyCode), MAX(marketLevelCode),
                                   exchangeCode, secuCode, MAX(originSecuCode),
                                   MAX(secuTradeTypeCode), secuBizTypeCode, MAX(bizSubTypeCode),
                                   openCloseFlagCode, '1', MAX(hedgeFlagCode),
                                   MAX(buySellFlagCode), SUM(ABS(matchQty)),
                                   CASE WHEN SUM(matchQty) = 0 THEN 0
                                        ELSE SUM(matchQty * matchNetPrice) / SUM(matchQty)END,
                                   SUM(matchSettleAmt), SUM(matchTradeFeeAmt),
                                   SUM(cashSettleAmt), SUM(-cashSettleAmt), 0
                              FROM sims2016TradeHist..prodRawJrnlESHist a 
                             WHERE settleDate >= @i_beginDate
                                   AND settleDate <= @v_today
                                   AND (@i_exchangeCode = '' OR CHARINDEX(a.exchangeCode, @i_exchangeCode) > 0) 
                                   AND (@i_secuCode = '' OR CHARINDEX(a.secuCode, @i_secuCode) > 0 OR CHARINDEX(a.secuCode, @i_secuCode) > 0)
                                   AND exchangeCode != ''
                                   AND secuCode != ''
                                   AND secuBizTypeCode IN ('123')
                                   AND matchQty != 0
                                   AND (cashBalanceAmt != 0 OR matchSettleAmt != 0 OR dataSourceFlagCode != '0')
                              GROUP BY settleDate, fundAcctCode, secuAcctCode, prodCellCode, exchangeCode, secuCode, openCloseFlagCode, secuBizTypeCode, investPortfolioCode
                              ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, investPortfolioCode, secuBizTypeCode, openCloseFlagCode
                                                                                                                                                           
  ---------------------------------- 非交易过户的配股上市
  -- 注意，对于配股上市，当前根据交易流水中的 PGSS记录直接进行处理（后续尚将考虑另外一个异常方案：即柜台无配股上市流水的情况，也应该由系统自动根据权益信息补充原始的配股上市流水）。
  INSERT INTO #tt_portfolioRawJrnl(serialNO, orderID, occurDate, fundAcctCode, secuAcctCode, 
                                   prodCode, prodCellCode, investPortfolioCode,
                                   transactionNO, currencyCode, marketLevelCode, 
                                   exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, bizSubTypeCode,
                                   openCloseFlagCode, longShortFlagCode, hedgeFlagCode,
                                   buySellFlagCode, matchQty,
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, costChgAmt, rlzChgProfit)
                            SELECT serialNO, 100, settleDate, fundAcctCode, secuAcctCode, 
                                   prodCode, prodCellCode, investPortfolioCode,
                                   transactionNO, currencyCode, marketLevelCode, 
                                   exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, bizSubTypeCode,
                                   openCloseFlagCode, ' ', hedgeFlagCode,
                                   buySellFlagCode, matchQty,
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, 0, 0
                              FROM sims2016TradeHist..prodRawJrnlESHist a 
                             WHERE settleDate >= @i_beginDate
                                   AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0) 
                                   AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
                                   AND secuBizTypeCode  IN ('124')
                                   AND matchQty > 0
                             ORDER BY fundAcctCode, settleDate                                                  
                                                                            
  INSERT INTO #tt_portfolioRawJrnl(serialNO, orderID, occurDate, fundAcctCode, secuAcctCode, prodCode,
                                   prodCellCode, investPortfolioCode, transactionNO, currencyCode,
                                   marketLevelCode, exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode, matchQty,
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt,
                                   costChgAmt, rlzChgProfit)
                            SELECT serialNO, 0, settleDate, fundAcctCode, secuAcctCode, prodCode,
                                   prodCellCode, investPortfolioCode, transactionNO, currencyCode,
                                   marketLevelCode, exchangeCode, secuCode, ' ', 
                                   secuTradeTypeCode, secuBizTypeCode, 'S1', '1',
                                   '1', hedgeFlagCode, '1', ABS(matchQty),
                                   CASE WHEN matchQty = 0 THEN 0
                                        ELSE investCostAmt / matchQty END, 0, 0, 0,
                                   investCostAmt, 0
                              FROM sims2016TradeHist..prodCellInOutESHist a
                             WHERE secuBizTypeCode = '8101'
                                   AND settleDate >= @v_realBeginDate
                                   AND settleDate <= @v_today
                                   AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                   AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                   AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                             ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, secuBizTypeCode      
             
  INSERT INTO #tt_portfolioRawJrnl(serialNO, orderID, occurDate, fundAcctCode, secuAcctCode, prodCode,
                                   prodCellCode, investPortfolioCode, transactionNO, currencyCode,
                                   marketLevelCode, exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode, matchQty,
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt,
                                   costChgAmt, rlzChgProfit)
                            SELECT serialNO, 0, settleDate, fundAcctCode, secuAcctCode, prodCode,
                                   prodCellCode, investPortfolioCode, transactionNO, currencyCode,
                                   marketLevelCode, exchangeCode, secuCode, ' ',
                                   secuTradeTypeCode, secuBizTypeCode, 'S1', 'A',
                                   '1', hedgeFlagCode, '1', ABS(matchQty),
                                   CASE WHEN matchQty = 0 THEN 0
                                        ELSE investCostAmt / matchQty END, 0, 0, 0,
                                   investCostAmt, 0
                              FROM sims2016TradeHist..prodCellInOutESHist a
                             WHERE secuBizTypeCode = '8103'
                                   AND settleDate >= @v_realBeginDate
                                   AND settleDate <= @v_today
                                   AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                                   AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                   AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                             ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, secuBizTypeCode
                             
  insert into #tt_sgwtb(settleDate,occurTime,exchangeCode,secuCode,fundAcctCode,prodCellCode,investPortfolioCode,macthQty) 
				         SELECT tradeDate,tradeTime,exchangeCode,secuCode,fundAcctCode,prodCellCode,investPortfolioCode,orderQty
                   FROM sims2016TradeHist..prodCellOrderESHist a 
                  where secuBizTypeCode = 'SG' 
                   AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                   AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                   AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
               order by fundAcctCode,tradeDate, exchangeCode, secuCode, prodCellCode, investPortfolioCode    
               
               --select * from   #tt_sgwtb                                                                                 
  --逐条处理
  DECLARE @o_fundAcctCode VARCHAR(20)
  SELECT @o_fundAcctCode = NULL
  --游标变量begin
  DECLARE
    @v_serialNO                 NUMERIC(20,0),                   --记录序号
    @v_orderID                  NUMERIC(5, 0),                   --排序Id
    @v_settleDate               VARCHAR(10),                     --发生日期
    @v_shareRecordDate          VARCHAR(10),                     --登记日期
    @v_fundAcctCode             VARCHAR(20),                     --资金账户
    @v_exchangeCode             VARCHAR(6),                      --交易所代码
    @v_secuCode                 VARCHAR(6),                      --证券代码
    @v_originSecuCode           VARCHAR(15),                     --原始证券代码
    @v_secuName                 VARCHAR(64),                     --证券名称
    @v_secuTradeTypeCode        VARCHAR(5),                      --证券类别
    @v_prodCellCode             VARCHAR(20),                     --产品单元代码
    @v_prodCode                 VARCHAR(20),                     --产品代码
    @v_investPortfolioCode      VARCHAR(20),                     --投资组合代码
    @v_buySellFlagCode          VARCHAR(1),                      --买卖类别
    @v_openCloseFlagCode        VARCHAR(16),                     --开平标志
    @v_marketLevelCode          VARCHAR(1),                      --市场来源
    @v_currencyCode             VARCHAR(6),                      --货币代码
    @v_hedgeFlagCode            VARCHAR(16),                     --投保标志
    @v_secuBizTypeCode          VARCHAR(16),                     --业务类型
    @v_matchQty                 NUMERIC(10,0),                   --成交数量
    @v_matchNetPrice            NUMERIC(10,2),                   --成交价格
    @v_cashCurrentSettleAmt     NUMERIC(19,2),                   --资金发生数
    @v_matchTradeFeeAmt         NUMERIC(19,2),                   --手续费
    @v_matchSettleAmt           NUMERIC(19,2),                   --成交结算金额
    @v_costChgAmt               NUMERIC(19,2),                   --移动平均成本变动
    @v_rlzChgProfit             NUMERIC(19,2),                    --实现盈亏变动
    @v_secuAcctCode             VARCHAR(20)--证券账户代码

  --游标变量end
  DECLARE for_mccjb CURSOR FOR SELECT serialNO, orderID, occurDate, shareRecordDate,
                                      fundAcctCode, secuAcctCode, prodCode, investPortfolioCode,
                                      exchangeCode, secuCode,originSecuCode,
                                      '', secuTradeTypeCode,prodCellCode, 
                                      buySellFlagCode, openCloseFlagCode,secuBizTypeCode,
                                      marketLevelCode, currencyCode, hedgeFlagCode,
                                      matchQty, matchNetPrice, cashSettleAmt, 
                                      matchTradeFeeAmt, matchSettleAmt,costChgAmt,
                                      rlzChgProfit
                                 FROM #tt_portfolioRawJrnl 
                             ORDER BY fundAcctCode, exchangeCode, secuCode, occurDate, orderID, buySellFlagCode DESC, serialNO 
  OPEN for_mccjb
  FETCH for_mccjb INTO @v_serialNO, @v_orderID, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_secuAcctCode,@v_prodCode, @v_investPortfolioCode, 
                       @v_exchangeCode, @v_secuCode, @v_originSecuCode,@v_secuName, @v_secuTradeTypeCode, 
                       @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_currencyCode, @v_hedgeFlagCode, 
                       @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                       @v_costChgAmt, @v_rlzChgProfit
                                                                                       
  WHILE 1 = 1
    BEGIN    
      IF @o_fundAcctCode IS NOT NULL AND (@o_fundAcctCode != @v_fundAcctCode OR @@FETCH_STATUS != 0)  
        BEGIN   
          INSERT INTO sims2016TradeHist..portfolioCheckJrnlESHist(createPosiDate, settleDate, prodCode, prodCellCode,
                                                                  fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode,
                                                                  originSecuCode, secuTradeTypeCode, marketLevelCode, transactionNO,
                                                                  investPortfolioCode, buySellFlagCode, bizSubTypeCode,
                                                                  openCloseFlagCode, longShortFlagCode, hedgeFlagCode,
                                                                  secuBizTypeCode, matchQty, matchNetPrice, matchSettleAmt,
                                                                  matchTradeFeeAmt, cashSettleAmt, costChgAmt,
                                                                  occupyCostChgAmt, rlzChgProfit, investCostChgAmt,
                                                                  investOccupyCostChgAmt, investRlzChgProfit)
                                                           SELECT createPosiDate, occurDate, prodCode, prodCellCode,
                                                                  fundAcctCode, secuAcctCode, currencyCode, exchangeCode, secuCode,
                                                                  originSecuCode, secuTradeTypeCode, marketLevelCode, 1,
                                                                  investPortfolioCode, buySellFlagCode, 'S1',
                                                                  openCloseFlagCode, '1', hedgeFlagCode,
                                                                  secuBizTypeCode, matchQty, matchNetPrice, matchSettleAmt,
                                                                  matchTradeFeeAmt, cashSettleAmt, costChgAmt,
                                                                  occupyCostChgAmt, rlzChgProfit, costChgAmt,
                                                                  occupyCostChgAmt, rlzChgProfit
                                                             FROM #tt_portfolioCheckJrnlES;

          INSERT INTO sims2016TradeHist..prodCellRawJrnlHist(settleDate,
                                                             prodCode, prodCellCode, fundAcctCode, secuAcctCode, currencyCode,
                                                             exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                                             marketLevelCode, buySellFlagCode, bizSubTypeCode,
                                                             openCloseFlagCode, hedgeFlagCode, secuBizTypeCode,
                                                             matchQty, matchNetPrice , cashSettleAmt, dataSourceFlagCode)
                                                             --, costChgAmt, occupyCostChgAmt, rlzChgProfit, investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit
                                                             --注掉的部分字段采用default方式生成)
                                                      SELECT occurDate,
                                                             prodCode, prodCellCode, fundAcctCode, ' ', currencyCode,
                                                             exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,
                                                             '2', buySellFlagCode, ' ',
                                                             openCloseFlagCode, hedgeFlagCode, secuBizTypeCode,
                                                             matchQty, matchNetPrice, cashSettleAmt, '0'
                                                        FROM #tt_portfolioCheckJrnlES
                                                       WHERE secuBizTypeCode  IN ('183', '187', '188'); --送红股派息证券业务类型
          TRUNCATE TABLE  #tt_portfolioCheckJrnlES
        END
    
    IF @@FETCH_STATUS != 0
      break
        
    IF @o_fundAcctCode IS NULL OR (@v_fundAcctCode != @o_fundAcctCode) 
      BEGIN
        SELECT @o_fundAcctCode = @v_fundAcctCode
        TRUNCATE TABLE #tt_portfolioCreatePosiDate
        TRUNCATE TABLE #tt_portfolioCreatePosiDateSum
        --取快照表(TODO)
        --取历史核算流水表
       
        INSERT INTO #tt_portfolioCreatePosiDate(exchangeCode, secuCode, prodCellCode, investPortfolioCode,
                                                createPosiDate, posiQty, costChgAmt, lastCreatePosiDate)
                                         SELECT exchangeCode, secuCode, prodCellCode, investPortfolioCode,
                                                MAX(createPosiDate), SUM(matchQty), SUM(costChgAmt), MAX(settleDate)
                                           FROM sims2016TradeHist..prodCellCheckJrnlESHist
                                          WHERE settleDate < @v_realBeginDate -- AND settleDate > 快照日期 (待后续快照表设计好后加上此条件)
                                            AND fundAcctCode = @v_fundAcctCode
                                            AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                            AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
                                          GROUP BY exchangeCode, secuCode, prodCellCode, investPortfolioCode
                                          HAVING SUM(matchQty) > 0
    

        INSERT INTO #tt_portfolioCreatePosiDateSum(exchangeCode, secuCode, prodCellCode, investPortfolioCode,
                                                   createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                            SELECT exchangeCode, secuCode, prodCellCode, investPortfolioCode,
                                                   MAX(createPosiDate), SUM(posiQty), SUM(costChgAmt), MAX(lastCreatePosiDate)
                                              FROM #tt_portfolioCreatePosiDate
                                             GROUP BY exchangeCode, secuCode, prodCellCode, createPosiDate, investPortfolioCode
                                            HAVING SUM(posiQty) > 0
                                                                                                       
                   --配股缴款过程中的持仓(含：配股权证到账，配股缴款权证减少，配股缴款证券增加，配股上市转出，配股摘牌)
        INSERT #tt_portfolioCreatePosiDateAllotment(exchangeCode, secuCode, secuCode0, secuBizTypeCode, prodCellCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate
          )
                                             SELECT exchangeCode, secuCode, prodCellCode, MAX(createPosiDate) AS  createPosiDate, 
                                                    SUM(matchQty) AS  posiQty, SUM(costChgAmt) AS  ydpjcb, MAX(createPosiDate) AS  lastestoperateDate, secuCode, secuBizTypeCode
                                               FROM sims2016TradeHist..portfolioCheckJrnlESHist a
                                              WHERE settleDate < @i_beginDate
                                                    AND fundAcctCode = @v_fundAcctCode
                                                    AND (@i_exchangeCode = '' OR CHARINDEX(a.exchangeCode, @i_exchangeCode) > 0) AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
                                                    AND secuBizTypeCode = 'JK'
                                              GROUP BY exchangeCode, secuCode, prodCellCode, secuCode, secuBizTypeCode
                                                                                                      
        TRUNCATE TABLE #tt_portfolioCheckJrnl_old
        --取快照表(TODO)
       
        INSERT INTO #tt_portfolioCheckJrnl_old(operateDate, exchangeCode, secuCode, prodCellCode,investPortfolioCode, posiQty)
                                        SELECT settleDate, exchangeCode, secuCode, prodCellCode, investPortfolioCode, SUM(matchQty)
                                          FROM sims2016TradeHist..prodCellCheckJrnlESHist
                                         WHERE settleDate < @v_realBeginDate -- AND settleDate > 快照日期 (待后续快照表设计好后加上此条件)
                                               AND fundAcctCode = @v_fundAcctCode
                                               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                               AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 )
                                         GROUP BY settleDate, exchangeCode, secuCode, prodCellCode, investPortfolioCode
                                        HAVING SUM(matchQty) != 0;  
        --SELECT * FROM #tt_portfolioCheckJrnl_old
      END
   
    IF @v_exchangeCode = '' AND @v_secuCode = '' 
      BEGIN
        TRUNCATE TABLE tt_portfolioCreatePosiDateSum
      END
    ELSE IF @v_secuBizTypeCode  IN ('122')      --配股业务 
      BEGIN
        TRUNCATE TABLE #tt_portfolioPosiQtyDetial
        TRUNCATE TABLE #tt_portfolioPosiQtySum
        
        INSERT #tt_portfolioPosiQtyDetial (createPosiDate,prodCellCode,investPortfolioCode ,
                                           posiQty,matchQty,costChgAmt)
                                    SELECT @v_settleDate, prodCellCode, investPortfolioCode, SUM(posiQty), 0, 0
                                      FROM #tt_portfolioCheckJrnl_old
                                     WHERE operateDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode 
                                     GROUP BY prodCellCode, investPortfolioCode                                 
                                    HAVING SUM(posiQty) > 0

        INSERT #tt_portfolioPosiQtyDetial (createPosiDate, prodCellCode,investPortfolioCode , posiQty, matchQty, costChgAmt)
                                   SELECT @v_settleDate, prodCellCode,investPortfolioCode, SUM(matchQty), 0, 0
                                     FROM #tt_portfolioCheckJrnlES
                                    WHERE occurDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode 
                                 GROUP BY prodCellCode, investPortfolioCode                                 
                               HAVING SUM(matchQty) != 0
                                                              
        INSERT INTO #tt_portfolioPosiQtySum(createPosiDate, prodCellCode, investPortfolioCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                                    SELECT @v_settleDate, prodCellCode, investPortfolioCode, SUM(posiQty), 0, 0, 0
                                      FROM #tt_portfolioPosiQtyDetial
                                     GROUP BY prodCellCode, investPortfolioCode
                                    HAVING SUM(posiQty) > 0 
                                                                                                                                                    
        IF EXISTS (SELECT * FROM #tt_portfolioPosiQtySum)
          BEGIN   
            SELECT @v_posiQty = SUM(posiQty) FROM #tt_portfolioPosiQtySum
            SELECT @v_matchQty, @v_posiQty    

            UPDATE #tt_portfolioPosiQtySum SET matchQty = FLOOR(ROUND(posiQty * @v_matchQty  / CONVERT(FLOAT, @v_posiQty), 4) )
            
            SELECT @v_matchQty = @v_matchQty - SUM(matchQty) FROM #tt_portfolioPosiQtySum
            
            IF @v_matchQty != 0  OR @v_costChgAmt != 0 OR @v_rlzChgProfit != 0 -- 尾数
              BEGIN
                SET rowcount 1
                SELECT @v_tempCellCode = prodCellCode FROM #tt_portfolioPosiQtySum ORDER BY posiQty DESC
                UPDATE #tt_portfolioPosiQtySum SET matchQty = matchQty + @v_matchQty WHERE prodCellCode = @v_tempCellCode
                SET rowcount 0
              END

            IF NOT EXISTS (SELECT * FROM #tt_portfolioCreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode)
              INSERT #tt_portfolioCreatePosiDateSum (exchangeCode, secuCode, prodCellCode, investPortfolioCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                     SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_investPortfolioCode,@v_settleDate, @v_matchQty, 0, @v_settleDate
            ELSE
              BEGIN
                UPDATE #tt_portfolioCreatePosiDateSum SET posiQty = posiQty + @v_matchQty
                       WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode
              END
          END
        ELSE-- 未找到正股持仓
          BEGIN
            IF NOT EXISTS (SELECT * FROM #tt_portfolioCreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode)
              INSERT #tt_portfolioCreatePosiDateSum (exchangeCode, secuCode, prodCellCode,investPortfolioCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                     SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_investPortfolioCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
            ELSE
              BEGIN
                UPDATE #tt_portfolioCreatePosiDateSum SET posiQty = posiQty + @v_matchQty
                       WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode
              END
  
            INSERT #tt_portfolioPosiQtySum (createPosiDate, prodCellCode, investPortfolioCode , posiQty, matchQty, costChgAmt, rlzChgProfit)
                   SELECT @v_settleDate, @v_fundAcctCode,@v_investPortfolioCode, 0, @v_matchQty, 0, 0
          END

        INSERT INTO #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                             secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                             secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                             buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                             currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                             matchNetPrice, cashSettleAmt, matchSettleAmt,
                                             matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                      SELECT @v_serialNO, @v_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                             @v_secuAcctCode, @v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ',
                                             @v_secuTradeTypeCode, prodCellCode, @v_prodCode, investPortfolioCode,
                                             @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode,
                                             @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, matchQty,
                                             @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt,
                                             @v_matchSettleAmt, @v_costChgAmt, @v_costChgAmt, @v_rlzChgProfit
                                        FROM #tt_portfolioPosiQtySum

        -- 更新或者增加持仓
        UPDATE a SET posiQty = a.posiQty + b.matchQty
                 FROM #tt_portfolioCreatePosiDateAllotment a 
                 INNER JOIN #tt_portfolioPosiQtySum b ON a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode AND a.secuCode0 = @v_secuCode AND a.prodCellCode = b.prodCellCode          

        insert #tt_portfolioCreatePosiDateAllotment (exchangeCode, secuCode, secuCode0, secuBizTypeCode, prodCellCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                             SELECT exchangeCode, secuCode, secuCode0, secuBizTypeCode, prodCellCode, createPosiDate, matchQty, costChgAmt, lastestoperateDate
                                     FROM (SELECT @v_exchangeCode AS  exchangeCode, @v_secuCode AS  secuCode, @v_secuCode AS  secuCode0, 'JK' AS  secuBizTypeCode, a.prodCellCode, @v_settleDate AS  createPosiDate, a.matchQty, 0 AS  costChgAmt, @v_settleDate AS  lastestoperateDate, b.createPosiDate AS  createPosiDate_y
                                                  FROM #tt_portfolioPosiQtySum a 
                                                  LEFT JOIN #tt_portfolioCreatePosiDateAllotment b ON a.prodCellCode = b.prodCellCode AND b.exchangeCode = @v_exchangeCode AND b.secuCode = @v_secuCode AND b.secuCode0 = @v_secuCode
                                          )x
                                          WHERE x.createPosiDate_y IS NULL
                                  
      END        
    ELSE IF @v_secuBizTypeCode  IN ('123')
      BEGIN
        -- 配股权证持仓减少
        SELECT @v_createPosiDate = NULL
        SELECT @v_createPosiDate = createPosiDate FROM #tt_portfolioCreatePosiDateAllotment WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode  AND prodCellCode = @v_prodCellCode          

        IF @v_createPosiDate IS NOT NULL
          BEGIN              
            UPDATE #tt_portfolioCreatePosiDateAllotment SET posiQty = posiQty - @v_matchQty
                   WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode

            INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                           secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                           secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                           buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                           currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                           matchNetPrice, cashSettleAmt, matchSettleAmt,
                                           matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                    SELECT @v_serialNO, @v_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                           @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                            '1231', 
                                           @v_prodCellCode, @v_prodCode, @v_investPortfolioCode,
                                           @v_buySellFlagCode, @v_openCloseFlagCode, 'JK', 
                                           @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, -1 *@v_matchQty,
                                           0 ,ROUND(0, 2), ROUND(0, 2),
                                           0, 0, 0, 0
          END

        --配股（正股未上市）持仓增加
        SELECT @v_createPosiDate = NULL
        SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastSettleDate = lastestoperateDate FROM #tt_portfolioCreatePosiDateAllotment
               WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode
        IF @v_createPosiDate IS NULL
          BEGIN
            INSERT #tt_portfolioCreatePosiDateAllotment (exchangeCode, secuCode, secuCode0, secuBizTypeCode, prodCellCode, investPortfolioCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                SELECT @v_exchangeCode, @v_secuCode, @v_secuCode, 'JK', @v_prodCellCode,@v_investPortfolioCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate
            SELECT @v_createPosiDate = @v_settleDate
          END
        ELSE
          BEGIN
            UPDATE #tt_portfolioCreatePosiDateAllotment SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + @v_costChgAmt, lastestoperateDate = @v_settleDate
                   WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode
          END

        INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                        secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                        secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                        buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                        currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                        matchNetPrice, cashSettleAmt, matchSettleAmt,
                                        matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                 SELECT @v_serialNO, @v_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                        @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                        '1232', 
                                        @v_prodCellCode, @v_prodCode, @v_investPortfolioCode,
                                        @v_buySellFlagCode, @v_openCloseFlagCode, 'JK', 
                                        @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_matchQty,
                                        @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchSettleAmt,
                                        @v_matchTradeFeeAmt, @v_costChgAmt, 0, @v_rlzChgProfit
      END 
    ELSE IF(@v_secuBizTypeCode = '124')      -- 配股上市。
      BEGIN
          --找到配股缴款的持仓 以及信托单元，然后按缴款持仓进行拆分。            
        WHILE @v_matchQty > 0
          BEGIN
            SELECT @temp_mr_prodCellCode = NULL
            SELECT top 1 
                   @temp_mr_prodCellCode = prodCellCode,
                   @temp_mr_investPortfolioCode = investPortfolioCode ,
                   @temp_mr_secuCode = secuCode,
                   @temp_mr_matchQty = ABS(posiQty),                                
                   @temp_mr_costChgAmt = costChgAmt,
                   @temp_mr_per_costChgAmt = costChgAmt / ABS(posiQty), 
                   @temp_mr_createPosiDate = createPosiDate 
              FROM #tt_portfolioCreatePosiDateAllotment
              WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND secuCode0 = @v_secuCode AND abs(posiQty) > 0
              ORDER BY createPosiDate, prodCellCode, investPortfolioCode

            IF @temp_mr_prodCellCode IS NOT NULL
              begin
                IF @v_matchQty < @temp_mr_matchQty
                  SELECT @temp_mc_matchQty = @v_matchQty
                ELSE
                  SELECT @temp_mc_matchQty = @temp_mr_matchQty

                SELECT @v_matchQty = @v_matchQty - @temp_mc_matchQty

                IF @temp_mc_matchQty < @temp_mr_matchQty
                  BEGIN
                    SELECT @temp_mc_costChgAmt = ROUND(@temp_mc_matchQty * @temp_mr_per_costChgAmt, 2)                                    
                  END
                ELSE
                  BEGIN
                    SELECT @temp_mc_costChgAmt = @temp_mr_costChgAmt             
                  END

                IF @temp_mc_matchQty != @temp_mr_matchQty
                  SELECT @temp_mr_costChgAmt = ROUND(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)

                SELECT @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt

                SELECT @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt

                SELECT @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt

                UPDATE #tt_portfolioCreatePosiDateAllotment SET posiQty = posiQty - @temp_mc_matchQty, 
                                              costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestoperateDate = @v_settleDate
                                              WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode
                                                                                          

                --配股上市转出记录
                INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                                secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                                buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                                currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                                matchNetPrice, cashSettleAmt, matchSettleAmt,
                                                matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                         SELECT @v_serialNO, @temp_mr_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                                @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                                '1241', 
                                                @temp_mr_prodCellCode, @v_prodCode, @v_investPortfolioCode,
                                                'S', @v_openCloseFlagCode, 'JK', 
                                                @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @temp_mc_matchQty * -1,
                                                 0, ISNULL(@v_cashCurrentSettleAmt, 0), @v_matchSettleAmt,
                                                 @v_matchTradeFeeAmt, @temp_mr_costChgAmt, 0, 0
                
                --配股上市转入
                SELECT @v_createPosiDate = NULL
                SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastSettleDate = lastestoperateDate FROM #tt_portfolioCreatePosiDateSum
                       WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode 

                IF @v_createPosiDate IS NULL
                  BEGIN
                    INSERT #tt_portfolioCreatePosiDateSum (exchangeCode, secuCode, prodCellCode, investPortfolioCode,
                                                           createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                                    SELECT @v_exchangeCode, @v_secuCode, @v_prodCellCode,@v_investPortfolioCode, @v_settleDate, @temp_mc_matchQty, @temp_mr_costChgAmt, @v_settleDate
                    SELECT @v_createPosiDate = @v_settleDate
                  END                 
                    ELSE
                      BEGIN
                        UPDATE #tt_portfolioCreatePosiDateSum SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @temp_mc_matchQty, costChgAmt = costChgAmt + @temp_mr_costChgAmt, lastestoperateDate = @v_settleDate
                               WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode 
                      END

                        INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                        secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                                        secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                                        buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                                        currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                                        matchNetPrice, cashSettleAmt, matchSettleAmt,
                                                        matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                                 SELECT @v_serialNO, @temp_mr_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                                        @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                                        '1242', 
                                                        @temp_mr_prodCellCode, @v_prodCode, @v_investPortfolioCode,
                                                        'B', @v_openCloseFlagCode, 'PT', 
                                                        @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @temp_mc_matchQty,
                                                        0, ISNULL(@v_cashCurrentSettleAmt, 0), @v_matchSettleAmt,
                                                        @v_matchTradeFeeAmt, @temp_mr_costChgAmt, 0, 0                  
                END
              ELSE -- 找不到对应的配股记录
                BEGIN
                  SELECT @v_createPosiDate = NULL
                  SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastSettleDate = lastestoperateDate FROM #tt_portfolioCreatePosiDateSum
                         WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode

                  IF @v_createPosiDate IS NULL
                    BEGIN
                      INSERT #tt_portfolioCreatePosiDateSum (exchangeCode, secuCode, prodCellCode, investPortfolioCode,
                                                             createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                                      SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode AS  prodCellCode, '', @v_settleDate, @v_matchQty, 0, @v_settleDate
                      SELECT @v_createPosiDate = @v_settleDate
                    END                 
                  ELSE
                    BEGIN
                      UPDATE #tt_portfolioCreatePosiDateSum SET createPosiDate = @v_createPosiDate, 
                                                                posiQty = posiQty + @v_matchQty, 
                                                                costChgAmt = costChgAmt + 0, 
                                                                lastestoperateDate = @v_settleDate
                                                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode 
                    END
                                           
                    INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                    secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                                    secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                                    buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                                    currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                                    matchNetPrice, cashSettleAmt, matchSettleAmt,
                                                    matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                             SELECT @v_serialNO, @temp_mr_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                                    @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                                    '1242', 
                                                    @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode,
                                                    'B', @v_openCloseFlagCode, 'PT', 
                                                    @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_matchQty,
                                                    0, 0, 0,
                                                    0, 0, 0, 0

                    BREAK
                END
            END
          SET rowcount 0
        END
        
    ELSE IF @v_secuBizTypeCode in ('103','106')
      BEGIN
        TRUNCATE TABLE #tt_portfolioPosiQtyDetial
    --  TRUNCATE TABLE #tt_portfolioPosiQtySum

        INSERT #tt_portfolioPosiQtyDetial (createPosiDate, prodCellCode,investPortfolioCode , posiQty, matchQty, costChgAmt)
                                    SELECT @v_settleDate, prodCellCode, investPortfolioCode, sum(macthQty), 0, 0
                                      FROM #tt_sgwtb
                                     WHERE exchangeCode = @v_exchangeCode AND fundAcctCode = @v_fundAcctCode
                                  GROUP BY settleDate, prodCellCode, investPortfolioCode 
                                  
        --select * from  #tt_portfolioPosiQtyDetial                    

        IF EXISTS (SELECT * FROM #tt_portfolioPosiQtyDetial)
          BEGIN
            SELECT @sgwtzsl = sum(posiQty) FROM #tt_portfolioPosiQtyDetial
            SELECT @mr_lastestUnit = CASE WHEN @v_exchangeCode = '0' THEN 500
                                          WHEN @v_exchangeCode = '1' THEN 1000 END

            SELECT @mr_lastestUnit = isnull(@mr_lastestUnit, 1)
            SELECT @sgwtzsl, '申购委托数量'
            UPDATE #tt_portfolioPosiQtyDetial SET matchQty = FLOOR(ROUND((posiQty  * @v_matchQty / CONVERT(money, @sgwtzsl)), 4) / @mr_lastestUnit) * @mr_lastestUnit,
                                      costChgAmt = FLOOR(ROUND((posiQty  * @v_matchQty / CONVERT(money, @sgwtzsl)), 4) / @mr_lastestUnit) * @mr_lastestUnit * ROUND(@v_matchNetPrice, 2)

            --select * from #tt_portfolioPosiQtyDetial 

            SELECT @v_matchQty = @v_matchQty - SUM(matchQty), @v_costChgAmt = @v_costChgAmt - SUM(costChgAmt) FROM #tt_portfolioPosiQtyDetial

            IF @v_matchQty != 0 OR @v_costChgAmt != 0 OR @v_rlzChgProfit != 0 -- 尾数
              BEGIN 
                WHILE(@v_matchQty >= @mr_lastestUnit)
                  BEGIN
                    DECLARE @tempprodCellCode VARCHAR(20)
                    SELECT top 1 @tempprodCellCode = prodCellCode FROM  #tt_sgwtb 
                                 WHERE exchangeCode = @v_exchangeCode  AND  fundAcctCode = @v_fundAcctCode
                                 ORDER BY macthQty DESC, occurTime ASC
                    UPDATE #tt_portfolioPosiQtyDetial SET matchQty = matchQty + @mr_lastestUnit, costChgAmt = matchQty + @mr_lastestUnit * @v_matchNetPrice 
                           WHERE prodCellCode = @tempprodCellCode
                    
                    --delete #tt_sgwtb where prodCellCode = @tempprodCellCode
                      
                    SELECT @v_matchQty = @v_matchQty - @mr_lastestUnit
                  
                  END   

                DELETE #tt_portfolioPosiQtyDetial WHERE matchQty = 0   --删除申购数量或者中签数量为0的流水
              END
          END
        -- 未找到对应委托
        ELSE
          BEGIN
            IF NOT EXISTS (SELECT * FROM #tt_portfolioCreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @v_fundAcctCode)
              INSERT #tt_portfolioCreatePosiDateSum(exchangeCode, secuCode, prodCellCode, investPortfolioCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                            SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, ' ', @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate
            ELSE
              BEGIN
                UPDATE #tt_portfolioCreatePosiDateSum SET posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + @v_costChgAmt
                       WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @v_fundAcctCode
              END

            INSERT #tt_portfolioPosiQtyDetial(createPosiDate, prodCellCode,investPortfolioCode , posiQty, matchQty, costChgAmt)
                           SELECT @v_settleDate, @v_fundAcctCode, '', 0, @v_matchQty, ROUND(@v_costChgAmt, 2)
          END
                         
                         
            INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                            secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                            secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                            buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                            currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                            matchNetPrice, cashSettleAmt, matchSettleAmt,
                                            matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                            SELECT distinct @v_serialNO, @v_settleDate, @v_settleDate, @v_fundAcctCode,
                                            @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                            @v_secuTradeTypeCode, prodCellCode, @v_prodCode, investPortfolioCode,
                                            @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, 
                                            @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, matchQty,
                                            @v_matchNetPrice, 0, 0,
                                            0, 0, 0, 0  
                                       FROM #tt_portfolioPosiQtyDetial                
                         
        -- 更新或者增加持仓
        UPDATE a SET posiQty = a.posiQty + b.matchQty
                     FROM #tt_portfolioCreatePosiDateSum a 
                     JOIN #tt_portfolioPosiQtyDetial b
                     ON a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode AND a.prodCellCode = b.prodCellCode

        INSERT #tt_portfolioCreatePosiDateSum(exchangeCode, secuCode, prodCellCode, investPortfolioCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                         SELECT exchangeCode, secuCode, prodCellCode, investPortfolioCode ,createPosiDate, posiQty, costChgAmt, lastestoperateDate
                                FROM (SELECT @v_exchangeCode AS exchangeCode, @v_secuCode AS secuCode, a.prodCellCode, a.investPortfolioCode AS investPortfolioCode, @v_settleDate as createPosiDate, a.matchQty as posiQty, a.costChgAmt as costChgAmt, @v_settleDate as lastestoperateDate, b.createPosiDate as createPosiDate_y
                                             FROM #tt_portfolioPosiQtyDetial a 
                                                  LEFT JOIN #tt_portfolioCreatePosiDateSum b ON a.prodCellCode = b.prodCellCode AND  b.exchangeCode = @v_exchangeCode AND  b.secuCode = @v_secuCode)x
                                WHERE x.createPosiDate_y IS NULL
                                                
      END 
      
    --新股申购(SGMC) 申购还款
    ELSE IF @v_secuBizTypeCode IN ('105')
      BEGIN    
        WHILE @v_matchQty > 0
          BEGIN
            SELECT @temp_mr_prodCellCode = NULL
            SELECT top 1 @temp_mr_prodCellCode = prodCellCode,
                         @temp_mr_investPortfolioCode = investPortfolioCode ,
                         @temp_mr_secuCode = secuCode, 
                         @temp_mr_matchQty = ABS(posiQty), 
                         @temp_mr_costChgAmt = costChgAmt,
                         @temp_mr_per_costChgAmt = costChgAmt / ABS(posiQty), 
                         @temp_mr_createPosiDate = createPosiDate
                    FROM #tt_portfolioCreatePosiDateSum
                    WHERE exchangeCode = @v_exchangeCode 
                          AND secuCode = @v_secuCode
                          AND ABS(posiQty) > 0
                    ORDER BY createPosiDate, prodCellCode

            IF @temp_mr_prodCellCode IS NOT NULL
              BEGIN
                IF @v_matchQty < @temp_mr_matchQty
                  SELECT @temp_mc_matchQty = @v_matchQty
                ELSE
                  SELECT @temp_mc_matchQty = @temp_mr_matchQty

                SELECT @v_matchQty = @v_matchQty - @temp_mc_matchQty

                IF @temp_mc_matchQty < @temp_mr_matchQty
                  BEGIN
                    SELECT @temp_mc_costChgAmt = ROUND(@temp_mc_matchQty * @temp_mr_per_costChgAmt, 2)
                  END
                ELSE
                  BEGIN
                    SELECT @temp_mc_costChgAmt = @temp_mr_costChgAmt
                  END

                IF @temp_mc_matchQty != @temp_mr_matchQty
                  SELECT @temp_mr_costChgAmt = ROUND(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)

                SELECT @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt

                SELECT @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt

                SELECT @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt

                UPDATE #tt_portfolioCreatePosiDateSum SET posiQty = posiQty - @temp_mc_matchQty,
                                            costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                            lastestoperateDate = @v_settleDate
                                      WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @temp_mr_prodCellCode
                                      
                INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                                secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                                buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                                currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                                matchNetPrice, cashSettleAmt, matchSettleAmt,
                                                matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                         SELECT @v_serialNO, @temp_mr_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                                @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                                @v_secuTradeTypeCode, 
                                                @temp_mr_prodCellCode, @v_prodCode, @v_investPortfolioCode,
                                                @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, 
                                                @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @temp_mc_matchQty * -1,
                                                0, ISNULL(@v_cashCurrentSettleAmt, 0), @v_matchSettleAmt,
                                                @v_matchTradeFeeAmt, -1 *@temp_mr_costChgAmt, 0, 0

                END
            ELSE -- 找不到对应的记录
              BEGIN
                 SELECT @v_createPosiDate = NULL
                 SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastSettleDate = lastestoperateDate FROM #tt_portfolioCreatePosiDateSum
                        WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @v_fundAcctCode

                 IF @v_createPosiDate IS NULL
                    BEGIN
                      INSERT #tt_portfolioCreatePosiDateSum (exchangeCode, secuCode, prodCellCode,investPortfolioCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                        SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode AS prodCellCode, ' ', @v_settleDate, @v_matchQty, 0, @v_settleDate

                      SELECT @v_createPosiDate = @v_settleDate
                    END
                  ELSE
                    BEGIN
                      UPDATE #tt_portfolioCreatePosiDateSum SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + 0, lastestoperateDate = @v_settleDate
                             WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @v_prodCellCode
                    END
                         
                  INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                  secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                                  secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                                  buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                                  currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                                  matchNetPrice, cashSettleAmt, matchSettleAmt,
                                                  matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                           SELECT @v_serialNO, @v_settleDate, @v_settleDate, @v_fundAcctCode,
                                                  @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                                  @v_secuTradeTypeCode, 
                                                  @v_fundAcctCode AS prodCellCode, @v_prodCode, @v_investPortfolioCode,
                                                  @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, 
                                                  @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_matchQty,
                                                  0, ISNULL(@v_cashCurrentSettleAmt, 0), @v_matchSettleAmt,
                                                  @v_matchTradeFeeAmt, @v_costChgAmt, 0, 0

                  break
              END
          END
      END      
      -- 新股上市。
    ELSE IF(@v_secuBizTypeCode = '107')
      BEGIN
        WHILE @v_matchQty > 0
          BEGIN                       
            SELECT @temp_mr_prodCellCode = NULL
            SELECT top 1 @temp_mr_prodCellCode = prodCellCode,
                         @temp_mr_investPortfolioCode = investPortfolioCode ,
                         @temp_mr_secuCode = secuCode,
                         @temp_mr_matchQty = ABS(posiQty),
                         @temp_mr_costChgAmt = costChgAmt,
                         @temp_mr_per_costChgAmt = costChgAmt / ABS(posiQty),
                         @temp_mr_createPosiDate = createPosiDate
                    FROM #tt_portfolioCreatePosiDateSum
                    WHERE exchangeCode = @v_exchangeCode 
                    --AND  dbo.fn_get_secuCode0(exchangeCode, secuCode) = @v_secuCode
                          AND ABS(posiQty) > 0
                    ORDER BY createPosiDate, prodCellCode
                                         
            IF @temp_mr_prodCellCode IS NOT NULL
              BEGIN
                IF @v_matchQty < @temp_mr_matchQty
                  SELECT @temp_mc_matchQty = @v_matchQty
                ELSE
                  SELECT @temp_mc_matchQty = @temp_mr_matchQty

                SELECT @v_matchQty = @v_matchQty - @temp_mc_matchQty

                IF @temp_mc_matchQty < @temp_mr_matchQty
                  BEGIN
                    SELECT @temp_mc_costChgAmt = ROUND(@temp_mc_matchQty * @temp_mr_per_costChgAmt, 2)
                  END
                ELSE
                  BEGIN
                    SELECT @temp_mc_costChgAmt = @temp_mr_costChgAmt
                  END

                IF @temp_mc_matchQty != @temp_mr_matchQty
                  SELECT @temp_mr_costChgAmt = ROUND(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)

                SELECT @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt

                SELECT @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt

                SELECT @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt


                UPDATE #tt_portfolioCreatePosiDateSum SET posiQty = posiQty - @temp_mc_matchQty, costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                            lastestoperateDate = @v_settleDate
                       where exchangeCode = @v_exchangeCode  AND  prodCellCode = @temp_mr_prodCellCode
                                                   
               INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                               secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                               secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                               buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                               currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                               matchNetPrice, cashSettleAmt, matchSettleAmt,
                                               matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                        SELECT @v_serialNO, @temp_mr_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                               @v_secuAcctCode ,@v_exchangeCode, @temp_mr_secuCode, @v_originSecuCode, ' ', 
                                               ' ', 
                                               @v_fundAcctCode AS prodCellCode, @v_prodCode, ' ',
                                               'S', @v_openCloseFlagCode, '1071', 
                                               @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @temp_mc_matchQty,
                                               0, ISNULL(@v_cashCurrentSettleAmt, 0), @v_matchSettleAmt,
                                               @v_matchTradeFeeAmt, -1 * @temp_mr_costChgAmt, 0, 0       
                       
                 --新股上市
                 SELECT @v_createPosiDate = NULL

                 SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastSettleDate = lastestoperateDate FROM #tt_portfolioCreatePosiDateSum
                        WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @v_prodCellCode

                 IF @v_createPosiDate IS NULL
                   BEGIN
                     INSERT #tt_portfolioCreatePosiDateSum (exchangeCode, secuCode, prodCellCode,investPortfolioCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                                    SELECT @v_exchangeCode, @v_secuCode, @temp_mr_prodCellCode,' ', @v_settleDate, @temp_mc_matchQty, @temp_mr_costChgAmt, @v_settleDate

                      SELECT @v_createPosiDate = @v_settleDate
                    END
                  ELSE
                    BEGIN
                      UPDATE #tt_portfolioCreatePosiDateSum SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @temp_mc_matchQty, costChgAmt = costChgAmt + @temp_mr_costChgAmt, lastestoperateDate = @v_settleDate
                             WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @temp_mr_prodCellCode
                    END
                    
                   INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                   secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                                   secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                                   buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                                   currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                                   matchNetPrice, cashSettleAmt, matchSettleAmt,
                                                   matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                            SELECT @v_serialNO, @temp_mr_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                                   @v_secuAcctCode ,@v_exchangeCode, @temp_mr_secuCode, @v_originSecuCode, ' ', 
                                                   '1072', 
                                                   @v_fundAcctCode AS prodCellCode, @v_prodCode, ' ',
                                                   'B', @v_openCloseFlagCode, @v_secuBizTypeCode, 
                                                   @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @temp_mc_matchQty,
                                                   0, ISNULL(@v_cashCurrentSettleAmt, 0), @v_matchSettleAmt,
                                                   @v_matchTradeFeeAmt, @temp_mr_costChgAmt, 0, 0    

                END
            ELSE -- 找不到对应的记录
              BEGIN
                SELECT @v_createPosiDate = NULL
                SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastSettleDate = lastestoperateDate FROM #tt_portfolioCreatePosiDateSum
                       WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @v_fundAcctCode
                 IF @v_createPosiDate IS NULL
                   BEGIN
                     INSERT #tt_portfolioCreatePosiDateSum (exchangeCode, secuCode, prodCellCode, createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                       SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode AS prodCellCode, @v_settleDate, @v_matchQty, 0, @v_settleDate

                     SELECT @v_createPosiDate = @v_settleDate
                    END
                  ELSE
                    BEGIN
                      UPDATE #tt_portfolioCreatePosiDateSum SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + 0, lastestoperateDate = @v_settleDate
                             WHERE exchangeCode = @v_exchangeCode AND  secuCode = @v_secuCode AND  prodCellCode = @v_prodCellCode
                    END
                   
                INSERT #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                                secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                                buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                                currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                                matchNetPrice, cashSettleAmt, matchSettleAmt,
                                                matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                                         SELECT @v_serialNO, @v_settleDate, @v_settleDate, @v_fundAcctCode,
                                                @v_secuAcctCode ,@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', 
                                                @v_secuTradeTypeCode, 
                                                @v_fundAcctCode as prodCellCode, @v_prodCode, @v_fundAcctCode as investPortfolioCode,
                                                @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, 
                                                @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_matchQty,
                                                0, 0, @v_matchSettleAmt,
                                                @v_matchTradeFeeAmt, @temp_mr_costChgAmt, 0, 0    
                
                break
              END
          END
        SET rowcount 0
      END 
        
    ELSE IF @v_secuBizTypeCode = '183' OR @v_secuBizTypeCode = '187' OR @v_secuBizTypeCode = '188'
      BEGIN      
        TRUNCATE TABLE #tt_portfolioPosiQtyDetial
        TRUNCATE TABLE #tt_portfolioPosiQtySum
     
        INSERT INTO #tt_portfolioPosiQtyDetial(createPosiDate, prodCellCode, investPortfolioCode, posiQty, matchQty, costChgAmt)
                                         SELECT @v_settleDate, prodCellCode, investPortfolioCode, SUM(posiQty), 0, 0
                                           FROM #tt_portfolioCheckJrnl_old
                                          WHERE operateDate <= @v_shareRecordDate
                                            AND exchangeCode = @v_exchangeCode
                                            AND secuCode = @v_secuCode
                                          GROUP BY prodCellCode, investPortfolioCode
                                         HAVING SUM(posiQty) > 0
        INSERT INTO #tt_portfolioPosiQtyDetial(createPosiDate, prodCellCode, investPortfolioCode, posiQty, matchQty, costChgAmt)
                                         SELECT @v_settleDate, prodCellCode, investPortfolioCode, SUM(matchQty), 0, 0
                                           FROM #tt_portfolioCheckJrnlES
                                          WHERE occurDate <= @v_shareRecordDate
                                            AND exchangeCode = @v_exchangeCode
                                            AND secuCode = @v_secuCode
                                          GROUP BY prodCellCode, investPortfolioCode
                                         HAVING SUM(matchQty) != 0
           
        INSERT INTO #tt_portfolioPosiQtySum(createPosiDate, prodCellCode, investPortfolioCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                                      SELECT @v_settleDate, prodCellCode, investPortfolioCode, SUM(posiQty), 0, 0, 0
                                        FROM #tt_portfolioPosiQtyDetial
                                       GROUP BY prodCellCode, investPortfolioCode
                                      HAVING SUM(posiQty) > 0  
                                                                     
                                                              
        IF EXISTS(SELECT 1 FROM #tt_portfolioPosiQtySum)
          BEGIN
            SELECT @v_posiQty = SUM(posiQty) FROM #tt_portfolioPosiQtySum

            UPDATE #tt_portfolioPosiQtySum SET matchQty = FLOOR(ROUND(posiQty / @v_posiQty * @v_matchQty, 4)),
                                              costChgAmt = ROUND(ROUND(posiQty / @v_posiQty * @v_costChgAmt, 4), 2),
                                              rlzChgProfit = ROUND(ROUND(posiQty / @v_posiQty * @v_rlzChgProfit, 4), 2)
                                              
                                              
            --SELECT * FROM #tt_portfolioPosiQtySum                                 
            
            SELECT @v_matchQty = @v_matchQty - SUM(matchQty), @v_costChgAmt = @v_costChgAmt - SUM(costChgAmt), @v_rlzChgProfit = @v_rlzChgProfit - SUM(rlzChgProfit) FROM #tt_portfolioPosiQtySum;
       
            
       
            IF @v_matchQty != 0 OR @v_costChgAmt != 0 OR @v_rlzChgProfit != 0
              BEGIN
                SELECT top 1   
                  @v_tempCellCode = prodCellCode
                  FROM #tt_portfolioPosiQtySum
                  ORDER BY matchQty DESC;
              
                UPDATE #tt_portfolioPosiQtySum SET matchQty = matchQty + @v_matchQty,
                                                   costChgAmt = costChgAmt + @v_costChgAmt,
                                                   rlzChgProfit = rlzChgProfit + @v_rlzChgProfit
                                             WHERE prodCellCode = @v_tempCellCode
              END
     
            MERGE INTO #tt_portfolioPosiQtySum a
            USING #tt_portfolioCreatePosiDateSum b ON (a.prodCellCode = b.prodCellCode AND b.exchangeCode = @v_exchangeCode AND b.secuCode = @v_secuCode)
            WHEN MATCHED THEN UPDATE SET a.createPosiDate = b.createPosiDate;
            
            MERGE INTO #tt_portfolioCreatePosiDateSum a
            USING #tt_portfolioPosiQtySum b ON (a.prodCellCode = b.prodCellCode AND a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode)
            WHEN MATCHED THEN UPDATE SET a.posiQty = a.posiQty + b.matchQty,
                                         a.costChgAmt = a.costChgAmt + b.costChgAmt,
                                         a.createPosiDate = CASE WHEN a.posiQty <= 0 THEN b.createPosiDate ELSE a.createPosiDate END;
                                                                                
        END
      ELSE
        BEGIN
          IF EXISTS(SELECT 1 FROM #tt_portfolioCreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCode)
             UPDATE #tt_portfolioCreatePosiDateSum SET posiQty = posiQty + @v_matchQty
                    WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCode
          ELSE
            INSERT INTO #tt_portfolioCreatePosiDateSum(exchangeCode, secuCode, prodCellCode, investPortfolioCode,
                                                       createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                                VALUES(@v_exchangeCode, @v_secuCode, @v_prodCode, @v_investPortfolioCode,
                                                       @v_settleDate, @v_matchQty, 0, @v_settleDate)
                                             
            INSERT INTO #tt_portfolioPosiQtySum(createPosiDate, prodCellCode, investPortfolioCode, posiQty,
                                                matchQty, costChgAmt, rlzChgProfit)
                                         VALUES(@v_settleDate, @v_prodCode, @v_investPortfolioCode, 0,
                                                @v_matchQty, 0, -@v_costChgAmt + @v_rlzChgProfit)
        END
                  
      INSERT INTO #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                           secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                           secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                           buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                           currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                           matchNetPrice, cashSettleAmt, matchSettleAmt,
                                           matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                    SELECT @v_serialNO, @v_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                           @v_secuAcctCode, @v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ',
                                           @v_secuTradeTypeCode, prodCellCode, @v_prodCode, @v_investPortfolioCode,
                                           @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode,
                                           @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, matchQty,
                                           @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchSettleAmt,
                                           @v_matchTradeFeeAmt, costChgAmt, - (costChgAmt - rlzChgProfit), rlzChgProfit
                                      FROM #tt_portfolioPosiQtySum
                                         
           --SELECT * FROM #tt_portfolioCheckJrnlES                            
      END           
    ----------------------------------------------------------买入处理-------------------------------------------------------         
    ELSE IF @v_buySellFlagCode = '1' AND @v_openCloseFlagCode = '1'
      BEGIN
        SELECT @v_createPosiDate = NULL
        SELECT @v_posiQty        = NULL
        SELECT @v_lastSettleDate = NULL
               
        SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastSettleDate =  lastCreatePosiDate
               FROM #tt_portfolioCreatePosiDate
              WHERE exchangeCode = @v_exchangeCode
                    AND secuCode = @v_secuCode
                    AND prodCellCode = @v_prodCellCode
                    AND investPortfolioCode = @v_investPortfolioCode
                                        
        IF @v_createPosiDate IS NULL
          BEGIN
            INSERT INTO #tt_portfolioCreatePosiDateSum(exchangeCode, secuCode, prodCellCode, investPortfolioCode,
                                                   createPosiDate, posiQty, costChgAmt, lastestoperateDate)
                                            VALUES(@v_exchangeCode, @v_secuCode, @v_prodCellCode, @v_investPortfolioCode,
                                                   @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate)
            SELECT @v_createPosiDate = @v_settleDate
          END
        ELSE IF @v_posiQty <= 0 AND @v_lastSettleDate != @v_settleDate
          BEGIN
            UPDATE #tt_portfolioCreatePosiDateSum SET createPosiDate = @v_settleDate,
                                                     posiQty = @v_matchQty,
                                                     costChgAmt = @v_costChgAmt,
                                                     lastestoperateDate = @v_settleDate
                                               WHERE exchangeCode = @v_exchangeCode
                                                 AND secuCode = @v_secuCode
                                                 AND prodCellCode = @v_prodCellCode
          END
        ELSE
          BEGIN
            UPDATE #tt_portfolioCreatePosiDateSum SET createPosiDate = @v_createPosiDate,
                                                      posiQty = posiQty + @v_matchQty,
                                                      costChgAmt = costChgAmt + @v_costChgAmt
                                                WHERE exchangeCode = @v_exchangeCode
                                                  AND secuCode = @v_secuCode
                                                  AND prodCellCode = @v_prodCellCode
                                                  AND investPortfolioCode = @v_investPortfolioCode;
          END
           
        INSERT INTO #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                             secuAcctCode, exchangeCode, secuCode, originSecuCode, secuName,
                                             secuTradeTypeCode, prodCellCode, prodCode, investPortfolioCode,
                                             buySellFlagCode, openCloseFlagCode, secuBizTypeCode,
                                             currencyCode, marketLevelCode, hedgeFlagCode, matchQty,
                                             matchNetPrice, cashSettleAmt, matchSettleAmt,
                                             matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                      VALUES(@v_serialNO, @v_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                             @v_secuAcctCode, @v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ',
                                             @v_secuTradeTypeCode, @v_prodCellCode, @v_prodCode, @v_investPortfolioCode,
                                             @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode,
                                             @v_currencyCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_matchQty,
                                             @v_matchNetPrice, @v_cashCurrentSettleAmt,@v_matchSettleAmt, 
                                             @v_matchTradeFeeAmt, @v_costChgAmt, @v_costChgAmt, @v_rlzChgProfit)
                                             
      END        
    -------------------------------------------------------卖出处理---------------------------------------------------------              
    ELSE IF @v_buySellFlagCode = '1' AND @v_openCloseFlagCode = 'A'
      BEGIN
        SELECT @v_costChgAmt                  = round(@v_costChgAmt, 2)
        SELECT @temp_mc_per_costChgAmt        = @v_costChgAmt / @v_matchQty
        SELECT @temp_mc_per_rlzChgProfit      = @v_rlzChgProfit / @v_matchQty
        SELECT @temp_mc_per_cashCurrSettleAmt = @v_cashCurrentSettleAmt /@v_matchQty
        SELECT @temp_mc_per_matchTradeFeeAmt  = @v_matchTradeFeeAmt / @v_matchQty
                       
        WHILE @v_matchQty > 0
          BEGIN
            SELECT @temp_mr_prodCellCode = NULL
              SELECT top 1
                     @temp_mr_prodCellCode = prodCellCode, 
                     @temp_mr_matchQty = posiQty, 
                     @temp_mr_costChgAmt = costChgAmt , 
                     @temp_mr_per_costChgAmt = costChgAmt / posiQty, 
                     @temp_mr_createPosiDate = createPosiDate
                FROM #tt_portfolioCreatePosiDateSum
               WHERE exchangeCode = @v_exchangeCode
                 AND secuCode = @v_secuCode
                 AND prodCellCode = @v_prodCellCode
                 AND posiQty > 0
               ORDER BY createPosiDate
                                     
       --找到相应的买入处理
            IF @temp_mr_prodCellCode IS NOT NULL 
            BEGIN
              IF @temp_mr_matchQty > @v_matchQty
                 SELECT @temp_mc_matchQty = @v_matchQty
              ELSE
                SELECT @temp_mc_matchQty = @temp_mr_matchQty
            
              SELECT @v_matchQty = @v_matchQty - @temp_mc_matchQty
              IF @v_matchQty != 0 
                BEGIN
                  SELECT @temp_mc_costChgAmt        = round(@temp_mc_matchQty * @temp_mc_per_costChgAmt, 2)
                  SELECT @temp_mc_cashCurrSettleAmt = round(@temp_mc_matchQty * @temp_mc_per_cashCurrSettleAmt, 2)
                  SELECT @temp_mc_matchTradeFeeAmt  = round(@temp_mc_matchQty * @temp_mc_per_matchTradeFeeAmt, 2)
                END
              ELSE
                BEGIN
                  SELECT @temp_mc_costChgAmt        = @v_costChgAmt
                  SELECT @temp_mc_cashCurrSettleAmt = @v_cashCurrentSettleAmt
                  SELECT @temp_mc_matchTradeFeeAmt  = @v_matchTradeFeeAmt
                END           
              IF @temp_mc_matchQty != @temp_mr_matchQty 
                SELECT @temp_mr_costChgAmt = ROUND(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)
                
              SELECT @temp_mc_rlzChgProfit   = -@temp_mc_costChgAmt - @temp_mr_costChgAmt;
              SELECT @v_costChgAmt           = @v_costChgAmt - @temp_mc_per_costChgAmt;
              SELECT @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_per_cashCurrSettleAmt;
              SELECT @v_matchTradeFeeAmt     = @v_matchTradeFeeAmt - @temp_mc_per_matchTradeFeeAmt;
              UPDATE #tt_portfolioCreatePosiDateSum SET posiQty = posiQty - @temp_mc_matchQty,
                                                       costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                                       lastestoperateDate = @v_settleDate
                                                 WHERE exchangeCode = @v_exchangeCode
                                                   AND secuCode = @v_secuCode
                                                   AND prodCellCode = @temp_mr_prodCellCode;
              
                INSERT INTO #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                   secuAcctCode, exchangeCode, secuCode, originSecuCode,
                                                   secuName, secuTradeTypeCode, prodCellCode, prodCode,
                                                   investPortfolioCode, buySellFlagCode, openCloseFlagCode,
                                                   secuBizTypeCode, currencyCode, marketLevelCode,
                                                   hedgeFlagCode, matchQty, matchNetPrice,
                                                   cashSettleAmt, matchSettleAmt, matchTradeFeeAmt,
                                                   costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                            VALUES(@v_serialNO, @temp_mr_createPosiDate, @v_settleDate, @v_fundAcctCode,
                                                   @v_secuAcctCode, @v_exchangeCode, @v_secuCode, @v_originSecuCode,
                                                   ' ', @v_secuTradeTypeCode, @temp_mr_prodCellCode, @v_prodCode,
                                                   @v_investPortfolioCode, @v_buySellFlagCode, @v_openCloseFlagCode,
                                                   @v_secuBizTypeCode, @v_currencyCode, @v_marketLevelCode,
                                                   @v_hedgeFlagCode, -@temp_mc_matchQty, @v_matchNetPrice,
                                                   @temp_mc_cashCurrSettleAmt, @v_matchSettleAmt, @temp_mc_matchTradeFeeAmt,
                                                   -@temp_mr_costChgAmt, @temp_mc_cashCurrSettleAmt, @temp_mc_rlzChgProfit);
            
            END 
            ELSe
              BEGIN
              DELETE #tt_portfolioCreatePosiDateSum
               WHERE exchangeCode = @v_exchangeCode
                 AND secuCode = @v_secuCode
                 AND prodCellCode = @v_prodCellCode;
              
                INSERT INTO #tt_portfolioCheckJrnlES(serialNO, createPosiDate, occurDate, fundAcctCode,
                                                   secuAcctCode, exchangeCode, secuCode, originSecuCode,
                                                   secuName, secuTradeTypeCode, prodCellCode, prodCode,
                                                   investPortfolioCode, buySellFlagCode, openCloseFlagCode,
                                                   secuBizTypeCode, currencyCode, marketLevelCode,
                                                   hedgeFlagCode, matchQty, matchNetPrice,
                                                   cashSettleAmt, matchSettleAmt, matchTradeFeeAmt,
                                                   costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                            VALUES(@v_serialNO, @v_settleDate, @v_settleDate, @v_fundAcctCode,
                                                   @v_secuAcctCode, @v_exchangeCode, @v_secuCode, @v_originSecuCode,
                                                   ' ', @v_secuTradeTypeCode, @v_prodCellCode, @v_prodCode,
                                                   @v_investPortfolioCode, @v_buySellFlagCode, @v_openCloseFlagCode,
                                                   @v_secuBizTypeCode, @v_currencyCode, @v_marketLevelCode,
                                                   @v_hedgeFlagCode, -@v_matchQty, @v_matchNetPrice,
                                                   @v_cashCurrentSettleAmt, @v_matchSettleAmt, @v_matchTradeFeeAmt,
                                                   0, -@v_cashCurrentSettleAmt, -@v_costChgAmt)
               break
              END
           
          END 
      END
                     
    FETCH for_mccjb INTO @v_serialNO, @v_orderID, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_secuAcctCode,@v_prodCode, @v_investPortfolioCode, 
                         @v_exchangeCode, @v_secuCode, @v_originSecuCode,@v_secuName, @v_secuTradeTypeCode, 
                         @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_currencyCode, @v_hedgeFlagCode, 
                         @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                         @v_costChgAmt, @v_rlzChgProfit
 
    END
    
   CLOSE for_mccjb
   DEALLOCATE for_mccjb
 RETURN 0
go
--exec opCalcPortfolioCheckJrnlES '','','','','','', ''