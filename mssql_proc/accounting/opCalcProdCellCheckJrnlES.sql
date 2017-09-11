USE sims2016Proc
go
IF exists (SELECT 1 FROM sysobjects WHERE name = 'opCalcProdCellCheckJrnlES')
	DROP PROC opCalcProdCellCheckJrnlES
go

CREATE PROC opCalcProdCellCheckJrnlES
  @i_operatorCode        VARCHAR(255),               --操作员代码
  @i_operatorPassword    VARCHAR(255),               --操作员密码
  @i_operateStationText  VARCHAR(4096),              --留痕信息
  @i_fundAcctCode        VARCHAR(4096),                --资金账户
  @i_exchangeCode        VARCHAR(20),                --交易所代码
  @i_secuCode            VARCHAR(20),                --证券代码
  @i_beginDate           VARCHAR(10)                 --开始日期
AS
/***************************************************************************
-- Author : yugy
-- Version : 1.0
--    V1.0 ： 支持股票买卖成交、送股派息、转入转出业务
-- Date : 2017-04-01
-- Description : 产品单元股票买入卖出成本的核算、送股派息处理、转入传出处理,相应流水生成
-- Function List : opCalcProdCellCheckJrnlES
-- History : 

****************************************************************************/
 SET NOCOUNT ON
 
 CREATE TABLE #tt_prodCellRawJrnl(
    serialNO                  NUMERIC(20,0),                                   --记录序号
    orderID                   NUMERIC(5, 0)     DEFAULT 0      NOT NULL,          --排序Id
    occurDate                 VARCHAR(10)                      NOT NULL,          --发生日期
    shareRecordDate           VARCHAR(10)       DEFAULT ' '    NULL,              --登记日期
  ----------------------------------------------------------------------------------------------------------------------
    fundAcctCode              VARCHAR(20)                      NOT NULL,        --资金账户
    prodCode                  VARCHAR(20)                      NOT NULL,        --产品代码
    prodCellCode              VARCHAR(20)       DEFAULT ' '    NOT NULL,        --产品单元代码
    investPortfolioCode       VARCHAR(20)       DEFAULT ' '    NOT NULL,        --投资组合代码
    transactionNO             NUMERIC(20, 0)    DEFAULT 1      NOT NULL,        --交易编号
  ----------------------------------------------------------------------------------------------------------------------
    currencyCode              VARCHAR(6)                       NOT NULL,        --货币代码
    marketLevelCode           VARCHAR(1)       DEFAULT '1'     NOT NULL,        --市场来源
    exchangeCode              VARCHAR(6)       NOT NULL,                         --交易所代码
    secuCode                  VARCHAR(20)      NOT NULL,                         --证券代码
    originSecuCode            VARCHAR(15)      NOT NULL,                         --原始证券代码
    secuTradeTypeCode         VARCHAR(20)      NOT NULL,                         --证券类别
  ----------------------------------------------------------------------------------------------------------------------
    secuBizTypeCode           VARCHAR(16)                    NOT NULL,          --业务类型
    bizSubTypeCode            VARCHAR(16)     DEFAULT 'S1'   NOT NULL,          --业务子类
    openCloseFlagCode         VARCHAR(16)                    NOT NULL,          --开平标志
    longShortFlagCode         VARCHAR(16)     DEFAULT '1'    NOT NULL,          --多空标志
    hedgeFlagCode             VARCHAR(16)     DEFAULT ''     NOT NULL,          --投保标志
    buySellFlagCode           VARCHAR(1)      DEFAULT '1'    NOT NULL,          --买卖类别
------------------------------------------------------------------------------------------------------------------------
    matchQty                  NUMERIC(10,0)     DEFAULT 0      NOT NULL,        --成交数量
    matchNetPrice             NUMERIC(10,2)     DEFAULT 0      NOT NULL,        --成交价格
    matchSettleAmt            NUMERIC(19,2)     DEFAULT 0      NOT NULL,        --成交结算金额
    matchTradeFeeAmt          NUMERIC(19,2)     DEFAULT 0      NOT NULL,        --手续费
    cashSettleAmt      NUMERIC(19,2)     DEFAULT 0      NOT NULL,        --资金发生数
------------------------------------------------------------------------------------------------------------------------
    costChgAmt                NUMERIC(19,2)     DEFAULT 0      NOT NULL,        --移动平均成本变动
    rlzChgProfit              NUMERIC(19,2)     DEFAULT 0      NOT NULL         --实现盈亏变动
)
 
 CREATE TABLE #tt_prodCellCheckJrnlES
(
  serialNO                  NUMERIC(20, 0),                                  --记录序号
  createPosiDate            VARCHAR(10)                    NOT NULL,         --建仓日期
  occurDate                 VARCHAR(10)                    NOT NULL,         --发生日期
  shareRecordDate           VARCHAR(10)       DEFAULT ' '      NULL,         --登记日期
  fundAcctCode              VARCHAR(20)                    NOT NULL,         --资金账户
  exchangeCode              VARCHAR(20)                    NOT NULL,        --交易所代码
  secuCode                  VARCHAR(20)                    NOT NULL,        --证券代码
  originSecuCode            VARCHAR(15)                    NOT NULL,         --原始证券代码
  secuName                  VARCHAR(15)                    NOT NULL,         --证券名称
  secuTradeTypeCode         VARCHAR(20)                    NOT NULL,        --证券类别
  prodCellCode              VARCHAR(20)       DEFAULT ' '  NOT NULL,         --产品单元代码
  prodCode                  VARCHAR(20)       DEFAULT ' '  NOT NULL,         --产品代码
  investPortfolioCode       VARCHAR(20)       DEFAULT ' '  NOT NULL,         --投资组合代码
  buySellFlagCode           VARCHAR(1)                     NOT NULL,         --买卖类别
  openCloseFlagCode         VARCHAR(1)                     NOT NULL,         --开平标志
  secuBizTypeCode           VARCHAR(16)                    NOT NULL,         --业务类型
  currencyCode              VARCHAR(6)                     NOT NULL,         --货币代码
  marketLevelCode           VARCHAR(1)        DEFAULT '2'  NOT NULL,         --市场来源
  hedgeFlagCode             VARCHAR(16)       DEFAULT ''   NOT NULL,         --投保标志
  longShortFlagCode         VARCHAR(16)       DEFAULT '1'  NOT NULL,         --多空标志
  matchQty                  NUMERIC(10, 0)    DEFAULT 0    NOT NULL,         --成交数量
  matchNetPrice             NUMERIC(10, 4)    DEFAULT 0    NOT NULL,         --成交价格
  cashSettleAmt      NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --资金发生数
  matchSettleAmt            NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --成交结算金额
  matchTradeFeeAmt          NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --手续费
  costChgAmt                NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --移动平均成本变动
  occupyCostChgAmt          NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --持仓成本变动
  rlzChgProfit              NUMERIC(19,2)     DEFAULT 0    NOT NULL          --实现盈亏变动
)
 
 CREATE TABLE #tt_cellcreatePosiDate
(
  exchangeCode                  VARCHAR(4)               NOT NULL, --交易所代码
  secuCode                      VARCHAR(30)              NOT NULL, --证券代码
  prodCellCode                  VARCHAR(30)              NOT NULL, --单元代码
  currencyCode                  VARCHAR(6)                     NOT NULL,         --货币代码
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --市场来源
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --投保标志
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --多空标志
  createPosiDate                VARCHAR(10)              NOT NULL, --建仓日期
  posiQty                       NUMERIC(19,4)            NOT NULL, --持仓数量
  costChgAmt                    NUMERIC(19,4)            NOT NULL, --成本变动金额
  lastestOperateDate            VARCHAR(10)              NOT NULL  --最后操作日期
)

CREATE TABLE #tt_cellcreatePosiDateSum
(
  exchangeCode                  VARCHAR(4)               NOT NULL, --交易所代码
  secuCode                      VARCHAR(30)              NOT NULL, --证券代码
  prodCellCode                  VARCHAR(30)              NOT NULL, --单元代码
  currencyCode                  VARCHAR(6)                     NOT NULL,         --货币代码
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --市场来源
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --投保标志
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --多空标志
  createPosiDate                VARCHAR(10)              NOT NULL, --建仓日期
  posiQty                       NUMERIC(19,4)            NOT NULL, --持仓数量
  costChgAmt                    NUMERIC(19,4)                NULL, --成本变动金额
  lastestOperateDate            VARCHAR(10)              NOT NULL  --最后操作日期
)

/*
CREATE TABLE #tt_cellcreatePosiDateSum_rs
(
  exchangeCode                  VARCHAR(4)               NOT NULL, --交易所代码
  secuCode                      VARCHAR(30)              NOT NULL, --证券代码
  originSecuCode                VARCHAR(30)              NOT NULL, --证券代码
  prodCellCode                  VARCHAR(30)              NOT NULL, --单元代码
  currencyCode                  VARCHAR(6)                     NOT NULL,         --货币代码
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --市场来源
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --投保标志
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --多空标志
  createPosiDate                VARCHAR(10)              NOT NULL, --建仓日期
  posiQty                       NUMERIC(19,4)            NOT NULL, --持仓数量
  costChgAmt                    NUMERIC(19,4)             NULL, --成本变动金额
  lastestOperateDate            VARCHAR(10)              NOT NULL  --最后操作日期
)
*/

CREATE TABLE #tt_cellCheckJrnl_old
(
  operateDate                   VARCHAR(10)              NOT NULL, -- 发生日期
  exchangeCode                  VARCHAR(4)               NOT NULL, -- 交易所代码
  secuCode                      VARCHAR(30)              NOT NULL, -- 证券代码
  prodCellCode                  VARCHAR(30)              NOT NULL, -- 单元代码
  currencyCode                  VARCHAR(6)                     NOT NULL,         --货币代码
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --市场来源
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --投保标志
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --多空标志
  posiQty                       NUMERIC(19,4)            NOT NULL  -- 持仓数量
)

