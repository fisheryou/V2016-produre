USE sims2016Proc
go

IF OBJECT_ID(N'ipTransformToES', N'P') IS NOT NULL
  DROP PROC ipTransformToES
go

CREATE PROC ipTransformToES
  @i_operatorCode       VARCHAR(30),      
  @i_operatorPassword   VARCHAR(30),      
  @i_operateStationText VARCHAR(600),     
  @i_fundAcctCode       VARCHAR(30),
  @i_beginDate          VARCHAR(10),
  @i_endDate            VARCHAR(10)
AS  
  
  DECLARE @findRow INT, @todayDate VARCHAR(10), @coveredFlagCode VARCHAR(30) = '1', @dataSourceFlagCode VARCHAR(30) = '0'

  SELECT @findRow = COUNT(serialNO) FROM #brokerRawJrnlDealSecuHist
  IF @@ROWCOUNT = 0
    RETURN

  --取只有一个产品单元的产品及投资组合信息
  SELECT a.prodCode, MAX(a.prodCellCode) AS prodCellCode, MAX(b.investPortfolioCode) AS investPortfolioCode
         INTO #defaultProdCellPortfolio
         FROM sims2016TradeToday..prodCell a
         JOIN sims2016TradeToday..investPortfolio b ON a.prodCode = b.prodCode AND a.prodCellCode = b.prodCellCode
         JOIN #prodCapitalES c ON a.prodCode = c.prodCode
         GROUP BY a.prodCode
         HAVING COUNT(a.prodCode) = 1
  --取委托
  SELECT a.orderNO, a.tradeDate, MAX(a.tradeTime) AS tradeTime, MAX(a.investInstrucNO) AS investInstrucNO, MAX(a.traderInstrucNO) AS traderInstrucNO,
         a.prodCode, a.prodCellCode, a.fundAcctCode, a.currencyCode, a.exchangeCode, a.secuCode, a.secuAcctCode,
         MAX(a.secuTradeTypeCode) AS secuTradeTypeCode, a.hedgeFlagCode,
         MAX(a.marketLevelCode) AS marketLevelCode, MAX(a.investPortfolioCode) AS investPortfolioCode,
         MAX(a.assetLiabilityTypeCode) AS assetLiabilityTypeCode, MAX(a.transactionNO) AS transactionNO,
         MAX(a.orderNetAmt) AS orderNetAmt, MAX(a.orderNetPrice) AS orderNetPrice,
         MAX(a.orderQty) AS orderQty, MAX(a.orderSettleAmt) AS orderSettleAmt,
         MAX(a.orderSettlePrice) AS orderSettlePrice, MAX(a.orderTradeFeeAmt) AS orderTradeFeeAmt,
         MAX(a.traderCode) AS traderCode, a.brokerOrderID,
         a.brokerOriginOrderID, MAX(a.brokerErrorMsg) AS brokerErrorMsg,
         CASE WHEN a.brokerOrderID != '' then 'A' + a.brokerOrderID
              WHEN a.brokerOriginOrderID != '' then 'B' + a.brokerOriginOrderID
              ELSE  '' END AS brokerOrderID_compare--,
         --CASE WHEN SIGN(a.cashAvailableChgAmt) < 0 then -1 ELSE 1 END AS cashCurrentSettleAmt_sign
         into #prodCellOrderESHist
         FROM sims2016TradeHist..prodCellOrderESHist a
         JOIN #prodCapitalES b ON a.fundAcctCode = b.fundAcctCode
         WHERE a.tradeDate BETWEEN @i_beginDate AND @i_endDate
           AND a.orderWithdrawFlagCode = '1' --委托
           AND (RTRIM(a.brokerOrderID) != '')
         GROUP BY a.orderNO, a.tradeDate, a.prodCode, a.prodCellCode, a.fundAcctCode, a.currencyCode, a.exchangeCode, a.secuCode, a.secuAcctCode,
                  a.hedgeFlagCode, a.brokerOrderID, a.brokerOriginOrderID--, SIGN(a.cashAvailableChgAmt)
         HAVING COUNT(a.orderNO) = 1

  SELECT a.operateDate, a.brokerSecuBizTypeCode, a.originSecuBizTypeCode, a.secuBizTypeCode,
         a.brokerJrnlSerialID,
         ISNULL(c.secuBizTypeName, brokerSecuBizTypeCode) AS brokerSecuBizTypeName,
         a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode, a.prodCode,
         ISNULL(ISNULL(b.prodCellCode, d.prodCellCode), a.prodCode) AS prodCellCode, a.fundAcctCode, a.currencyCode,
         a.cashSettleAmt, a.cashBalanceAmt, a.exchangeCode, a.secuCode, a.originSecuCode, a.secuName, a.secuTradeTypeCode,
         CASE WHEN c.buySellFlagCode = '' then a.matchQty
              WHEN c.posiDirectFlagValue > 0 then ABS(a.matchQty)
              WHEN c.posiDirectFlagValue < 0 then -ABS(a.matchQty)
              ELSE a.matchQty END AS matchQty,
         a.matchNetPrice, a.posiBalanceQty,
         CASE WHEN c.buySellFlagCode = '' then a.matchSettleAmt
              WHEN c.cashDirectFlagValue > 0 then ABS(a.matchSettleAmt)
              WHEN c.cashDirectFlagValue < 0 then -ABS(a.matchSettleAmt)
              ELSE a.matchSettleAmt END AS matchNetAmt,
         a.stampTaxAmt, a.commissionFeeAmt, a.transferFeeAmt, a.otherFeeAmt,
         a.stampTaxAmt + a.commissionFeeAmt + a.transferFeeAmt + a.otherFeeAmt AS matchTradeFeeAmt,
         a.matchDate, a.matchTime, a.matchID,
         a.secuAcctCode, a.brokerOrderID, a.brokerOriginOrderID, a.brokerOrderID_compare, a.operateRemarkText,
         a.marketLevelCode,
         --委托字段信息
         ISNULL(b.orderNO, 0) AS orderNO, ISNULL(b.investInstrucNO, 0) AS investInstrucNO, ISNULL(b.traderInstrucNO, 0) AS traderInstrucNO,
         CASE WHEN ISNULL(b.prodCellCode, d.prodCellCode) = d.prodCellCode then ISNULL(d.investPortfolioCode, ' ')
              ELSE ISNULL(b.investPortfolioCode, ' ') END AS investPortfolioCode,
         ISNULL(b.orderQty, 0) AS orderQty, ISNULL(b.orderNetPrice, 0) AS orderNetPrice, ISNULL(b.orderNetAmt, 0) AS orderNetAmt,
         ISNULL(b.orderSettleAmt, 0) AS orderSettleAmt, ISNULL(b.orderSettlePrice, 0) AS orderSettlePrice, ISNULL(b.orderTradeFeeAmt, 0) AS orderTradeFeeAmt,
         ISNULL(b.tradeTime, '') AS tradeTime,
         ISNULL(b.traderCode, '') AS traderCode, ISNULL(b.transactionNO, 0) AS transactionNO, ISNULL(b.assetLiabilityTypeCode, '0') AS assetLiabilityTypeCode,
         ISNULL(b.hedgeFlagCode, '1') AS hedgeFlagCode, ISNULL(b.brokerErrorMsg, '') AS brokerErrorMsg
         INTO #dataSyncRawJrnlES
         FROM #brokerRawJrnlDealSecuHist a
         LEFT JOIN #prodCellOrderESHist b ON a.operateDate = b.tradeDate AND
                                             a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode AND
                                             a.exchangeCode = b.exchangeCode AND a.secuCode = b.secuCode AND
                                             a.secuAcctCode = b.secuAcctCode AND
                                             a.brokerOrderID_compare = b.brokerOrderID_compare
         LEFT JOIN sims2016TradeToday..secuBizType c ON a.secuBizTypeCode = c.secuBizTypeCode
         LEFT JOIN #defaultProdCellPortfolio d ON a.prodCode = d.prodCode

  --产品资金证券流水当日总流水表
  DELETE FROM sims2016TradeToday..prodRawJrnlToday WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                     AND settleDate >= @todayDate
                                                     AND dataSourceFlagCode = '0'

  INSERT sims2016TradeToday..prodRawJrnlToday(settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, coveredFlagCode,
                                              originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, prodCode, fundAcctCode,
                                              currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName,
                                              secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode,
                                              operateDatetime, operateRemarkText)
                                        SELECT operateDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, @coveredFlagCode,
                                              originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, a.prodCode, a.fundAcctCode,
                                              a.currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName,
                                              secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, @dataSourceFlagCode, marketLevelCode,
                                              GETDATE(), operateRemarkText
                                              FROM #dataSyncRawJrnlES a
                                              JOIN #prodCapitalES b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
                                              WHERE a.operateDate >= @todayDate

  --产品资金证券流水历史总流水表
  DELETE FROM sims2016TradeHist..prodRawJrnlHist WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                   AND settleDate BETWEEN @i_beginDate AND @i_endDate
                                                   AND dataSourceFlagCode = '0'

  INSERT sims2016TradeHist..prodRawJrnlHist(settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, coveredFlagCode,
                                            originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, prodCode, fundAcctCode,
                                            currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName,
                                            secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode,
                                            operateDatetime, operateRemarkText)
                                      SELECT operateDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, @coveredFlagCode,
                                            originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, a.prodCode, a.fundAcctCode,
                                            a.currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName,
                                            secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, @dataSourceFlagCode, marketLevelCode,
                                            GETDATE(), operateRemarkText
                                            FROM #dataSyncRawJrnlES a
                                            JOIN #prodCapitalES b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
                                            where a.operateDate < @todayDate
                                              AND a.operateDate BETWEEN @i_beginDate AND @i_endDate

