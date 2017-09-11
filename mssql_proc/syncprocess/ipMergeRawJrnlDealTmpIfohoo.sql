USE sims2016Proc
go

IF OBJECT_ID(N'ipMergeRawJrnlDealTmpIfohoo', N'P') IS NOT NULL
  DROP PROC ipMergeRawJrnlDealTmpIfohoo
go

CREATE PROC ipMergeRawJrnlDealTmpIfohoo
  @i_operatorCode            VARCHAR(30),    --操作员代码
  @i_operatorPassword        VARCHAR(30),    --操作员密码
  @i_operateStationText      VARCHAR(600),    --

  @i_fundAcctCode            VARCHAR(30),    --资金账户代码
  @i_currencyCode            VARCHAR(4),    --货币代码
  @i_beginDate               VARCHAR(10),    --同步开始日期
  @i_endDate                 VARCHAR(10)     --同步结束日期
AS

  DELETE FROM sims2016DataExchg..brokerRawJrnlDealSecuTmp
         WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
           AND operateDate BETWEEN @i_beginDate AND @i_endDate

  INSERT sims2016DataExchg..brokerRawJrnlDealSecuTmp(fundAcctCode, operateDate, operateTime, brokerJrnlSerialID, brokerSecuBizTypeCode, 
                                                    brokerSecuBizTypeName, cashSettleAmt, cashBalanceAmt, posiBalanceQty, exchangeCode,
                                                    secuCode, secuName, longShortFlagCode, hedgeFlagCode, tradingUnitValue, matchQty, matchNetPrice, matchNetAmt,
                                                    stampTaxAmt, commissionFeeAmt, transferFeeAmt, secuManageFeeAmt, brokerageFeeAmt, otherFeeAmt, clearingFeeAmt,
                                                    secuAcctCode, brokerOrderID, brokerOriginOrderID, matchDate, matchTime, matchID, riskFundFeeAmt, performanceFeeAmt,
                                                    operatorCode, operateDatetime, operateRemarkText)
                                             SELECT a.fundAcctCode, a.settleDate, CONVERT(VARCHAR(25), GETDATE(), 114), a.brokerJrnlSerialID, a.brokerSecuBizTypeCode, 
                                                    a.brokerSecuBizTypeName, a.cashSettleAmt, a.cashBalanceAmt, a.posiBalanceQty, a.exchangeCode,
                                                    a.secuCode, a.secuName, a.longShortFlagCode, a.hedgeFlagCode, a.tradingUnitValue, a.matchQty, a.matchNetPrice, a.matchNetAmt,
                                                    a.stampTaxAmt, a.commissionFeeAmt, a.transferFeeAmt, a.secuManageFeeAmt, a.brokerageFeeAmt, a.otherFeeAmt, 0, --a.clearingFeeAmt,
                                                    a.secuAcctCode, ISNULL(b.brokerOrderID, a.brokerOrderID) AS brokerOrderID, a.brokerOriginOrderID,
                                                    a.matchDate, a.matchTime, a.matchID, a.riskFundFeeAmt, a.performanceFeeAmt,
                                                    a.operatorCode, GETDATE(), a.operateRemarkText
                                                    FROM sims2016DataExchg..brokerRawJrnlSecuTmp a
                                                    LEFT JOIN sims2016DataExchg..brokerDealSecuTmp b ON a.settleDate = b.settleDate AND a.fundAcctCode = b.fundAcctCode AND
                                                                                      a.brokerJrnlSerialID = b.brokerJrnlSerialID
                                                    WHERE dbo.fnCharIndexDh(a.fundAcctCode, @i_fundAcctCode) > 0
                                                      AND a.brokerJrnlSerialID IS NOT NULL 
                                                      AND a.settleDate BETWEEN @i_beginDate AND @i_endDate
  RETURN 0
go