CREATE TABLE #tt_cellPosiQtyDetial
(
  createPosiDate                VARCHAR(10)              NOT NULL, --建仓日期
  prodCellCode                  VARCHAR(30)              NOT NULL, --单元代码
  currencyCode                  VARCHAR(6)                     NOT NULL,         --货币代码
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --市场来源
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --投保标志
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --多空标志
  posiQty                       NUMERIC(19,4)              NOT NULL, --持仓数量
  matchQty                      NUMERIC(19,4)              NOT NULL, --成交数量
  costChgAmt                    NUMERIC(19,4)              NOT NULL  --成本变动金额
)

CREATE TABLE #tt_cellPosiQtySum
(
  createPosiDate                VARCHAR(10)              NOT NULL, --建仓日期
  prodCellCode                  VARCHAR(30)              NOT NULL, --单元代码
  currencyCode                  VARCHAR(6)                     NOT NULL,         --货币代码
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --市场来源
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --投保标志
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --多空标志
  posiQty                       NUMERIC(19,4)              NOT NULL, --持仓数量
  matchQty                      NUMERIC(19,4)              NOT NULL, --成交数量
  costChgAmt                    NUMERIC(19,4)              NOT NULL, --成本变动金额
  rlzChgProfit                  NUMERIC(19,4)              NOT NULL  --盈亏变动金额
)

CREATE TABLE #tt_purchaseEntr
(
  occurDate              VARCHAR(10)         not null,
  occurDatetime          DATETIME        not null, 
  exchangeCode           VARCHAR(10)         not null, -- 交易所代码
  secuCode               VARCHAR(20)      not null, --

  fundAcctCode           VARCHAR(30)     not null,
  prodCellCode           VARCHAR(30)     not null,
  currencyCode                  VARCHAR(6)                     NOT NULL,         --货币代码
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --市场来源
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --投保标志
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --多空标志

  matchQty               DECIMAL(19, 2)  not null,
)

--
DECLARE 
@v_createPosiDate                 VARCHAR(10),           --建仓日期
@v_posiQty                        NUMERIC(19,4),         --持仓数量
@v_lastsettleDate                 VARCHAR(10),           --最后建仓日期

@temp_prodCellCode                VARCHAR(20),           --产品单元代码
@temp_shareRecordDate             VARCHAR(10),           --登记日期(临时变量)
@temp_mc_matchQty                 NUMERIC(10,0),         --卖出成交数量(临时变量)
@temp_mc_per_costChgAmt           NUMERIC(19,8),         --卖出移动平均成本变动(临时变量)
@temp_mc_costChgAmt               NUMERIC(19,2),         --买入移动平均成本变动(临时变量)
@temp_mc_per_rlzChgProfit         NUMERIC(19,8),         --卖出实现盈亏变动(临时变量)
@temp_mc_rlzChgProfit             NUMERIC(19,2),         --卖出实现盈亏变动(临时变量)
@temp_mc_per_cashCurrSettleAmt    NUMERIC(19,8),         --卖出资金发生数(临时变量)
@temp_mc_cashCurrSettleAmt        NUMERIC(19,2),         --卖出资金发生数(临时变量)
@temp_mc_per_matchTradeFeeAmt     NUMERIC(19,8),         --卖出交易费用(临时变量)
@temp_mc_matchTradeFeeAmt         NUMERIC(19,2),         --卖出交易费用(临时变量)
@temp_mr_prodCellCode             VARCHAR(20),           --买入产品单元代码(临时变量)
@temp_mr_secuCode                 VARCHAR(20),           --买入证券代码(临时变量)
@temp_mr_matchQty                 NUMERIC(10,0),         --买入成交数量(临时变量)
@temp_mr_per_costChgAmt           NUMERIC(19,8),         --买入移动平均成本变动1(临时变量)
@temp_mr_costChgAmt               NUMERIC(19,2),         --买入移动平均成本变动(临时变量)
@temp_mr_createPosiDate           VARCHAR(10),           --买入建仓日期(临时变量)

@v_tempCellCode                  VARCHAR(30),
@v_openQtyUnitValue              NUMERIC(19,4),           --申购最小单位
@v_purchaseComAmo                NUMERIC(19,4)           --申购委托总数量
 
--取当前日期
 DECLARE @v_today VARCHAR(10), @v_prevArchiveDate VARCHAR(10), --上次归档日期
         @v_lastestOperateDate VARCHAR(10),  @v_divCode  VARCHAR(1)--利息是否冲减成本
 SELECT @v_today = CONVERT(VARCHAR(10), getdate(), 21),@temp_mc_cashCurrSettleAmt =0--源代码有问题，暂时给默认值

 SELECT @v_prevArchiveDate = CONVERT(VARCHAR(10), prevArchiveDate, 21) FROM sims2016TradeToday..systemCfg
 SELECT @v_divCode = itemValueText FROM sims2016TradeToday..commonCfg WHERE itemCode = '2009' --0 计入实现盈亏， 1 冲减移动平均成本  
 --临时
  IF ISNULL(@v_divCode, '') ='' 
  SELECT @v_divCode = '1'
--计算成本计算开始日期
 --todo
 DECLARE @v_realBeginDate VARCHAR(10) = @i_beginDate
--判断资金账户是否上下线 @i_beginDate
 --todo
   BEGIN--删除产品单元股票核算流水
    DELETE sims2016TradeHist..prodCellCheckJrnlESHist
     WHERE settleDate >= @v_realBeginDate
       AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
       AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0);
  END
/*
  BEGIN--删除非交易类流水
    DELETE sims2016TradeHist..prodCellRawJrnlESHist
     WHERE settleDate >= @v_realBeginDate
       AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
       AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
       AND secuBizTypeCode  IN('183', '187', '188', '122', '123', '124');
  END
 
  BEGIN--删除非交易类流水
    DELETE sims2016TradeHist..prodCellRawJrnlHist
     WHERE settleDate >= @v_realBeginDate
       AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
       AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
       AND secuBizTypeCode  IN('183', '187', '188', '122', '123', '124');
  END
 */ 
   --取单元股票历史资金证券流水
    INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,  
                                   fundAcctCode, prodCode, prodCellCode, investPortfolioCode, transactionNO,
                                   currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, longShortFlagCode, hedgeFlagCode, buySellFlagCode, 
                                   matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt,cashSettleAmt, costChgAmt, rlzChgProfit
                                  )
                            SELECT MAX(serialNO), 0, settleDate,       
                                   fundAcctCode, prodCode, prodCellCode, MAX(investPortfolioCode), MAX(transactionNO),
                                   currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
                                   secuBizTypeCode, MAX(bizSubTypeCode), openCloseFlagCode, '1', hedgeFlagCode, buySellFlagCode,
                                   SUM(abs(matchQty)), CASE WHEN SUM(matchQty) = 0 THEN 0 ELSE SUM(matchQty*matchNetPrice) / SUM(matchQty) END, SUM(matchSettleAmt), SUM(matchTradeFeeAmt), SUM(cashSettleAmt), SUM(-cashSettleAmt), 0
                              FROM sims2016TradeHist..prodCellRawJrnlESHist a                              
                             WHERE settleDate >= @v_realBeginDate
                               AND settleDate <= @v_today  
                               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                               AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)           
                          GROUP BY settleDate, prodCode, fundAcctCode, prodCellCode, currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, openCloseFlagCode, hedgeFlagCode, buySellFlagCode
                          ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, a.originSecuCode, prodCellCode, secuBizTypeCode, openCloseFlagCode, MAX(serialNO)

