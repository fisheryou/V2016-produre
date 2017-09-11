USE sims2016Proc
go
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'opMoveQuotaDataTodayToHist')
	DROP PROC opMoveQuotaDataTodayToHist
go

CREATE PROC opMoveQuotaDataTodayToHist
(
  @o_errorMsgCode          INT              OUT,
  @o_errorMsgText          VARCHAR(255)     OUT,
  @i_operatorCode          VARCHAR(255),       --操作员代码
  @i_operatorPassword      VARCHAR(255),       --操作员密码
  @i_operateStationText    VARCHAR(2048),      --操作员网卡信息
  @i_latestTradeDate       CHAR(10)            --最近交易日
  )
AS
/*
名称: opMoveQuotaDataTodayToHist
功能: 将当日(期货/现货)行情搬移到历史行情(期货/现货)
==================================================================================================
Author:yugy
Version:1.0
Date：2017-04-10
Description：将期货/现货当日基本行情分别迁移到期货/现货基本历史行情和期货/现货持仓历史行情中
History：

==================================================================================================
NOTE：
*/
SET NOCOUNT ON
-- 删除历史行情表的行情日期在当日表中存在的数据(将历史行情中的上一个交易日的数据[错误数据]删除)
    DELETE FROM sims2016QuotaHist..primaryQuotaESHist WHERE quotaDate = @i_latestTradeDate
    -- 将当日行情表数据全部插入到历史行情表中
    INSERT INTO sims2016QuotaHist..primaryQuotaESHist(quotaDate       , -- 行情日期YYYY-MM-DD    
                                       quotaTime       , -- 行情时间HH:MM:SS.SSS  
                                       exchangeCode        , -- 交易所代码             
                                       secuCode        , -- 证券代码              
                                       secuStatusCode  , -- 证券状态代码            
                                       prevIOPVValue       , -- 昨日IOPV            
                                       prevDeltaValue      , -- 昨日虚实度             
                                       prevClosePrice      , -- 昨日收盘价             
                                       prevTotalLongPosiQty, -- 昨日持仓量             
                                       openPrice           , -- 开盘价               
                                       highestPrice        , -- 最高价               
                                       lowestPrice         , -- 最低价               
                                       lastestPrice        , -- 最新价               
                                       iopvValue           , -- IOPV              
                                       deltaValue          , -- 虚实度               
                                       closePrice          , -- 收盘价               
                                       totalLongPosiQty    , -- 持仓量               
                                       totalMatchQty       , -- 成交数量              
                                       totalTickCount      , -- 成交笔数              
                                       totalMatchAmt       , -- 成交金额              
                                       callOnePrice        , -- 买1价格              
                                       callOneQty          , -- 买1数量              
                                       putOnePrice         , -- 卖1价格              
                                       putOneQty)            -- 卖1数量 
                                SELECT quotaDate       , -- 行情日期YYYY-MM-DD
                                       quotaTime       , -- 行情时间HH:MM:SS.SSS
                                       exchangeCode        , -- 交易所代码
                                       secuCode        , -- 证券代码
                                       secuStatusCode  , -- 证券状态代码
                                       prevIOPVValue       , -- 昨日IOPV
                                       prevDeltaValue      , -- 昨日虚实度
                                       prevClosePrice      , -- 昨日收盘价
                                       prevTotalLongPosiQty, -- 昨日持仓量
                                       openPrice           , -- 开盘价
                                       highestPrice        , -- 最高价
                                       lowestPrice         , -- 最低价
                                       lastestPrice        , -- 最新价
                                       iopvValue           , -- IOPV
                                       deltaValue          , -- 虚实度
                                       closePrice          , -- 收盘价
                                       totalLongPosiQty    , -- 持仓量
                                       totalMatchQty       , -- 成交数量
                                       totalTickCount      , -- 成交笔数
                                       totalMatchAmt       , -- 成交金额
                                       callOnePrice        , -- 买1价格
                                       callOneQty          , -- 买1数量
                                       putOnePrice         , -- 卖1价格
                                       putOneQty             -- 卖1数量     
                                  FROM sims2016QuotaToday..primaryQuotaESToday
                                 WHERE quotaDate = @i_latestTradeDate;  --当日行情表有非上一交易日的数据，不做处理
                                 
                                 
    -- 删除历史行情表的行情日期在当日表中存在的数据(将历史行情中的上一个交易日的数据[错误数据]删除)
    DELETE FROM sims2016QuotaHist..primaryQuotaFHist WHERE quotaDate = @i_latestTradeDate
    -- 将当日行情表数据全部插入到历史行情表中
    INSERT INTO sims2016QuotaHist..primaryQuotaFHist(quotaDate       , -- 行情日期YYYY-MM-DD   
                                      quotaTime       , -- 行情时间HH:MM:SS.SSS 
                                      exchangeCode        , -- 交易所代码            
                                      secuCode        , -- 证券代码             
                                      secuStatusCode  , -- 证券状态代码           
                                      prevIOPVValue       , -- 昨日IOPV           
                                      prevDeltaValue      , -- 昨日虚实度            
                                      prevClosePrice      , -- 昨日收盘价            
                                      prevSettlePrice     , -- 昨日结算价            
                                      prevTotalLongPosiQty, -- 昨日持仓量            
                                      lowerLimitPrice     , -- 行情跌停价格           
                                      upperLimitPrice     , -- 行情涨停价格           
                                      openPrice           , -- 开盘价              
                                      highestPrice        , -- 最高价              
                                      lowestPrice         , -- 最低价              
                                      lastestPrice        , -- 最新价              
                                      iopvValue           , -- IOPV             
                                      deltaValue          , -- 虚实度              
                                      closePrice          , -- 收盘价              
                                      settlePrice         , -- 结算价              
                                      totalLongPosiQty    , -- 持仓量              
                                      totalMatchQty       , -- 成交数量             
                                      totalTickCount      , -- 成交笔数             
                                      totalMatchAmt       , -- 成交金额             
                                      callOnePrice        , -- 买1价格             
                                      callOneQty          , -- 买1数量             
                                      putOnePrice         , -- 卖1价格             
                                      putOneQty)            -- 卖1数量    
                               SELECT quotaDate       , -- 行情日期YYYY-MM-DD   
                                      quotaTime       , -- 行情时间HH:MM:SS.SSS 
                                      exchangeCode        , -- 交易所代码            
                                      secuCode        , -- 证券代码             
                                      secuStatusCode  , -- 证券状态代码           
                                      prevIOPVValue       , -- 昨日IOPV           
                                      prevDeltaValue      , -- 昨日虚实度            
                                      prevClosePrice      , -- 昨日收盘价            
                                      prevSettlePrice     , -- 昨日结算价            
                                      prevTotalLongPosiQty, -- 昨日持仓量            
                                      lowerLimitPrice     , -- 行情跌停价格           
                                      upperLimitPrice     , -- 行情涨停价格           
                                      openPrice           , -- 开盘价              
                                      highestPrice        , -- 最高价              
                                      lowestPrice         , -- 最低价              
                                      lastestPrice        , -- 最新价              
                                      iopvValue           , -- IOPV             
                                      deltaValue          , -- 虚实度              
                                      closePrice          , -- 收盘价              
                                      settlePrice         , -- 结算价              
                                      totalLongPosiQty    , -- 持仓量              
                                      totalMatchQty       , -- 成交数量             
                                      totalTickCount      , -- 成交笔数             
                                      totalMatchAmt       , -- 成交金额             
                                      callOnePrice        , -- 买1价格             
                                      callOneQty          , -- 买1数量             
                                      putOnePrice         , -- 卖1价格             
                                      putOneQty             -- 卖1数量   
                                 FROM sims2016QuotaToday..primaryQuotaFToday
                                WHERE quotaDate = @i_latestTradeDate; --当日行情表有非上一交易日的数据，不做处理
                                
          --将历史行情中的上一个交易日的数据[错误数据]删除
    DELETE FROM sims2016QuotaHist..posiQuotaESHist WHERE quotaDate = @i_latestTradeDate
   --将当日行情表部分数据插入到持仓历史行情表中
    INSERT INTO sims2016QuotaHist..posiQuotaESHist(quotaDate       , -- 行情日期YYYY-MM-DD
                                    exchangeCode        , -- 交易所代码
                                    secuCode        , -- 证券代码
                                    prevClosePrice      , -- 昨日收盘价
                                    openPrice           , -- 开盘价
                                    highestPrice        , -- 最高价
                                    lowestPrice         , -- 最低价
                                    lastestPrice        , -- 最新价
                                    closePrice)           -- 收盘价
                             SELECT quotaDate       , -- 行情日期YYYY-MM-DD                                   
                                    p.exchangeCode      , -- 交易所代码
                                    p.secuCode      , -- 证券代码  
                                    prevClosePrice      , -- 昨日收盘价
                                    openPrice           , -- 开盘价
                                    highestPrice        , -- 最高价
                                    lowestPrice         , -- 最低价
                                    lastestPrice        , -- 最新价
                                    closePrice            -- 收盘价    
                               FROM sims2016QuotaToday..primaryQuotaESToday p
                               INNER JOIN(SELECT DISTINCT exchangeCode,secuCode FROM sims2016TradeToday..prodCellPosiES) b
                                  ON quotaDate = @i_latestTradeDate AND p.exchangeCode = b.exchangeCode AND p.secuCode = b.secuCode;  --1.当日行情表有非上一交易日的数据，不做处理 2.不在产品单元持仓表的证券，不处理
                                  
                                  --将历史行情中的上一个交易日的数据[错误数据]删除
    DELETE FROM sims2016QuotaHist..posiQuotaFHist WHERE quotaDate = @i_latestTradeDate;
  --将当日行情表部分数据插入到持仓历史行情表中
    INSERT INTO sims2016QuotaHist..posiQuotaFHist(quotaDate       , -- 行情日期YYYY-MM-DD                                     
                                   exchangeCode        , -- 交易所代码            
                                   secuCode        , -- 证券代码                                                         
                                   prevClosePrice      , -- 昨日收盘价            
                                   prevSettlePrice     , -- 昨日结算价                
                                   openPrice           , -- 开盘价              
                                   highestPrice        , -- 最高价              
                                   lowestPrice         , -- 最低价              
                                   lastestPrice        , -- 最新价                                              
                                   closePrice          , -- 收盘价              
                                   settlePrice)          -- 结算价              
                            SELECT quotaDate       , -- 行情日期YYYY-MM-DD                                       
                                   p.exchangeCode      , -- 交易所代码            
                                   p.secuCode      , -- 证券代码                                                         
                                   prevClosePrice      , -- 昨日收盘价            
                                   prevSettlePrice     , -- 昨日结算价                      
                                   openPrice           , -- 开盘价              
                                   highestPrice        , -- 最高价              
                                   lowestPrice         , -- 最低价              
                                   lastestPrice        , -- 最新价                       
                                   closePrice          , -- 收盘价              
                                   settlePrice           -- 结算价                                    
                              FROM sims2016QuotaToday..primaryQuotaFToday p
                              INNER JOIN(SELECT DISTINCT exchangeCode,secuCode FROM sims2016TradeToday..prodCellPosiF) b
                              ON quotaDate = @i_latestTradeDate AND p.exchangeCode = b.exchangeCode AND p.secuCode = b.secuCode;  ----1.当日行情表有非上一交易日的数据，不做处理 2.不在产品单元持仓表的证券，不处理
  select @o_errorMsgCode = 0, @o_errorMsgText = '行情初始化成功'
  RETURN 0
go