--产品资金证券流水表股票当日(纯交易流水)
  DELETE FROM sims2016TradeToday..prodRawJrnlESToday WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                       AND settleDate >= @todayDate
                                                       AND dataSourceFlagCode = '0'
  
  INSERT sims2016TradeToday..prodRawJrnlESToday(serialNO, settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
                                                originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, prodCode, prodCellCode,
                                                fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode,
                                                secuName, secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode, matchSettleAmt,
                                                matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID, brokerOriginOrderID, brokerErrorMsg, transactionNO, investPortfolioCode,
                                                assetLiabilityTypeCode, investInstrucNO, traderInstrucNO, orderNO, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt, orderSettlePrice,
                                                orderTradeFeeAmt, directorCode, traderCode, operatorCode, operateDatetime, operateRemarkText)
                                          SELECT c.serialNO, a.operateDate, a.secuBizTypeCode, a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode, a.hedgeFlagCode,
                                                a.originSecuBizTypeCode, a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName, a.brokerJrnlSerialID, a.prodCode, a.prodCellCode,
                                                a.fundAcctCode, a.currencyCode, a.cashSettleAmt, a.cashBalanceAmt, a.exchangeCode, a.secuAcctCode, a.secuCode, a.originSecuCode,
                                                a.secuName, a.secuTradeTypeCode, a.matchQty, a.posiBalanceQty, a.matchNetPrice, @dataSourceFlagCode, a.marketLevelCode, a.matchNetAmt,
                                                a.matchTradeFeeAmt, a.matchDate, a.matchTime, a.matchID, a.brokerOrderID, a.brokerOriginOrderID, a.brokerErrorMsg, a.transactionNO, ISNULL(a.investPortfolioCode, ' '),
                                                a.assetLiabilityTypeCode, a.investInstrucNO, a.traderInstrucNO, a.orderNO, a.orderNetAmt, a.orderNetPrice, a.orderQty, a.orderSettleAmt, a.orderSettlePrice,
                                                a.orderTradeFeeAmt, '', a.traderCode, '', GETDATE(), a.operateRemarkText
                                                FROM #dataSyncRawJrnlES a
                                                JOIN #prodCapitalES b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
                                                JOIN sims2016TradeToday..prodRawJrnlToday c ON a.operateDate = c.settleDate AND a.prodCode = c.prodCode AND a.fundAcctCode = c.fundAcctCode AND a.brokerJrnlSerialID = c.brokerJrnlSerialID
                                                where a.operateDate >= @todayDate
                                                  AND a.secuBizTypeCode NOT IN('8001', '8002', '8003', '8004')
  
  --产品资金证券流水表股票历史(纯交易流水)
  DELETE FROM sims2016TradeHist..prodRawJrnlESHist WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                     AND settleDate BETWEEN @i_beginDate AND @i_endDate
                                                     AND dataSourceFlagCode = '0'

  INSERT sims2016TradeHist..prodRawJrnlESHist(serialNO, settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
                                              originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, prodCode, prodCellCode,
                                              fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode,
                                              secuName, secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode, matchSettleAmt,
                                              matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID, brokerOriginOrderID, brokerErrorMsg, transactionNO, investPortfolioCode,
                                              assetLiabilityTypeCode, investInstrucNO, traderInstrucNO, orderNO, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt, orderSettlePrice,
                                              orderTradeFeeAmt, directorCode, traderCode, operatorCode, operateDatetime, operateRemarkText)
                                       SELECT c.serialNO, a.operateDate, a.secuBizTypeCode, a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode, a.hedgeFlagCode,
                                              a.originSecuBizTypeCode, a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName, a.brokerJrnlSerialID, a.prodCode, a.prodCellCode,
                                              a.fundAcctCode, a.currencyCode, a.cashSettleAmt, a.cashBalanceAmt, a.exchangeCode, a.secuAcctCode, a.secuCode, a.originSecuCode,
                                              a.secuName, a.secuTradeTypeCode, a.matchQty, a.posiBalanceQty, a.matchNetPrice, @dataSourceFlagCode, a.marketLevelCode, a.matchNetAmt,
                                              a.matchTradeFeeAmt, a.matchDate, a.matchTime, a.matchID, a.brokerOrderID, a.brokerOriginOrderID, a.brokerErrorMsg, a.transactionNO, ISNULL(a.investPortfolioCode, ' '),
                                              a.assetLiabilityTypeCode, a.investInstrucNO, a.traderInstrucNO, a.orderNO, a.orderNetAmt, a.orderNetPrice, a.orderQty, a.orderSettleAmt, a.orderSettlePrice,
                                              a.orderTradeFeeAmt, '', a.traderCode, '', GETDATE(), a.operateRemarkText
                                              FROM #dataSyncRawJrnlES a
                                              JOIN #prodCapitalES b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
                                              JOIN sims2016TradeHist..prodRawJrnlHist c ON a.operateDate = c.settleDate AND a.prodCode = c.prodCode AND a.fundAcctCode = c.fundAcctCode AND a.brokerJrnlSerialID = c.brokerJrnlSerialID
                                              where a.operateDate < @todayDate
                                                AND a.secuBizTypeCode NOT IN('8001', '8002', '8003', '8004')
                                                AND a.operateDate BETWEEN @i_beginDate AND @i_endDate

  --生成单元资金证券股票流水
  EXEC ipCalcProdCellRawJrnlES @i_fundAcctCode, @i_beginDate, @i_endDate
go

