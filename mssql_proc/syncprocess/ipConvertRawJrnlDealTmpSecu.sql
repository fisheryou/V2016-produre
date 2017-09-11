USE sims2016Proc
go

IF OBJECT_ID(N'ipConvertRawJrnlDealTmpSecu', N'P') IS NOT NULL
  DROP PROC ipConvertRawJrnlDealTmpSecu
go

--EXEC ipConvertRawJrnlDealTmpSecu '9999', '', '', '6000-01', '2000-03-13', '2099-03-20'
CREATE PROC ipConvertRawJrnlDealTmpSecu
  @i_operatorCode       VARCHAR(30),      
  @i_operatorPassword   VARCHAR(30),      
  @i_operateStationText VARCHAR(600),     
  @i_fundAcctCode       VARCHAR(30),
  @i_beginDate          VARCHAR(10),
  @i_endDate            VARCHAR(10)
AS
  DECLARE
  @brokerBranchCode VARCHAR(30), @currencyCode VARCHAR(4), @counterVersionCode VARCHAR(30), @innerCounterVersionCode VARCHAR(30)
  
  DECLARE
  @serialNO INT, @prodCode VARCHAR(30), @fundAcctCode VARCHAR(30), @operateDate VARCHAR(10), @operateTime VARCHAR(25), @brokerJrnlSerialID VARCHAR(30),
  @brokerSecuBizCode VARCHAR(30), @brokerSecuBizName VARCHAR(30),
  @cashSettleAmt DECIMAL(19,4), @cashBalanceAmt DECIMAL(19,4), @posiBalanceQty DECIMAL(19,4),
  @exchangeCode VARCHAR(4), @secuCode VARCHAR(30), @secuName VARCHAR(60), @tradingUnitValue INT, @matchQty INT, @matchNetPrice DECIMAL(19,4),
  @matchNetAmt DECIMAL(19,4), @stampTaxAmt DECIMAL(19,4), @commissionFeeAmt DECIMAL(19,4), @transferFeeAmt DECIMAL(19,4), @otherFeeAmt DECIMAL(19,4),
  @brokerOrderID VARCHAR(30), @brokerOriginOrderID VARCHAR(30), @secuAcctCode VARCHAR(30), @matchDate VARCHAR(10), @matchTime VARCHAR(25),
  @matchID VARCHAR(30), @operateRemarkText VARCHAR(600)

  DECLARE
  @listingDate VARCHAR(10), @secuTradeTypeCode VARCHAR(30), @tradeUnitValue INT, @originSecuCode VARCHAR(30), @bizTypeCode VARCHAR(30),
  @qtyUnitFactorCode INT, @qtyUnitFactorValue INT, @todayDate VARCHAR(10), @fundAcctCode_tmp VARCHAR(30), @fundAcctCode_l VARCHAR(4096),
  @findRow INT = 0,
  @bizSubTypeCode VARCHAR(30), @buySellFlagCode VARCHAR(30), @openCloseFlagCode VARCHAR(30), @hedgeFlagCode VARCHAR(30), @coveredFlagCode VARCHAR(30) = '1',
  @dataSourceFlagCode VARCHAR(30) = '0', @marketLevelCode VARCHAR(30), @brokerOrderID_compare VARCHAR(30)

  SELECT @todayDate = CONVERT(VARCHAR(10), GETDATE(), 120), @fundAcctCode_l = ','

  SELECT serialNO, settleDate AS operateDate, CAST('' AS VARCHAR(30)) AS operateTime,
         secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode,
         hedgeFlagCode, CAST('' AS VARCHAR(1)) AS coveredFlagCode, originSecuBizTypeCode,
         brokerOrderID, brokerOriginOrderID,
         CAST('' AS VARCHAR(25)) AS brokerOrderID_compare,
         prodCode, fundAcctCode, currencyCode, brokerJrnlSerialID,
         brokerSecuBizTypeCode, brokerSecuBizTypeName,
         cashSettleAmt, cashBalanceAmt, posiBalanceQty,
         exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode,
         CAST(0 AS DECIMAL(19,4)) AS tradingUnitValue,
         matchQty, matchNetPrice, matchSettleAmt, dataSourceFlagCode,
         CAST(0 AS DECIMAL(19,4)) AS stampTaxAmt, CAST(0 AS DECIMAL(19,4)) AS commissionFeeAmt,
         CAST(0 AS DECIMAL(19,4)) AS transferFeeAmt, CAST(0 AS DECIMAL(19,4)) AS otherFeeAmt,
         matchDate, matchTime, matchID, marketLevelCode, operateRemarkText
         into #brokerRawJrnlDealSecuHist
         FROM sims2016TradeToday..prodRawJrnlESToday WHERE 0 = 1

  SELECT @brokerBranchCode = brokerBranchCode, @currencyCode = currencyCode
         FROM sims2016TradeToday..prodCapital
         WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
  IF @brokerBranchCode IS NULL OR @brokerBranchCode = ''
    RETURN

  SELECT @counterVersionCode = brokerCounterVersionCode FROM sims2016TradeToday..brokerBranch WHERE brokerBranchCode = @brokerBranchCode
  IF @counterVersionCode IS NULL OR @counterVersionCode = ''
    RETURN

  SELECT prodCode, currencyCode, fundAcctCode, brokerFundAcctCode, brokerBranchCode,
         CASE WHEN brokerCounterAcctDate != '' AND brokerCounterAcctDate > @i_beginDate THEN brokerCounterAcctDate
              ELSE @i_beginDate END AS beginDate
         INTO #prodCapitalES
         FROM sims2016TradeToday..prodCapital
         WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
           AND fundAcctTypeCode = '3'
  IF @@ROWCOUNT <= 0
    RETURN
  
  DECLARE cur_RawJrnl CURSOR FOR SELECT serialNO, b.prodCode, a.fundAcctCode, operateDate, operateTime, brokerJrnlSerialID,
                                        brokerSecuBizTypeCode, brokerSecuBizTypeName,
                                        cashSettleAmt, cashBalanceAmt, posiBalanceQty,
                                        exchangeCode, secuCode, secuName, tradingUnitValue,
                                        matchQty, matchNetPrice, matchNetAmt,
                                        stampTaxAmt, commissionFeeAmt, transferFeeAmt, otherFeeAmt,
                                        brokerOrderID, brokerOriginOrderID,secuAcctCode, matchDate, matchTime, matchID,
                                        operateRemarkText
                                        FROM sims2016DataExchg..brokerRawJrnlDealSecuTmp a
                                        JOIN #prodCapitalES b ON a.fundAcctCode = b.fundAcctCode
                                        WHERE a.operateDate >= b.beginDate AND a.operateDate BETWEEN @i_beginDate AND @i_endDate
                                        order BY a.fundAcctCode, a.operateDate, a.serialNO
                                                                                                                                                           
  OPEN cur_RawJrnl
  SELECT @fundAcctCode_tmp = NULL
  FETCH cur_RawJrnl INTO @serialNO, @prodCode, @fundAcctCode, @operateDate, @operateTime, @brokerJrnlSerialID,
                         @brokerSecuBizCode, @brokerSecuBizName,
                         @cashSettleAmt, @cashBalanceAmt, @posiBalanceQty,
                         @exchangeCode, @secuCode, @secuName, @tradingUnitValue,
                         @matchQty, @matchNetPrice, @matchNetAmt,
                         @stampTaxAmt, @commissionFeeAmt, @transferFeeAmt, @otherFeeAmt,
                         @brokerOrderID, @brokerOriginOrderID, @secuAcctCode, @matchDate, @matchTime, @matchID,
                         @operateRemarkText
  WHILE @@FETCH_STATUS = 0
    BEGIN
    		
      IF @fundAcctCode_tmp IS NULL OR @fundAcctCode != @fundAcctCode_tmp
        SELECT @fundAcctCode_tmp = @fundAcctCode

      IF @matchDate = ''
        SELECT @matchDate = @operateDate

      SELECT @originSecuCode = @secuCode
      IF @exchangeCode != '' AND @exchangeCode NOT IN('XSHG', 'XSHE')
        SELECT @exchangeCode = ''
      IF @exchangeCode = '' AND @secuCode != ''
        BEGIN
          SELECT @exchangeCode = exchangeCode FROM sims2016TradeToday..secuTable WHERE secuCode = @secuCode AND secuTradeTypeCode !='DDC'
          IF @@ROWCOUNT != 1
            BEGIN
              SELECT @exchangeCode FROM sims2016TradeToday..secuTmpl WHERE @secuCode BETWEEN beginSecuCode AND endSecuCode AND secuTradeTypeCode != 'DDC'
              IF @@ROWCOUNT != 1
                SELECT @exchangeCode = ''
            END
        END

      IF @exchangeCode = '' AND @secuAcctCode != ''
        BEGIN
          SELECT @exchangeCode FROM sims2016TradeToday..secuAcct WHERE fundAcctCode = @fundAcctCode AND secuAcctCode = @secuAcctCode
          IF @@ROWCOUNT != 1
            BEGIN
              SELECT @exchangeCode = ''
              IF @secuAcctCode LIKE 'B88%' OR @secuAcctCode LIKE 'D89%'
                SELECT @exchangeCode = 'XSHG'
            END
        END

      IF @exchangeCode != '' AND @secuCode != ''
        BEGIN
          EXEC ip_getOrginSecuCode @i_operatorCode, @i_operatorPassword, @i_operateStationText, @exchangeCode, @secuCode, @operateDate,
                                   @secuTradeTypeCode OUT, @originSecuCode OUT
          
          SELECT @listingDate = listingDate, @secuTradeTypeCode = secuTradeTypeCode
                 FROM sims2016TradeToday..secuTable WHERE exchangeCode = @exchangeCode AND secuCode = @secuCode
          IF @secuTradeTypeCode IN('RW', 'RWS', 'RA')
            SELECT @listingDate = '2999-01-01'

          SELECT @listingDate = ISNULL(@listingDate, '')
          
          SELECT @qtyUnitFactorValue = CASE WHEN qtyUnitFactorCode = '2' THEN qtyUnitFactorValue ELSE 1 END
                 FROM sims2016TradeToday..secuTradeProperty
          SELECT @qtyUnitFactorValue = ISNULL(@qtyUnitFactorValue, 1)
        END
               
      EXEC ip_convertBrokerSecuBizType @i_operatorCode, @i_operatorPassword, @i_operateStationText, @counterVersionCode, @fundAcctCode, @currencyCode,
                                     @operateDate, @brokerSecuBizCode OUT, @brokerSecuBizName OUT, @cashSettleAmt OUT,
                                     @exchangeCode OUT, @secuCode OUT, @secuName OUT, @secuTradeTypeCode OUT, @tradeUnitValue OUT, @tradingUnitValue OUT,
                                     @matchQty OUT, @matchNetPrice OUT, @matchNetAmt OUT,
                                     @stampTaxAmt OUT, @commissionFeeAmt OUT, @transferFeeAmt OUT, @otherFeeAmt OUT,
                                     @secuAcctCode OUT, @brokerOrderID OUT, @operateRemarkText OUT, @bizTypeCode OUT 

			

      SELECT @buySellFlagCode = buySellFlagCode, @bizSubTypeCode = bizSubTypeCode, @openCloseFlagCode = openCloseFlagCode
             FROM sims2016TradeToday..secuBizType
             WHERE secuBizTypeCode = @bizTypeCode

      SELECT @buySellFlagCode = ISNULL(@buySellFlagCode, ''), @bizSubTypeCode = ISNULL(@bizSubTypeCode, ''), @openCloseFlagCode = ISNULL(@openCloseFlagCode, '')

      IF @bizTypeCode IN('8090', '8091') --其他资金增加，其他资金减少
        SELECT @buySellFlagCode = ' '
      ELSE
        SELECT @buySellFlagCode = '1'

      IF @exchangeCode != '' AND @secuCode != '' AND @bizTypeCode NOT LIKE '80%'
        BEGIN
          IF @bizTypeCode = '101'
            BEGIN
              IF @matchQty != 0 AND @cashSettleAmt = 0 AND @matchNetAmt = 0
                --新股配号
                SELECT @bizTypeCode = '104', @buySellFlagCode = ' ', @bizSubTypeCode = ' ', @openCloseFlagCode = ' '
            END
          IF @bizTypeCode = '102'
            BEGIN
              IF @matchQty != 0 AND @cashSettleAmt = 0 AND @matchNetAmt = 0
                --新股配号
                SELECT @bizTypeCode = '104', @buySellFlagCode = ' ', @bizSubTypeCode = ' ', @openCloseFlagCode = ' '
            END
        END

      --根据特殊的证券代码进行业务代码的处理
      IF @secuCode = '799999'
        SELECT @bizTypeCode = 'ZDJYDJ'
      ELSE IF @secuCode = '799998'
        SELECT @bizTypeCode = 'ZDJYCX'
      ELSE IF @secuCode = '799997'
        SELECT @bizTypeCode = 'HGZDDJ'
      ELSE IF @secuCode = '799996'
        SELECT @bizTypeCode = 'HGZDCX'

      --资金存取类业务，证券交易类别代码为空
      IF @bizTypeCode IN('8001', '8002', '8003', '8004')
        SELECT @secuTradeTypeCode = ''

      SELECT @brokerOrderID_compare = CASE WHEN @brokerOrderID != '' THEN 'A' + @brokerOrderID
                                           WHEN @brokerOriginOrderID != '' THEN 'B' + @brokerOriginOrderID ELSE '' END

      INSERT #brokerRawJrnlDealSecuHist(serialNO, operateDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode,
                                      hedgeFlagCode, coveredFlagCode, originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName,
                                      brokerOrderID, brokerOriginOrderID,
                                      brokerOrderID_compare,
                                      brokerJrnlSerialID, prodCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode,
                                      secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, matchSettleAmt, dataSourceFlagCode,
                                      stampTaxAmt, commissionFeeAmt, transferFeeAmt, otherFeeAmt,
                                      matchDate, matchTime, matchID,
                                      marketLevelCode, operateRemarkText)
                               VALUES(@serialNO, @operateDate, @bizTypeCode, @buySellFlagCode, @bizSubTypeCode, @openCloseFlagCode,
                                      ISNULL(@hedgeFlagCode, '1'), ISNULL(@coveredFlagCode, '0'), @brokerSecuBizCode, @brokerSecuBizCode, @brokerSecuBizName,
                                      @brokerOrderID, @brokerOriginOrderID,
                                      @brokerOrderID_compare,
                                      @brokerJrnlSerialID, @prodCode, @fundAcctCode, @currencyCode, @cashSettleAmt, @cashBalanceAmt, @exchangeCode, @secuAcctCode,
                                      @secuCode, @originSecuCode, @secuName, ISNULL(@secuTradeTypeCode, ' '), @matchQty, @posiBalanceQty, @matchNetPrice, @matchNetAmt, @dataSourceFlagCode,
                                      @stampTaxAmt, @commissionFeeAmt, @transferFeeAmt, @otherFeeAmt,
                                      @matchDate, @matchTime, @matchID,
                                      ISNULL(@marketLevelCode, ' '), @operateRemarkText)

      FETCH cur_RawJrnl INTO @serialNO, @prodCode, @fundAcctCode, @operateDate, @operateTime, @brokerJrnlSerialID,
                             @brokerSecuBizCode, @brokerSecuBizName,
                             @cashSettleAmt, @cashBalanceAmt, @posiBalanceQty,
                             @exchangeCode, @secuCode, @secuName, @tradingUnitValue,
                             @matchQty, @matchNetPrice, @matchNetAmt,
                             @stampTaxAmt, @commissionFeeAmt, @transferFeeAmt, @otherFeeAmt,
                             @brokerOrderID, @brokerOriginOrderID, @secuAcctCode, @matchDate, @matchTime, @matchID,
                             @operateRemarkText
    END
  CLOSE cur_RawJrnl
  DEALLOCATE cur_RawJrnl
  
  EXEC ipTransformToP @i_operatorCode, @i_operatorPassword, @i_operateStationText, @i_fundAcctCode, @i_beginDate, @i_endDate            

go

--EXEC ipConvertRawJrnlDealTmpSecu '9999', '', '', '6000-01', '2000-03-13', '2099-03-20'

--SELECT * FROM sims2016TradeHist..prodRawJrnlESHist
--SELECT * FROM sims2016DataExchg..brokerRawJrnlDealSecuTmp
----SELECT * FROM sims2016TradeHist..prodCellRawJrnlESHist
--select * from sims2016TradeHist..prodRawJrnlPHist
--select * from sims2016TradeHist..prodCellRawJrnlPHist
----select * FROM sims2016TradeHist..prodRawJrnlPHist
----select * from sims2016TradeHist..prodRawJrnlHist
--SELECT * FROM sims2016TradeHist.dbo.wdqhgjlb