--新股
/*
    INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,                         --记录序号, 处理排序编号, 业务发生日期                                    
                                   shareRecordDate, fundAcctCode, prodCode,              --送红派息登记日期, 资金账户代码, 产品代码
                                   prodCellCode, investPortfolioCode, transactionNO,     --产品单元代码, 投资组合代码, 交易编号
                                   currencyCode, marketLevelCode, exchangeCode,          --货币代码, 市场来源代码, 交易所代码
                                   secuCode, originSecuCode, secuTradeTypeCode,          --证券代码, 原始证券代码,证券交易类型代码 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,   --证券业务类别代码, 业务子类, 开平标志
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,    --多空标志, 投保标志, 买卖标志
                                   matchQty, matchNetPrice, matchSettleAmt,              --成交数量, 成交价格, 成交金额
                                   matchTradeFeeAmt,cashSettleAmt,               --成交费用, 资金发生数
                                   costChgAmt, rlzChgProfit                              --持仓成本金额变动, 持仓实现盈亏变动
                                  )
                           SELECT serialNO, 0, settleDate,    
                                  shareRecordDate, fundAcctCode, prodCode, 
                                  prodCellCode, investPortfolioCode, transactionNO,
                                  currencyCode, marketLevelCode, exchangeCode, 
                                  secuCode, originSecuCode, secuTradeTypeCode,  
                                  secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, 
                                  '1', hedgeFlagCode, buySellFlagCode,
                                  abs(matchQty), matchNetPrice, matchSettleAmt, 
                                  matchTradeFeeAmt, cashSettleAmt, 
                                  0, 0
                             FROM sims2016TradeHist..prodRawJrnlESHist a
                            WHERE settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today 
                              AND secuBizTypeCode IN ('103', '105', '106', '107') 
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                         ORDER BY fundAcctCode, settleDate
  */ 
  /*                     
                                                    
   --取产品股票送股派息流水
    INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,                         --记录序号, 处理排序编号, 业务发生日期                                    
                                   shareRecordDate, fundAcctCode, prodCode,              --送红派息登记日期, 资金账户代码, 产品代码
                                   prodCellCode, investPortfolioCode, transactionNO,     --产品单元代码, 投资组合代码, 交易编号
                                   currencyCode, marketLevelCode, exchangeCode,          --货币代码, 市场来源代码, 交易所代码
                                   secuCode, originSecuCode, secuTradeTypeCode,          --证券代码, 原始证券代码,证券交易类型代码 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,   --证券业务类别代码, 业务子类, 开平标志
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,    --多空标志, 投保标志, 买卖标志
                                   matchQty, matchNetPrice, matchSettleAmt,              --成交数量, 成交价格, 成交金额
                                   matchTradeFeeAmt,cashSettleAmt,               --成交费用, 资金发生数
                                   costChgAmt, rlzChgProfit                              --持仓成本金额变动, 持仓实现盈亏变动
                                  )
                           SELECT serialNO, 0, settleDate,    
                                  shareRecordDate, fundAcctCode, prodCode, 
                                  prodCellCode, investPortfolioCode, transactionNO,
                                  currencyCode, marketLevelCode, exchangeCode, 
                                  secuCode, originSecuCode, secuTradeTypeCode,  
                                  secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, 
                                  '1', hedgeFlagCode, buySellFlagCode,
                                  abs(matchQty), matchNetPrice, matchSettleAmt, 
                                  matchTradeFeeAmt, cashSettleAmt, 
                                  0, 0
                             FROM sims2016TradeHist..prodRawJrnlESHist a
                            WHERE settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today 
                              AND shareRecordDate != ' '
                              AND secuBizTypeCode IN ('183', '187', '188', '122') 
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                         ORDER BY fundAcctCode, settleDate
                          
   --取配股缴款（因为需要拆分成2条）
    INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,                         --记录序号, 处理排序编号, 业务发生日期                                    
                                   shareRecordDate, fundAcctCode, prodCode,              --送红派息登记日期, 资金账户代码, 产品代码
                                   prodCellCode, investPortfolioCode, transactionNO,     --产品单元代码, 投资组合代码, 交易编号
                                   currencyCode, marketLevelCode, exchangeCode,          --货币代码, 市场来源代码, 交易所代码
                                   secuCode, originSecuCode, secuTradeTypeCode,          --证券代码, 原始证券代码,证券交易类型代码 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,   --证券业务类别代码, 业务子类, 开平标志
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,    --多空标志, 投保标志, 买卖标志
                                   matchQty, matchNetPrice, matchSettleAmt,              --成交数量, 成交价格, 成交金额
                                   matchTradeFeeAmt,cashSettleAmt,               --成交费用, 资金发生数
                                   costChgAmt, rlzChgProfit                              --持仓成本金额变动, 持仓实现盈亏变动
                                  )
                           SELECT MAX(a.serialNO), 0, settleDate,    
                                  MAX(shareRecordDate), fundAcctCode, prodCode, 
                                  prodCellCode, '' AS investPortfolioCode, MAX(transactionNO),
                                  currencyCode, MAX(marketLevelCode), exchangeCode, 
                                  secuCode, originSecuCode, secuTradeTypeCode,  
                                  secuBizTypeCode, MAX(bizSubTypeCode), MAX(openCloseFlagCode), 
                                  '1', MAX(hedgeFlagCode), buySellFlagCode,
                                  SUM(abs(matchQty)),  case when SUM(matchQty) = 0 THEN 0 ELSE SUM(matchQty*matchNetPrice) / SUM(matchQty) END AS matchNetPrice, SUM(-matchSettleAmt), 
                                  0 AS matchTradeFeeAmt, SUM(cashSettleAmt), 
                                  0, 0
                             FROM sims2016TradeHist..prodRawJrnlESHist a
                            WHERE settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today 
                              AND secuBizTypeCode IN ('123') 
                              AND matchQty > 0
                              AND secuCode != ''
                              AND exchangeCode != ''
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
				                 GROUP BY settleDate, prodCellCode, currencyCode, a.fundAcctCode, a.prodCode, secuTradeTypeCode, buySellFlagCode, exchangeCode, secuCode, originSecuCode, secuBizTypeCode
                         ORDER BY a.fundAcctCode, a.prodCode, settleDate, exchangeCode, a.secuCode, a.originSecuCode, prodCellCode, secuTradeTypeCode, buySellFlagCode, MAX(a.serialNO)
 
     ---------------------------------- 非交易过户的配股上市
         INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,                         --记录序号, 处理排序编号, 业务发生日期                                    
                                   shareRecordDate, fundAcctCode, prodCode,              --送红派息登记日期, 资金账户代码, 产品代码
                                   prodCellCode, investPortfolioCode, transactionNO,     --产品单元代码, 投资组合代码, 交易编号
                                   currencyCode, marketLevelCode, exchangeCode,          --货币代码, 市场来源代码, 交易所代码
                                   secuCode, originSecuCode, secuTradeTypeCode,          --证券代码, 原始证券代码,证券交易类型代码 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,   --证券业务类别代码, 业务子类, 开平标志
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,    --多空标志, 投保标志, 买卖标志
                                   matchQty, matchNetPrice, matchSettleAmt,              --成交数量, 成交价格, 成交金额
                                   matchTradeFeeAmt,cashSettleAmt,               --成交费用, 资金发生数
                                   costChgAmt, rlzChgProfit                              --持仓成本金额变动, 持仓实现盈亏变动
                                  )
                           SELECT serialNO, 0, settleDate,    
                                  '' AS shareRecordDate, fundAcctCode, prodCode, 
                                  prodCellCode, investPortfolioCode, transactionNO,
                                  currencyCode, marketLevelCode, exchangeCode, 
                                  secuCode, originSecuCode, secuTradeTypeCode,  
                                  secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, 
                                  '1', hedgeFlagCode, buySellFlagCode,
                                  matchQty, matchNetPrice, matchSettleAmt, 
                                  matchTradeFeeAmt, cashSettleAmt, 
                                  0, 0
                             FROM sims2016TradeHist..prodRawJrnlESHist a
                            WHERE settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today 
                              AND secuBizTypeCode IN ('124') 
                              AND matchQty > 0
									           -- AND (cashSettleAmt != 0 or cjje != 0 or sjly != '0')
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                         ORDER BY fundAcctCode, settleDate
        */             
   --取单元证券持仓转入流水(8101)
                             INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,  
                                   fundAcctCode, prodCode, prodCellCode, 
                                   investPortfolioCode, transactionNO, currencyCode, 
                                   marketLevelCode, exchangeCode, secuCode, 
                                   originSecuCode, secuTradeTypeCode, secuBizTypeCode, 
                                   bizSubTypeCode, openCloseFlagCode, longShortFlagCode,
                                   hedgeFlagCode, buySellFlagCode, matchQty, 
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, costChgAmt, rlzChgProfit
                                  )      
                            SELECT serialNO, 0, settleDate,       
                                   fundAcctCode, prodCode, prodCellCode, 
                                   investPortfolioCode, transactionNO, currencyCode, 
                                   marketLevelCode, exchangeCode, secuCode, 
                                   ' ', secuTradeTypeCode, secuBizTypeCode, 
                                   'S1', '1', '1', 
                                   hedgeFlagCode, '1', abs(matchQty), 
                                   CASE WHEN matchQty = 0 THEN 0 ELSE investCostAmt / matchQty END, 0, 0, 
                                   0, investCostAmt, 0
                              FROM sims2016TradeHist..prodCellInOutESHist a
                             WHERE secuBizTypeCode = '8101'
                               AND settleDate >= @v_realBeginDate
                               AND settleDate <= @v_today                   
                               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                               AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                          ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, secuBizTypeCode
                          
                          
       --取单元证券持仓转出流水(8103)                   
        INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,  
                                   fundAcctCode, prodCode, prodCellCode, 
                                   investPortfolioCode, transactionNO, currencyCode, 
                                   marketLevelCode, exchangeCode, secuCode, 
                                   originSecuCode, secuTradeTypeCode, secuBizTypeCode, 
                                   bizSubTypeCode, openCloseFlagCode, longShortFlagCode, 
                                   hedgeFlagCode, buySellFlagCode, matchQty, 
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, costChgAmt, rlzChgProfit
                                  )   
                           SELECT serialNO, 0, settleDate,       
                                  fundAcctCode, prodCode, prodCellCode,
                                  investPortfolioCode, transactionNO, currencyCode, 
                                  marketLevelCode, exchangeCode, secuCode, 
                                  ' ', secuTradeTypeCode, secuBizTypeCode,
                                  'S1', 'A', '1', 
                                  hedgeFlagCode, '1', abs(matchQty), 
                                  CASE WHEN matchQty = 0 THEN 0 ELSE investCostAmt / matchQty END, 0, 0,
                                  0, investCostAmt, 0
                             FROM sims2016TradeHist..prodCellInOutESHist a
                            WHERE secuBizTypeCode = '8103'
                              AND settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today                   
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                         ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, secuBizTypeCode                                   
 
  --新股申购委托统计
  --insert #tt_purchaseEntr(occurDate, occurDatetime, exchangeCode, secuCode, fundAcctCode, prodCellCode, matchQty) 
		--		   select tradeDate, tradeTime, exchangeCode, secuCode fundAcctCode, prodCellCode, orderQty
  --       from utrm30drsj..prev_wtb_dr_jyzh a inner join #nbzjzh d on a.nbzjzh = d.nbzjzh
  --       where (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
  --       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
  --       AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
         --AND secuBizTypeCode IN ('103', '105', '106', '107')
  --       --AND jylx = 'SG' 
  --      ORDER BY fundAcctCode, tradeDate, exchangeCode, a.secuCode, prodCellCode,
  
  /*     
  insert #tt_purchaseEntr(occurDate, occurDatetime, exchangeCode, secuCode, fundAcctCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, matchQty) 
				   select tradeDate, tradeTime, exchangeCode, secuCode, fundAcctCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, orderQty
         from sims2016TradeHist..prodCellOrderESHist a 
         where (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
         AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
         AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
         AND secuBizTypeCode IN ('103', '105', '106', '107')
        ORDER BY fundAcctCode, tradeDate, exchangeCode, a.secuCode, prodCellCode
  */     
 --逐条处理
  DECLARE @o_fundAcctCode VARCHAR(20)
  SELECT @o_fundAcctCode = null
 
--游标变量BEGIN
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
@v_longShortFlagCode        VARCHAR(16),                     --多空标志
@v_secuBizTypeCode          VARCHAR(16),                     --业务类型
@v_matchQty                 NUMERIC(10,0),                   --成交数量
@v_matchNetPrice            NUMERIC(10,2),                   --成交价格
@v_cashCurrentSettleAmt     NUMERIC(19,2),                   --资金发生数
@v_matchTradeFeeAmt         NUMERIC(19,2),                   --手续费
@v_matchSettleAmt           NUMERIC(19,2),                   --成交结算金额
@v_costChgAmt               NUMERIC(19,2),                   --移动平均成本变动
@v_rlzChgProfit             NUMERIC(19,2)                    --实现盈亏变动
--游标变量END

 DECLARE for_mccjb CURSOR FOR SELECT serialNO, orderID, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                          exchangeCode, secuCode, originSecuCode, '', secuTradeTypeCode, longShortFlagCode,
                          prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, currencyCode, hedgeFlagCode, 
                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                          costChgAmt, rlzChgProfit
                     FROM #tt_prodCellRawJrnl 
                 ORDER BY fundAcctCode, exchangeCode, secuCode, occurDate, orderID, buySellFlagCode DESC, serialNO
  OPEN for_mccjb
  FETCH for_mccjb INTO @v_serialNO, @v_orderID, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode, 
                       @v_exchangeCode, @v_secuCode, @v_originSecuCode,@v_secuName, @v_secuTradeTypeCode, @v_longShortFlagCode,
                       @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_currencyCode, @v_hedgeFlagCode, 
                       @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                       @v_costChgAmt, @v_rlzChgProfit
                       
   WHILE 1 = 1
    BEGIN
    IF @o_fundAcctCode IS NOT NULL AND (@o_fundAcctCode != @v_fundAcctCode or @@FETCH_STATUS != 0)  
       BEGIN
          INSERT INTO sims2016TradeHist..prodCellCheckJrnlESHist( createPosiDate, settleDate,
                                              prodCode, prodCellCode, fundAcctCode,
                                              currencyCode, exchangeCode, secuCode,
                                              originSecuCode, secuTradeTypeCode, marketLevelCode,
                                              transactionNO, investPortfolioCode, buySellFlagCode,
                                              bizSubTypeCode, openCloseFlagCode, longShortFlagCode,
                                              hedgeFlagCode, secuBizTypeCode, matchQty,
                                              matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                              cashSettleAmt, costChgAmt, occupyCostChgAmt,
                                              rlzChgProfit, investCostChgAmt,
                                              investOccupyCostChgAmt, investRlzChgProfit   
                                             )
                                       SELECT createPosiDate, occurDate, 
                                              prodCode, prodCellCode, fundAcctCode, 
                                              currencyCode, exchangeCode, secuCode,
                                              originSecuCode, secuTradeTypeCode, marketLevelCode,
                                              1, investPortfolioCode, buySellFlagCode,
                                              'S1', openCloseFlagCode, longShortFlagCode,
                                              hedgeFlagCode, secuBizTypeCode, matchQty,
                                              matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                              cashSettleAmt, costChgAmt, occupyCostChgAmt,
                                              rlzChgProfit, costChgAmt,
                                              occupyCostChgAmt, rlzChgProfit                                                
                                         FROM #tt_prodCellCheckJrnlES
                                         
     /*                                    
          INSERT INTO sims2016TradeHist..prodCellRawJrnlHist( 
																															originSerialNO,
																															settleDate,
																															secuBizTypeCode,
																															buySellFlagCode,
																															bizSubTypeCode,
																															openCloseFlagCode,
																															hedgeFlagCode,
																															coveredFlagCode,
																															originSecuBizTypeCode,
																															brokerSecuBizTypeCode,
																															brokerSecuBizTypeName,
																															brokerJrnlSerialID,
																															prodCode,
																															prodCellCode,
																															fundAcctCode,
																															currencyCode,
																															cashSettleAmt,
																															cashBalanceAmt,
																															exchangeCode,
																															secuAcctCode,
																															secuCode,
																															originSecuCode,
																															secuName,
																															secuTradeTypeCode,
																															matchQty,
																															posiBalanceQty,
																															matchNetPrice,
																															dataSourceFlagCode,
																															marketLevelCode,
																															operatorCode,
																															operateDatetime,
																															operateRemarkText   )
																						           SELECT 
																															0,
																															occurDate,
																															secuBizTypeCode,
																															buySellFlagCode,
																															'S1',
																															openCloseFlagCode,
																															hedgeFlagCode,
																															' ',
																															' ',
																															' ',
																															' ',
																															' ',
																															prodCode,
																															prodCellCode,
																															fundAcctCode,
																															currencyCode,
																															cashSettleAmt,
																															0,
																															exchangeCode,
																															' ',
																															secuCode,
																															originSecuCode,
																															secuName,
																															secuTradeTypeCode,
																															matchQty,
																															0,
																															matchNetPrice,
																															0,
																															marketLevelCode,
																															' ',
																															GETDATE(),
																															' ' 
                                       FROM #tt_prodCellCheckJrnlES 
                                      WHERE secuBizTypeCode IN('183', '187', '188', '122', '123', '124')                                
                                    
                                         
          INSERT INTO sims2016TradeHist..prodCellRawJrnlESHist(serialNO,  settleDate, secuBizTypeCode,
                                            buySellFlagCode, bizSubTypeCode, openCloseFlagCode,
                                            hedgeFlagCode, originSecuBizTypeCode, brokerSecuBizTypeCode,
                                            brokerSecuBizTypeName, brokerJrnlSerialID, prodCode,
                                            prodCellCode, fundAcctCode, currencyCode,
                                            cashSettleAmt, cashBalanceAmt, exchangeCode,
                                            secuAcctCode, secuCode, originSecuCode,
                                            secuName, secuTradeTypeCode, matchQty,
                                            posiBalanceQty, matchNetPrice, matchSettleAmt,
                                            matchTradeFeeAmt, matchDate, matchTime,
                                            matchID, brokerOrderID, brokerOriginOrderID,
                                            brokerErrorMsg, dataSourceFlagCode, transactionNO,
                                            investPortfolioCode, assetLiabilityTypeCode, investInstrucNO,
                                            traderInstrucNO, orderNO, marketLevelCode,
                                            orderNetAmt, orderNetPrice, orderQty,
                                            orderSettleAmt, orderSettlePrice, orderTradeFeeAmt,
                                            directorCode, traderCode, operatorCode,
                                            operateDatetime, operateRemarkText, shareRecordDate
                                           )
                                     SELECT bb.serialNO, occurDate, aa.secuBizTypeCode,
                                            aa.buySellFlagCode, ' ', aa.openCloseFlagCode,
                                            aa.hedgeFlagCode, ' ', ' ',
                                            ' ', ' ', aa.prodCode,
                                            aa.prodCellCode, aa.fundAcctCode, aa.currencyCode,
                                            aa.cashSettleAmt, 0, aa.exchangeCode,
                                            ' ', aa.secuCode, aa.originSecuCode,
                                            ' ', aa.secuTradeTypeCode, aa.matchQty,
                                            0, aa.matchNetPrice, matchSettleAmt,
                                            matchTradeFeeAmt, createPosiDate, ' ',
                                            ' ', ' ', ' ',
                                            ' ', '0', 1,
                                            investPortfolioCode, ' ', 0,
                                            0, 0, '2',
                                            0, 0, 0,
                                            0, 0, 0,
                                            ' ', ' ', ' ',
                                            GETDATE(), ' ', shareRecordDate
                                       FROM #tt_prodCellCheckJrnlES aa inner join sims2016TradeHist..prodCellRawJrnlHist bb
																				    ON (aa.occurDate = bb.settleDate AND  aa.prodCellCode =  bb.prodCellCode AND aa.exchangeCode = bb.exchangeCode AND aa.secuCode = bb.secuCode
																				        AND aa.secuBizTypeCode = bb.secuBizTypeCode)                                       
                                      WHERE aa.secuBizTypeCode IN('183', '187', '188', '122', '123', '124');
                    */                  
          TRUNCATE TABLE #tt_prodCellCheckJrnlES
        END
        
     IF @@FETCH_STATUS != 0
        BREAK
    --beign 初始账户或者账户切换
    IF @o_fundAcctCode IS NULL OR @o_fundAcctCode != @v_fundAcctCode
    BEGIN
     SELECT @o_fundAcctCode = @v_fundAcctCode
     
     TRUNCATE TABLE #tt_cellcreatePosiDate
     TRUNCATE TABLE #tt_cellcreatePosiDateSum
     
     --取快照表(TODO)
     --取历史核算流水表

     
            INSERT INTO #tt_cellcreatePosiDate(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                        SELECT exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode,MAX(createPosiDate), SUM(matchQty), SUM(costChgAmt), MAX(settleDate)
                                          FROM sims2016TradeHist..prodCellCheckJrnlESHist
                                          WHERE fundAcctCode = @v_fundAcctCode  
                                                AND settleDate < @v_realBeginDate -- AND settleDate > 快照日期 (待后续快照表设计好后加上此条件) 
                                                AND (@i_exchangeCode = '' or CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                                AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
                                          GROUP BY prodCellCode, exchangeCode, secuCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode
                                                                    
             INSERT INTO #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                          SELECT exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode,MAX(createPosiDate),SUM(posiQty), SUM(costChgAmt), MAX(lastestOperateDate)
                                            FROM #tt_cellcreatePosiDate
                                            GROUP BY exchangeCode, secuCode, prodCellCode, createPosiDate, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode
                                            HAVING SUM(posiQty) > 0;                                          
                          
            TRUNCATE TABLE #tt_cellCheckJrnl_old
            
            SELECT @temp_shareRecordDate = shareRecordDate FROM #tt_prodCellRawJrnl WHERE fundAcctCode = @v_fundAcctCode AND shareRecordDate != ''
            
            SELECT @temp_shareRecordDate = ISNULL(@temp_shareRecordDate, '')
            
            INSERT INTO #tt_cellCheckJrnl_old(operateDate, exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty)
                                      SELECT settleDate, exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(matchQty)
                                        FROM sims2016TradeHist..prodCellCheckJrnlESHist
                                        WHERE settleDate < @v_realBeginDate -- AND settleDate > 快照日期 (待后续快照表设计好后加上此条件)
                                              AND fundAcctCode = @v_fundAcctCode
                                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+originSecuCode+',', @i_secuCode) > 0)
                                        GROUP BY settleDate, exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode
                                        HAVING SUM(matchQty) != 0;
  
    END
    --END 初始账户或者账户切换
    
    IF @v_exchangeCode = '' AND @v_secuCode = ''
    BEGIN
			TRUNCATE TABLE #tt_cellcreatePosiDateSum
		END
		ELSE IF @v_secuBizTypeCode in ('122','123', '1231', '1232', '124', '1241', '1242', '103', '106', '105', '107', '1071', '1072')
		BEGIN
      INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                  exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                  prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                  matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                  costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                    SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,@v_investPortfolioCode,
                           @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                           @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                           @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                           @v_costChgAmt, 0, @v_rlzChgProfit
                           
       IF  @v_secuBizTypeCode IN ('122', '1242', '103','106', '1072') 
       BEGIN                  
         IF not exists (SELECT * FROM #tt_cellcreatePosiDateSum 
                        WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                        AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode)
           INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                           SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
         ELSE
           BEGIN
            UPDATE #tt_cellcreatePosiDateSum 
              SET createPosiDate = CASE WHEN @v_secuBizTypeCode != '122' THEN @v_createPosiDate ELSE createPosiDate END,
                  posiQty = posiQty + @v_posiQty , 
                  costChgAmt = costChgAmt + CASE WHEN @v_secuBizTypeCode != '122' THEN @v_costChgAmt ELSE 0 END, 
                  lastestOperateDate = CASE WHEN @v_secuBizTypeCode != '122' THEN @v_lastestOperateDate ELSE lastestOperateDate END
            WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                  AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  
           END  
        END
       ELSE IF @v_secuBizTypeCode IN ('1241', '105', '1071') 
       BEGIN
         UPDATE #tt_cellcreatePosiDateSum 
           SET posiQty = posiQty - @v_posiQty, 
               costChgAmt = costChgAmt - @v_costChgAmt, 
               lastestOperateDate = @v_lastestOperateDate
         WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
               AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
       END                                               
		END
        /*		
		ELSE IF @v_secuBizTypeCode = '122'  --SPGDJ  送配股登记
			BEGIN
				--TRUNCATE TABLE #tt_cellPosiQtyDetial
    --    TRUNCATE TABLE #tt_cellPosiQtySum
        
        IF @v_shareRecordDate < @v_prevArchiveDate
          SELECT @v_shareRecordDate = @v_prevArchiveDate

          INSERT #tt_cellPosiQtyDetial (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
                          SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(posiQty), 0, 0
                                 FROM #tt_cellCheckJrnl_old
                                 WHERE operateDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_originSecuCode 
                                 GROUP BY prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode                                
                                 HAVING SUM(posiQty) > 0

          INSERT #tt_cellPosiQtyDetial (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
                          SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(matchQty), 0, 0
                                 FROM #tt_prodCellCheckJrnlES
                                 WHERE occurDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_originSecuCode 
                                 GROUP BY prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode                                 
                                 HAVING SUM(matchQty) != 0

          INSERT #tt_cellPosiQtySum (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                          SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(posiQty), 0, 0, 0
                                 FROM #tt_cellPosiQtyDetial
                                 GROUP BY prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode                                 
                                 HAVING SUM(posiQty) > 0

          IF exists (SELECT * FROM #tt_cellPosiQtySum)
            BEGIN
              SELECT @v_openQtyUnitValue = openQtyUnitValue FROM sims2016TradeToday..secuTable WHERE secuCode = @v_secuCode
              SELECT @v_openQtyUnitValue = ISNULL(@v_openQtyUnitValue, 1)

              SELECT @v_posiQty = SUM(posiQty) FROM #tt_cellPosiQtySum    

              UPDATE #tt_cellPosiQtySum SET matchQty = FLOOR(ROUND(posiQty * @v_matchQty / CONVERT(FLOAT, @v_posiQty), 4) / @v_openQtyUnitValue) * @v_openQtyUnitValue

              SELECT @v_matchQty = @v_matchQty - SUM(matchQty) FROM #tt_cellPosiQtySum

              IF @v_matchQty != 0 or @v_costChgAmt != 0 or @v_rlzChgProfit != 0 -- 尾数
                BEGIN
                  SET rowcount 1
                  SELECT @temp_prodCellCode = prodCellCode FROM #tt_cellPosiQtySum ORDER BY posiQty desc
                  UPDATE #tt_cellPosiQtySum SET matchQty = matchQty + @v_matchQty WHERE prodCellCode = @temp_prodCellCode
                  SET rowcount 0
                END

              IF not exists (SELECT * FROM #tt_cellcreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode)
                INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                 SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
              ELSE
                BEGIN
                  UPDATE #tt_cellcreatePosiDateSum SET posiQty = posiQty + @v_matchQty
                                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                END
            END
          ELSE-- 未找到正股持仓
            BEGIN
              IF not exists (SELECT * FROM #tt_cellcreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode)
                BEGIN
                  INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                 SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
                END
              ELSE
                BEGIN
                  UPDATE #tt_cellcreatePosiDateSum SET posiQty = posiQty + @v_matchQty
                                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode
                END
  
              INSERT #tt_cellPosiQtySum (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                              SELECT @v_settleDate, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, 0, @v_matchQty, 0, 0
            END

          INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                          exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                          prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                          costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                            SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                                   @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                                   prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                                   matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                   0, 0, 0     
                                   --FROM #tt_cellPosiQtySum      

          -- 更新或者增加持仓
          UPDATE a SET posiQty = a.posiQty + b.matchQty
                   FROM #tt_cellcreatePosiDateSum_rs a 
                   inner join #tt_cellPosiQtySum b ON a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode AND a.originSecuCode = @v_originSecuCode AND a.prodCellCode = b.prodCellCode          
 
          INSERT #tt_cellcreatePosiDateSum_rs (exchangeCode, secuCode, originSecuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                               SELECT exchangeCode, secuCode, originSecuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate
                                       FROM (SELECT @v_exchangeCode AS exchangeCode, @v_secuCode AS secuCode, @v_originSecuCode AS originSecuCode, a.prodCellCode, @v_currencyCode AS currencyCode, 
                                                    @v_marketLevelCode AS marketLevelCode,@v_hedgeFlagCode AS hedgeFlagCode,@v_longShortFlagCode AS longShortFlagCode, @v_settleDate AS createPosiDate, a.matchQty AS posiQty, 0 AS costChgAmt, 
                                                    @v_settleDate AS lastestOperateDate, b.createPosiDate AS createPosiDate_y
                                                    FROM #tt_cellPosiQtySum a 
                                                    left join #tt_cellcreatePosiDateSum_rs b ON a.prodCellCode = b.prodCellCode AND b.exchangeCode = @v_exchangeCode AND b.secuCode = @v_secuCode AND b.originSecuCode = @v_originSecuCode 
                                                    AND b.currencyCode = @v_currencyCode AND b.marketLevelCode = @v_marketLevelCode AND b.hedgeFlagCode = @v_hedgeFlagCode AND b.longShortFlagCode = @v_longShortFlagCode
                                           )x
                                            WHERE x.createPosiDate_y is null				

			END	
		ELSE IF @v_secuBizTypeCode in ('123') --PGJK 配股缴款
      BEGIN
          -- 配股权证持仓减少 PGJKQZJS   1231
          SELECT @v_createPosiDate = null
          SELECT @v_createPosiDate = createPosiDate 
          FROM #tt_cellcreatePosiDateSum_rs 
          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND originSecuCode = @v_originSecuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode          

          IF @v_createPosiDate is not null
            BEGIN              
              UPDATE #tt_cellcreatePosiDateSum_rs SET posiQty = posiQty - @v_matchQty
                     WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND originSecuCode = @v_originSecuCode AND prodCellCode = @v_prodCellCode 
                           AND currencyCode = @v_currencyCode AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  

          INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                          exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                          prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                          costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                            SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                                   @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                                   @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, '1231' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                                    -1 * @v_matchQty, 0, 0, 0, 0,
                                   0, 0, 0     
            END

          --配股（正股未上市）持仓增加
          SELECT @v_createPosiDate = null
          SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate FROM #tt_cellcreatePosiDateSum_rs
                 WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_originSecuCode AND originSecuCode = @v_originSecuCode AND prodCellCode = @v_prodCellCode
          IF @v_createPosiDate is null
            BEGIN
              INSERT #tt_cellcreatePosiDateSum_rs (exchangeCode, secuCode, originSecuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                  SELECT @v_exchangeCode, @v_originSecuCode, @v_originSecuCode, @v_prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate
              SELECT @v_createPosiDate = @v_settleDate
            END
          ELSE
            BEGIN
              UPDATE #tt_cellcreatePosiDateSum_rs SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + @v_costChgAmt, lastestOperateDate = @v_settleDate
                     WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_originSecuCode AND originSecuCode = @v_originSecuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
            END
            -- 配股权证持仓增加 PGJKQZZJ   1232

          INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                          exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                          prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                          costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                            SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                                   @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                                   @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, '1232' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                                   @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                  ROUND(@v_costChgAmt, 2), 0, ROUND(@v_rlzChgProfit, 2) 
        END   

    ELSE IF(@v_secuBizTypeCode = '124')      --PGSS 配股上市。
      BEGIN
          --找到配股缴款的持仓 以及信托单元，然后按缴款持仓进行拆分。            
          WHILE @v_matchQty > 0
            BEGIN
              SELECT @temp_mr_prodCellCode = null
              SELECT TOP 1 
                     @temp_mr_prodCellCode = prodCellCode,
                     @temp_mr_secuCode = secuCode,
                     @temp_mr_matchQty = abs(posiQty),                                
                     @temp_mr_costChgAmt = costChgAmt,
                     @temp_mr_per_costChgAmt = costChgAmt / abs(posiQty), 
                     @temp_mr_createPosiDate = createPosiDate 
                     FROM #tt_cellcreatePosiDateSum_rs
                     WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND originSecuCode = @v_secuCode AND abs(posiQty) > 0 AND currencyCode = @v_currencyCode 
                           AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                     ORDER BY createPosiDate, prodCellCode

              IF @temp_mr_prodCellCode is not null
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

                  SELECT @v_costChgAmt = ISNULL(@v_costChgAmt,0) - ISNULL(@temp_mc_costChgAmt,0)

                  SELECT @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt

                  UPDATE #tt_cellcreatePosiDateSum_rs SET posiQty = posiQty - @temp_mc_matchQty, 
                                              costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestOperateDate = @v_settleDate
                                              WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND originSecuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode
                                                    AND currencyCode = @v_currencyCode AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                   --配股上市转出记录 '1241','股票配股上市转出' PGSSZC
                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @temp_mr_createPosiDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'S' AS buySellFlagCode, @v_openCloseFlagCode, '1241' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          -1 * @temp_mc_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          -1 * @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
            
                   SELECT @v_createPosiDate = null
                   SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate FROM #tt_cellcreatePosiDateSum
                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   IF @v_createPosiDate is null
                      BEGIN
                        INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                          SELECT @v_exchangeCode, @v_secuCode, @v_prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @temp_mc_matchQty, @temp_mr_costChgAmt, @v_settleDate
                        SELECT @v_createPosiDate = @v_settleDate
                      END                 
                    ELSE
                      BEGIN
                        UPDATE #tt_cellcreatePosiDateSum SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @temp_mc_matchQty, costChgAmt = costChgAmt + @temp_mr_costChgAmt, lastestOperateDate = @v_settleDate
                               WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      END
                --'1242','股票配股上市转入'   PGSSZR    
                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, '1242' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @temp_mc_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
                END
              ELSE -- 找不到对应的配股记录
                BEGIN
                   SELECT @v_createPosiDate = null
                   SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate FROM #tt_cellcreatePosiDateSum
                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   IF @v_createPosiDate is null
                      BEGIN
                        INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                          SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode AS prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
                        SELECT @v_createPosiDate = @v_settleDate
                      END                 
                    ELSE
                      BEGIN
                        UPDATE #tt_cellcreatePosiDateSum SET createPosiDate = @v_createPosiDate, 
                                                    posiQty = posiQty + @v_matchQty, 
                                                    costChgAmt = costChgAmt + 0, 
                                                    lastestOperateDate = @v_settleDate
                                                WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                      AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  
                      END
                   
                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @v_fundAcctCode AS prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, '1242' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          0, 0 AS matchNetPrice, 0, 0, 0,
                          0, 0, 0 AS rlzChgProfit 
                  BREAK
                END
            END
          SET rowcount 0
        END
       
    ELSE IF @v_secuBizTypeCode in ('103','106')   -- 103 SGMR 新股申购, 106 SGZQ 新股中签
      begin
        truncate TABLE #tt_cellPosiQtyDetial

        insert #tt_cellPosiQtyDetial (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
                        select @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, sum(matchQty), 0, 0
                          from #tt_purchaseEntr
                         --where exchangeCode = @v_exchangeCode AND dbo.fnGetOriginSecuCode(exchangeCode, secuCode) = @v_originSecuCode AND fundAcctCode = @v_fundAcctCode
                         WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND fundAcctCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                               AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      group by occurDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode

        IF exists (select * from #tt_cellPosiQtyDetial)
          begin
            select @v_purchaseComAmo = sum(posiQty) from #tt_cellPosiQtyDetial
            --暂时处理，表字段不全
            --select @v_openQtyUnitValue = case when value = '1' AND @v_exchangeCode = '0' then 500
            --                      when value = '1' AND @v_exchangeCode = '1' then 1000
            --                      ELSE 1 end from sims2016TradeToday..systemCfg where item_bs = 'XGZQZXFPDW'
            select @v_openQtyUnitValue = case when @v_exchangeCode = 'XSHE' then 1  when @v_exchangeCode = 'XSHG' then 1 ELSE 1 end

            select @v_openQtyUnitValue = isnull(@v_openQtyUnitValue, 1)
            update #tt_cellPosiQtyDetial set matchQty = floor(round((posiQty  * @v_matchQty / convert(money, @v_purchaseComAmo)), 4) / @v_openQtyUnitValue) * @v_openQtyUnitValue,
                                      costChgAmt = floor(round((posiQty  * @v_matchQty / convert(money, @v_purchaseComAmo)), 4) / @v_openQtyUnitValue) * @v_openQtyUnitValue * round(@v_matchNetPrice, 2)

            select @v_matchQty = @v_matchQty - sum(matchQty), @v_costChgAmt = ISNULL(@v_costChgAmt,0) - ISNULL(sum(costChgAmt),0) from #tt_cellPosiQtyDetial

            IF exists(select * from tempdb..sysobjects where id=object_id('tempdb..#tt_purchaseEntr1'))
            DROP TABLE #tt_purchaseEntr1
            SELECT * INTO #tt_purchaseEntr1 FROM #tt_purchaseEntr

            IF @v_matchQty != 0 or @v_costChgAmt != 0 or @v_rlzChgProfit != 0 -- 尾数
              begin 
				      while(@v_matchQty >= @v_openQtyUnitValue)
				        begin
					      declare @tempCjkhdm VARCHAR(20)
					      select top 1 @tempCjkhdm = prodCellCode from  #tt_purchaseEntr1 
								       where exchangeCode = @v_exchangeCode AND dbo.fnGetOriginSecuCode(exchangeCode, secuCode) = @v_originSecuCode AND fundAcctCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                             AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
								       order by matchQty desc, occurDatetime asc
				          update #tt_cellPosiQtyDetial set matchQty = matchQty + @v_openQtyUnitValue, costChgAmt = costChgAmt + @v_openQtyUnitValue * @v_matchNetPrice 
						         where prodCellCode = @tempCjkhdm
      	                
	                  delete #tt_purchaseEntr1 where prodCellCode = @tempCjkhdm
      	                  
					      select @v_matchQty = @v_matchQty - @v_openQtyUnitValue                  
				  end	

              delete #tt_cellPosiQtyDetial where matchQty = 0   --删除申购数量或者中签数量为0的流水
              end
          end
        -- 未找到对应委托
        ELSE
          begin
            IF not exists (select * from #tt_cellcreatePosiDateSum where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode)
			  insert #tt_cellcreatePosiDateSum(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                               select @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate
            ELSE
              begin
                update #tt_cellcreatePosiDateSum set posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + @v_costChgAmt
                       where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
              end

            insert #tt_cellPosiQtyDetial(createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
						   select @v_settleDate, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, 0, @v_matchQty, round(@v_costChgAmt, 2)
          END
          
         INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                      exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                      prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                      matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                      costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
         SELECT DISTINCT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                matchQty, 0 AS matchNetPrice, -round(costChgAmt, 2), @v_matchTradeFeeAmt, @v_matchSettleAmt,
                round(costChgAmt, 2), 0, 0 AS rlzChgProfit 
                from #tt_cellPosiQtyDetial

        -- 更新或者增加持仓
        --DELETE #tt_cellcreatePosiDateSum
        
        update a set posiQty = a.posiQty + b.matchQty
               from #tt_cellcreatePosiDateSum a 
					join #tt_cellPosiQtyDetial b
                    on a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode AND a.prodCellCode = b.prodCellCode AND a.currencyCode = b.currencyCode 
                                                AND a.marketLevelCode = b.marketLevelCode AND a.hedgeFlagCode = b.hedgeFlagCode AND a.longShortFlagCode = b.longShortFlagCode 

        insert #tt_cellcreatePosiDateSum(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                         select exchangeCode, secuCode, prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate
                                from (select @v_exchangeCode as exchangeCode, @v_secuCode as secuCode, a.prodCellCode, @v_settleDate as createPosiDate, a.matchQty as posiQty, a.costChgAmt as costChgAmt, @v_settleDate as lastestOperateDate, b.createPosiDate as jcrq_y
                                             from #tt_cellPosiQtyDetial a 
                                                  left join #tt_cellcreatePosiDateSum b on a.prodCellCode = b.prodCellCode AND b.exchangeCode = @v_exchangeCode AND b.secuCode = @v_secuCode AND b.currencyCode = @v_currencyCode 
                                                AND b.marketLevelCode = @v_marketLevelCode AND b.hedgeFlagCode = @v_hedgeFlagCode AND b.longShortFlagCode = @v_longShortFlagCode)x
                                where x.jcrq_y is NULL

      end
      --申购还款
    ELSE IF @v_secuBizTypeCode in ('105')
      begin
          while @v_matchQty > 0
            begin
              select @temp_mr_prodCellCode = null
              select top 1 @temp_mr_prodCellCode = prodCellCode, @temp_mr_secuCode = secuCode, @temp_mr_matchQty = abs(posiQty), @temp_mr_costChgAmt = costChgAmt,
						   @temp_mr_per_costChgAmt = costChgAmt / abs(posiQty), @temp_mr_createPosiDate = createPosiDate
					 from #tt_cellcreatePosiDateSum
					 where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode  AND currencyCode = @v_currencyCode AND marketLevelCode = @v_marketLevelCode 
					 AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode AND abs(posiQty) > 0
					 order by createPosiDate, prodCellCode

              IF @temp_mr_prodCellCode is not null
                begin
                  IF @v_matchQty < @temp_mr_matchQty
                    select @temp_mc_matchQty = @v_matchQty
                  ELSE
                    select @temp_mc_matchQty = @temp_mr_matchQty

                  select @v_matchQty = @v_matchQty - @temp_mc_matchQty

                  IF @temp_mc_matchQty < @temp_mr_matchQty
                    begin
                      select @temp_mc_costChgAmt = round(@temp_mc_matchQty * @temp_mr_per_costChgAmt, 2)
                    end
                  ELSE
                    begin
                      select @temp_mc_costChgAmt = @temp_mr_costChgAmt
                    end

                  IF @temp_mc_matchQty != @temp_mr_matchQty
                    select @temp_mr_costChgAmt = round(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)

                  select @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt

                  select @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt

                  select @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt

                  update #tt_cellcreatePosiDateSum set posiQty = posiQty - @temp_mc_matchQty,
                                              costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestOperateDate = @v_settleDate
                                        where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode AND currencyCode = @v_currencyCode 
                                              AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          -1 * @temp_mc_matchQty, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @temp_mc_matchQty, 0 AS matchNetPrice, @temp_mr_costChgAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          -1 * @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
                  end
              ELSE -- 找不到对应的记录
                begin
                   select @v_createPosiDate = null
                   select @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate from #tt_cellcreatePosiDateSum
					      where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                      AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   IF @v_createPosiDate is null
                      begin
                        insert #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                          select @v_exchangeCode, @v_secuCode, @v_fundAcctCode as prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate

                        select @v_createPosiDate = @v_settleDate
                      end
                    ELSE
                      begin
                        update #tt_cellcreatePosiDateSum set createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + 0, lastestOperateDate = @v_settleDate
                               where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      end

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @v_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
                    break
                end
            end

        end
      -- 新股上市。
    ELSE IF(@v_secuBizTypeCode = '107')
      begin
          while @v_matchQty > 0
            begin
              select @temp_mr_prodCellCode = null
              select top 1 @temp_mr_prodCellCode = prodCellCode,
						   @temp_mr_secuCode = secuCode,
						   @temp_mr_matchQty = abs(posiQty),
               @temp_mr_costChgAmt = costChgAmt,
               @temp_mr_per_costChgAmt = costChgAmt / abs(posiQty),
               @temp_mr_createPosiDate = createPosiDate
               from #tt_cellcreatePosiDateSum
               where exchangeCode = @v_exchangeCode AND dbo.fnGetOriginSecuCode(exchangeCode, secuCode) = @v_secuCode AND currencyCode = @v_currencyCode 
                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode AND abs(posiQty) > 0
						   order by createPosiDate, prodCellCode

              IF @temp_mr_prodCellCode is not null
                begin
                  IF @v_matchQty < @temp_mr_matchQty
                    select @temp_mc_matchQty = @v_matchQty
                  ELSE
                    select @temp_mc_matchQty = @temp_mr_matchQty

                  select @v_matchQty = @v_matchQty - @temp_mc_matchQty

                  IF @temp_mc_matchQty < @temp_mr_matchQty
                    begin
                      select @temp_mc_costChgAmt = round(@temp_mc_matchQty * @temp_mr_per_costChgAmt, 2)
                    end
                  ELSE
                    begin
                      select @temp_mc_costChgAmt = @temp_mr_costChgAmt
                    end

                  IF @temp_mc_matchQty != @temp_mr_matchQty
                    select @temp_mr_costChgAmt = round(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)

                  select @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt

                  select @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt

                  select @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt


                  update #tt_cellcreatePosiDateSum set posiQty = posiQty - @temp_mc_matchQty, costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestOperateDate = @v_settleDate
                         where exchangeCode = @v_exchangeCode AND dbo.fnGetOriginSecuCode(exchangeCode, secuCode) = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode 
                               AND currencyCode = @v_currencyCode AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                   --申购中签转出记录 '1071','新股上市转出'
                   --'非流通股'                                               
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, '1071' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          -1 * @temp_mc_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit                           

                   --新股上市
                   select @v_createPosiDate = null

                   select @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate 
                     from #tt_cellcreatePosiDateSum
						         where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   IF @v_createPosiDate is null
                     begin
                       insert #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                         select @v_exchangeCode, @v_secuCode, @temp_mr_prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @temp_mc_matchQty, @temp_mr_costChgAmt, @v_settleDate

                        select @v_createPosiDate = @v_settleDate
                      end
                    ELSE
                      begin
                        update #tt_cellcreatePosiDateSum set createPosiDate = @v_createPosiDate, posiQty = posiQty + @temp_mc_matchQty, costChgAmt = costChgAmt + @temp_mr_costChgAmt, lastestOperateDate = @v_settleDate
                               where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      end

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)            
                   --'流通股'                                                   
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, '1072' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @temp_mc_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
                  end
              ELSE -- 找不到对应的记录
                begin
                  select @v_createPosiDate = null
                  select @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate from #tt_cellcreatePosiDateSum
                         where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode
                   IF @v_createPosiDate is null
                     begin
                       insert #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                         select @v_exchangeCode, @v_secuCode, @v_fundAcctCode as prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate

                       select @v_createPosiDate = @v_settleDate
                      end
                    ELSE
                      begin
                        update #tt_cellcreatePosiDateSum set createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + 0, lastestOperateDate = @v_settleDate
                               where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      end

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, '1071' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @v_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          0 AS costChgAmt, 0, 0 AS rlzChgProfit 
                    break
                end
            end
          set rowcount 0
        end  
    */
    --买入处理
    
    ELSE IF @v_buySellFlagCode = '1' AND @v_openCloseFlagCode = '1' AND @v_secuBizTypeCode != '183' AND @v_secuBizTypeCode != '187' AND @v_secuBizTypeCode != '188'     
    BEGIN
    SELECT  @v_createPosiDate  = null                        --建仓日期
    SELECT @v_posiQty = null                                 --持仓数量
    SELECT @v_lastsettleDate = null                          --最后建仓日期

    SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastsettleDate = lastestOperateDate FROM #tt_cellcreatePosiDateSum
           WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode; 
      
     IF @v_createPosiDate is null
     BEGIN     
				  INSERT INTO #tt_cellcreatePosiDateSum(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                 VALUES(@v_exchangeCode, @v_secuCode, @v_prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate);
          SELECT @v_createPosiDate = @v_settleDate   
     END
     ELSE IF @v_posiQty <= 0 AND @v_lastsettleDate != @v_settleDate
     BEGIN
			  UPDATE #tt_cellcreatePosiDateSum SET createPosiDate = @v_settleDate,
                                                      posiQty = @v_matchQty,
                                                   costChgAmt = @v_costChgAmt,
                                           lastestOperateDate = @v_settleDate
                                         WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                               AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
     END
     ELSE
			BEGIN
			UPDATE #tt_cellcreatePosiDateSum SET createPosiDate = @v_createPosiDate,
                                                      posiQty = posiQty + @v_matchQty,
                                                   costChgAmt = costChgAmt + @v_costChgAmt,
                                                 lastestOperateDate = @v_settleDate
                                               WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
			END
			
			   INSERT INTO #tt_prodCellCheckJrnlES (serialNO, createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                                costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                         VALUES(@v_serialNO, @v_createPosiDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode,@v_prodCode, @v_investPortfolioCode,
                                                @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                                @v_secuTradeTypeCode, @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode, @v_currencyCode,
                                                @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                                                @v_costChgAmt,@v_costChgAmt, @v_rlzChgProfit);
			END			
