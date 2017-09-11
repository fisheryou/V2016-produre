USE sims2016Proc
go

IF OBJECT_ID(N'ipCalcProdCellRawJrnlF', N'P') IS NOT NULL
  DROP PROC ipCalcProdCellRawJrnlF
go

CREATE PROC ipCalcProdCellRawJrnlF
  @i_fundAcctCode           VARCHAR(30),
  @i_beginDate              VARCHAR(10),
  @i_endDate                VARCHAR(10)
AS
  DECLARE @todayDate VARCHAR(10)

  SELECT @todayDate = CONVERT(VARCHAR(10), GETDATE(), 120)

  IF @i_beginDate >= @todayDate
    BEGIN
      DELETE sims2016TradeToday..prodCellRawJrnlToday
             WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
               AND settleDate BETWEEN @i_beginDate AND @i_endDate
               AND dataSourceFlagCode = '0'
               AND secuTradeTypeCode LIKE 'F%' --只负责处理期货交易流水
               AND secuBizTypeCode NOT IN('181', '182', '183', '184', '185', '186', '187', '188', '605', '606',
                                          '8041', '8001', '8002', '8003', '8004')
      --单元资金证券总流水表当日
      INSERT sims2016TradeToday..prodCellRawJrnlToday(originSerialNO, settleDate, secuBizTypeCode, buySellFlagCode,
                                                      bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, coveredFlagCode,
                                                      originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID,
                                                      prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt,
                                                      exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty,
                                                      posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode,
                                                      operatorCode, operateDatetime, operateRemarkText)
                                               SELECT serialNO, settleDate, secuBizTypeCode, buySellFlagCode,
                                                      bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, '0' AS coveredFlagCode,
                                                      originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID,
                                                      prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt,
                                                      exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty,
                                                      posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode,
                                                      operatorCode, operateDatetime, operateRemarkText 
                                                      FROM sims2016TradeToday..prodRawJrnlFToday
                                                      WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                        AND prodCode != prodCellCode
                                                        AND settleDate BETWEEN @i_beginDate AND @i_endDate
                                                        AND secuBizTypeCode NOT IN('605', '606','8041', '8001', '8002', '8003', '8004')

      DELETE sims2016TradeToday..prodCellRawJrnlFToday
             WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
               AND settleDate BETWEEN @i_beginDate AND @i_endDate
               AND dataSourceFlagCode = '0'
               AND secuBizTypeCode NOT IN('605', '606', '8041', '8001', '8002', '8003', '8004')
      --单元资金证券流水表期货当日
      INSERT sims2016TradeToday..prodCellRawJrnlFToday(serialNO, settleDate, secuBizTypeCode, buySellFlagCode,
                                                        bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, originSecuBizTypeCode,
                                                        brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID,
                                                        prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt,
                                                        cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode,
                                                        secuName, secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice,
                                                        matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID,
                                                        brokerOriginOrderID, brokerErrorMsg, dataSourceFlagCode, transactionNO,
                                                        investPortfolioCode, assetLiabilityTypeCode, investInstrucNO, traderInstrucNO,
                                                        orderNO, marketLevelCode, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt,
                                                        orderSettlePrice, orderTradeFeeAmt, directorCode, traderCode,
                                                        operatorCode, operateDatetime, operateRemarkText)
                                                 SELECT a.serialNO, a.settleDate, a.secuBizTypeCode, a.buySellFlagCode,
                                                        a.bizSubTypeCode, a.openCloseFlagCode, a.hedgeFlagCode, a.originSecuBizTypeCode,
                                                        a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName, a.brokerJrnlSerialID,
                                                        a.prodCode, a.prodCellCode, a.fundAcctCode, a.currencyCode, a.cashSettleAmt,
                                                        a.cashBalanceAmt, a.exchangeCode, a.secuAcctCode, a.secuCode, a.originSecuCode,
                                                        a.secuName, a.secuTradeTypeCode, a.matchQty, a.posiBalanceQty, a.matchNetPrice,
                                                        matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID,
                                                        brokerOriginOrderID, brokerErrorMsg, a.dataSourceFlagCode, transactionNO,
                                                        investPortfolioCode, assetLiabilityTypeCode, investInstrucNO, traderInstrucNO,
                                                        orderNO, a.marketLevelCode, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt,
                                                        orderSettlePrice, orderTradeFeeAmt, directorCode, traderCode,
                                                        a.operatorCode, a.operateDatetime, a.operateRemarkText
                                                        FROM sims2016TradeToday..prodCellRawJrnlToday a
                                                        join sims2016TradeToday..prodRawJrnlFToday b on a.originSerialNO = b.serialNO
                                                        WHERE dbo.fnCharIndexDh(a.fundAcctCode, @i_fundAcctCode) > 0
                                                          AND a.prodCode != a.prodCellCode
                                                          AND a.secuTradeTypeCode LIKE 'F%' --只负责处理期货交易流水
                                                          AND a.settleDate BETWEEN @i_beginDate AND @i_endDate
                                                          AND a.secuBizTypeCode NOT IN('605', '606','8041', '8001', '8002', '8003', '8004')
    END

  IF @i_beginDate < @todayDate
    BEGIN
      DELETE sims2016TradeHist..prodCellRawJrnlHist
             WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
               AND settleDate BETWEEN @i_beginDate AND @i_endDate
               AND dataSourceFlagCode = '0'
               AND secuTradeTypeCode LIKE 'F%' --只负责处理期货交易流水
               AND secuBizTypeCode NOT IN('181', '182', '183', '184', '185', '186', '187', '188', '605', '606',
                                          '8041', '8001', '8002', '8003', '8004')
      --单元资金证券总流水表历史
      INSERT sims2016TradeHist..prodCellRawJrnlHist(originSerialNO, settleDate, secuBizTypeCode, buySellFlagCode,
                                                    bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, coveredFlagCode,
                                                    originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID,
                                                    prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt,
                                                    exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty,
                                                    posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode,
                                                    operatorCode, operateDatetime, operateRemarkText)
                                              SELECT serialNO, settleDate, secuBizTypeCode, buySellFlagCode,
                                                    bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, '0' AS coveredFlagCode,
                                                    originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID,
                                                    prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt,
                                                    exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty,
                                                    posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode,
                                                    operatorCode, operateDatetime, operateRemarkText 
                                                    FROM sims2016TradeHist..prodRawJrnlFHist
                                                    WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                      AND prodCode != prodCellCode
                                                      AND settleDate BETWEEN @i_beginDate AND @i_endDate
                                                      AND secuBizTypeCode NOT IN('605', '606','8041', '8001', '8002', '8003', '8004')

      DELETE sims2016TradeHist..prodCellRawJrnlFHist
             WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
               AND settleDate BETWEEN @i_beginDate AND @i_endDate
               AND dataSourceFlagCode = '0'
               AND secuBizTypeCode NOT IN('605', '606', '8041', '8001', '8002', '8003', '8004')
      --单元资金证券流水表期货历史
      INSERT sims2016TradeHist..prodCellRawJrnlFHist(serialNO, settleDate, secuBizTypeCode, buySellFlagCode,
                                                    bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, originSecuBizTypeCode,
                                                    brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID,
                                                    prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt,
                                                    cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode,
                                                    secuName, secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice,
                                                    matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID,
                                                    brokerOriginOrderID, brokerErrorMsg, dataSourceFlagCode, transactionNO,
                                                    investPortfolioCode, assetLiabilityTypeCode, investInstrucNO, traderInstrucNO,
                                                    orderNO, marketLevelCode, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt,
                                                    orderSettlePrice, orderTradeFeeAmt, directorCode, traderCode,
                                                    operatorCode, operateDatetime, operateRemarkText)
                                              SELECT a.serialNO, a.settleDate, a.secuBizTypeCode, a.buySellFlagCode,
                                                    a.bizSubTypeCode, a.openCloseFlagCode, a.hedgeFlagCode, a.originSecuBizTypeCode,
                                                    a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName, a.brokerJrnlSerialID,
                                                    a.prodCode, a.prodCellCode, a.fundAcctCode, a.currencyCode, a.cashSettleAmt,
                                                    a.cashBalanceAmt, a.exchangeCode, a.secuAcctCode, a.secuCode, a.originSecuCode,
                                                    a.secuName, a.secuTradeTypeCode, a.matchQty, a.posiBalanceQty, a.matchNetPrice,
                                                    matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID,
                                                    brokerOriginOrderID, brokerErrorMsg, a.dataSourceFlagCode, transactionNO,
                                                    investPortfolioCode, assetLiabilityTypeCode, investInstrucNO, traderInstrucNO,
                                                    orderNO, a.marketLevelCode, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt,
                                                    orderSettlePrice, orderTradeFeeAmt, directorCode, traderCode,
                                                    a.operatorCode, a.operateDatetime, a.operateRemarkText
                                                    FROM sims2016TradeHist..prodCellRawJrnlHist a
                                                    join sims2016TradeHist..prodRawJrnlFHist b on a.originSerialNO = b.serialNO
                                                    WHERE dbo.fnCharIndexDh(a.fundAcctCode, @i_fundAcctCode) > 0
                                                      AND a.prodCode != a.prodCellCode
                                                      AND a.secuTradeTypeCode LIKE 'F%' --只负责处理期货交易流水
                                                      AND a.settleDate BETWEEN @i_beginDate AND @i_endDate
                                                      AND a.secuBizTypeCode NOT IN('605', '606','8041', '8001', '8002', '8003', '8004')
    END

  RETURN 0
go

--exec ipCalcProdCellRawJrnlF '9999-01', '2017-03-13', '2017-03-17'