--买入处理END

--卖出处理BEGIN
ELSE IF @v_buySellFlagCode = '1' AND @v_openCloseFlagCode = 'A' AND @v_secuBizTypeCode != '183' AND @v_secuBizTypeCode != '187' AND @v_secuBizTypeCode != '188'
BEGIN
  SELECT @v_costChgAmt = ISNULL(ROUND(@v_costChgAmt, 2),0)
	SELECT @temp_mc_per_costChgAmt = @v_costChgAmt / @v_matchQty
  SELECT @temp_mc_per_rlzChgProfit = @v_rlzChgProfit / @v_matchQty
  SELECT @temp_mc_per_cashCurrSettleAmt = @v_cashCurrentSettleAmt / @v_matchQty
  SELECT @temp_mc_per_matchTradeFeeAmt = @v_matchTradeFeeAmt / @v_matchQty
  WHILE @v_matchQty > 0  
  BEGIN
    SELECT @temp_mr_prodCellCode = NULL

			SELECT TOP 1
			  @temp_mr_prodCellCode = prodCellCode, @temp_mr_matchQty = posiQty, @temp_mr_costChgAmt = costChgAmt, @temp_mr_per_costChgAmt = costChgAmt / posiQty, @temp_mr_createPosiDate = createPosiDate
				FROM #tt_cellcreatePosiDateSum
				WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND posiQty > 0
				ORDER BY createPosiDate
			--找到相应的买入处理开始	
			IF @temp_mr_prodCellCode IS NOT NULL
				BEGIN	

			        IF @temp_mr_matchQty > @v_matchQty 
                  SELECT @temp_mc_matchQty = @v_matchQty;
                ELSE
                  SELECT @temp_mc_matchQty = @temp_mr_matchQty;         
               SELECT @v_matchQty = @v_matchQty - @temp_mc_matchQty

                IF @v_matchQty != 0 
									BEGIN
                    SELECT @temp_mc_costChgAmt = ROUND(@temp_mc_matchQty * @temp_mc_per_costChgAmt, 2)
                    SELECT @temp_mc_cashCurrSettleAmt = ROUND(@temp_mc_matchQty * @temp_mc_per_cashCurrSettleAmt, 2)
                    SELECT @temp_mc_matchTradeFeeAmt = ROUND(@temp_mc_matchQty * @temp_mc_per_matchTradeFeeAmt, 2)
									END
                ELSE
									BEGIN
                  SELECT @temp_mc_costChgAmt = @v_costChgAmt;
                  SELECT @temp_mc_cashCurrSettleAmt = @v_cashCurrentSettleAmt
                  SELECT @temp_mc_matchTradeFeeAmt = @v_matchTradeFeeAmt 
                  END
                  
               IF @temp_mc_matchQty != @temp_mr_matchQty 
                  SELECT @temp_mr_costChgAmt = ROUND(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2);
                
                SELECT @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt
                SELECT @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt
                SELECT @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt
                SELECT @v_matchTradeFeeAmt = @v_matchTradeFeeAmt - @temp_mc_matchTradeFeeAmt
 
               
                UPDATE #tt_cellcreatePosiDateSum SET posiQty = posiQty - @temp_mc_matchQty,
                                              costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestOperateDate = @v_settleDate
                                        WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                                                
                INSERT INTO #tt_prodCellCheckJrnlES(serialNO, createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                                     exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, 
                                                     prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                                     matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                                     costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                              VALUES(@v_serialNO, @temp_mr_createPosiDate, @v_settleDate,@v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode,
                                                     @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                                     @v_secuTradeTypeCode, @temp_mr_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                                     -@temp_mc_matchQty, @v_matchNetPrice, @temp_mc_cashCurrSettleAmt, @temp_mc_matchTradeFeeAmt, @v_matchSettleAmt,
                                                     @temp_mr_costChgAmt, @temp_mc_cashCurrSettleAmt, @temp_mc_rlzChgProfit)                                           
          END --找到相应的买入处理结束
         ELSE --找不到对应的买入记录
                BEGIN
                DELETE #tt_cellcreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode
                INSERT INTO #tt_prodCellCheckJrnlES(serialNO, createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                                     exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, 
                                                     prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                                     matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                                     costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                              VALUES(@v_serialNO, @v_settleDate, @v_settleDate,@v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode,
                                                     @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                                     @v_secuTradeTypeCode, @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                                     -@v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                                     0, -@v_cashCurrentSettleAmt, -@v_costChgAmt)
                BREAK                                     
                END
  END
END
--卖出处理END

 ELSE IF @v_secuBizTypeCode = '183' OR @v_secuBizTypeCode = '187' OR @v_secuBizTypeCode = '188'
	BEGIN
		
		TRUNCATE TABLE #tt_cellPosiQtyDetial
    TRUNCATE TABLE #tt_cellPosiQtySum
    
     INSERT INTO #tt_cellPosiQtyDetial(createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
                                      SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(posiQty), 0, 0
                                        FROM #tt_cellCheckJrnl_old
                                       WHERE operateDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND currencyCode = @v_currencyCode 
                                             AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                                       GROUP BY prodCellCode
                                       HAVING SUM(posiQty) > 0
                                       
		INSERT INTO #tt_cellPosiQtyDetial(createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
														SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(matchQty), 0, 0
															FROM #tt_prodCellCheckJrnlES
														 WHERE occurDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND currencyCode = @v_currencyCode 
                                   AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
														 GROUP BY prodCellCode
														 HAVING SUM(matchQty) != 0
    
    INSERT INTO #tt_cellPosiQtySum(createPosiDate, prodCellCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                                   SELECT @v_settleDate, prodCellCode, SUM(posiQty), 0, 0, 0
                                     FROM #tt_cellPosiQtyDetial
                                     GROUP BY prodCellCode
                                     HAVING SUM(posiQty) > 0                                     
                             
   IF exists(SELECT 1 FROM #tt_cellPosiQtySum)
		BEGIN
			 SELECT @v_posiQty = SUM(posiQty) FROM #tt_cellPosiQtySum;
              UPDATE #tt_cellPosiQtySum SET matchQty = FLOOR(ROUND(posiQty / @v_posiQty * @v_matchQty, 4)),
                                           costChgAmt = ROUND(ROUND(posiQty / @v_posiQty * @v_costChgAmt, 4), 2),
                                           rlzChgProfit = ROUND(ROUND(posiQty / @v_posiQty * @v_rlzChgProfit, 4), 2)
              
              SELECT @v_matchQty = @v_matchQty - SUM(matchQty), @v_costChgAmt =  @v_costChgAmt - SUM(costChgAmt), @v_rlzChgProfit = @v_rlzChgProfit - SUM(rlzChgProfit)
                FROM #tt_cellPosiQtySum
                
                
    IF @v_matchQty != 0 OR @v_costChgAmt != 0 OR @v_rlzChgProfit != 0 
    BEGIN
                SELECT  TOP 1
                  @v_tempCellCode = prodCellCode
                
                
                 FROM #tt_cellPosiQtySum  ORDER BY matchQty DESC;
                UPDATE #tt_cellPosiQtySum SET matchQty = matchQty + @v_matchQty,
                                           costChgAmt = costChgAmt + @v_costChgAmt,
                                         rlzChgProfit = rlzChgProfit + @v_rlzChgProfit
                                   WHERE prodCellCode = @v_tempCellCode
      END
      
      MERGE INTO #tt_cellPosiQtySum a 
                     USING #tt_cellcreatePosiDateSum b ON (a.prodCellCode = b.prodCellCode AND b.exchangeCode = @v_exchangeCode AND b.secuCode = @v_secuCode 
                                                           AND a.currencyCode = b.currencyCode AND a.marketLevelCode = b.marketLevelCode AND a.hedgeFlagCode = b.hedgeFlagCode 
                                                           AND a.longShortFlagCode = b.longShortFlagCode)
                      WHEN MATCHED THEN UPDATE SET a.createPosiDate = b.createPosiDate;
                      
      MERGE INTO #tt_cellcreatePosiDateSum a
                     USING #tt_cellPosiQtySum b ON (a.prodCellCode = b.prodCellCode AND a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode 
                                                    AND a.currencyCode = @v_currencyCode AND a.marketLevelCode = @v_marketLevelCode AND a.hedgeFlagCode = @v_hedgeFlagCode 
                                                    AND a.longShortFlagCode = @v_longShortFlagCode)
                      WHEN MATCHED THEN UPDATE SET a.posiQty = a.posiQty + b.matchQty,
                                                   a.costChgAmt = a.costChgAmt + b.costChgAmt,
                                                   a.createPosiDate = CASE WHEN a.posiQty <= 0 THEN b.createPosiDate ELSE a.createPosiDate END;		
		END
			ELSE 
		   BEGIN
				IF exists(SELECT 1 FROM #tt_cellcreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCode)
				UPDATE #tt_cellcreatePosiDateSum SET posiQty = posiQty + @v_matchQty 
				WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCode AND currencyCode = @v_currencyCode 
              AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  
				
				ELSE

			  INSERT INTO #tt_cellcreatePosiDateSum(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                              VALUES(@v_exchangeCode, @v_secuCode, @v_prodCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate)
                                              		   
		    INSERT INTO #tt_cellPosiQtySum(createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                                              VALUES(@v_settleDate, @v_prodCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, 0, @v_matchQty, 0, -@v_costChgAmt + @v_rlzChgProfit)
		   END
		   
		   INSERT INTO #tt_prodCellCheckJrnlES(serialNO, createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                               exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, 
                                               prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                               matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                               costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                        SELECT @v_serialNO, @v_createPosiDate, @v_settleDate,@v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode,
                                               @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                               @v_secuTradeTypeCode, prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                               matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                               costChgAmt, -(costChgAmt - rlzChgProfit), rlzChgProfit
                                          FROM #tt_cellPosiQtySum
	END

  FETCH for_mccjb INTO @v_serialNO, @v_orderID, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode, 
                       @v_exchangeCode, @v_secuCode, @v_originSecuCode,@v_secuName, @v_secuTradeTypeCode, @v_longShortFlagCode,
                       @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_currencyCode, @v_hedgeFlagCode, 
                       @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                       @v_costChgAmt, @v_rlzChgProfit

    END
        
  CLOSE for_mccjb
  DEALLOCATE for_mccjb
 
 RETURN 0
go

--exec opCalcProdCellCheckJrnlES '','','','','','','2017-03-17'
--exec opCalcProdCellCheckJrnlES '','','','','','','2017-03-15' 出错
--SELECT * FROM secuBizType WHERE secuBizTypeName LIKE '配股%'

