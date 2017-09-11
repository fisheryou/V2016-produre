USE sims2016Proc
go

IF OBJECT_ID(N'ipConvertRawJrnlDealTmpF', N'P') IS NOT NULL
  DROP PROC ipConvertRawJrnlDealTmpF
go

--名称: ipConvertRawJrnlDealTmpF
--功能: 处理营业部资金流水历史成交表(brokerRawJrnlDealSecuTmp)数据：
--     ①、派生到产品总流水表、产品股票流水表;
--     ②、派生到单元总流水表、单元股票流水表;
CREATE PROC ipConvertRawJrnlDealTmpF
  @i_operatorCode        VARCHAR(30)      ,       --操作员代码
  @i_operatorPassword    VARCHAR(30)      ,       --操作员密码
  @i_operateStationText  VARCHAR(600)     ,       --
  @i_fundAcctCode        VARCHAR(30)      ,       --资金账户代码
  @i_beginDate           VARCHAR(10)      ,       --开始日期
  @i_endDate             VARCHAR(10)              --结束日期
AS
  DECLARE
  @brokerBranchCode VARCHAR(30),  @currencyCode VARCHAR(4), @counterVersionCode VARCHAR(30), @innerCounterVersionCode VARCHAR(30),

  @serialNO INT, @settleDate VARCHAR(10), @prodCode VARCHAR(30), @fundAcctCode VARCHAR(30), @brokerJrnlSerialID VARCHAR(30),
  @exchangeCode VARCHAR(4), @secuAcctCode VARCHAR(30), @secuCode VARCHAR(30), @secuName VARCHAR(60), @bizCode VARCHAR(30), @bizName VARCHAR(60),
  @brokerOrderID VARCHAR(30), @brokerOriginOrderID VARCHAR(30),

  @matchDate VARCHAR(10), @matchTime VARCHAR(30), @matchNetPrice DECIMAL(19,4), @matchQty DECIMAL(19,4), @matchNetAmt DECIMAL(19,4), @matchID VARCHAR(30),
  @cashSettleAmt DECIMAL(19,4), @cashBalanceAmt DECIMAL(19,4), @posiBalanceQty DECIMAL(19,4),
  @commissionFeeAmt DECIMAL(19,4), @recentRlzProfit DECIMAL(19,4), @brokerReportQtyUnitCode VARCHAR(30), @contractMultiplierValue DECIMAL(19,4), 
  @brokerBizTypeCode VARCHAR(30), @operatorCode VARCHAR(10), @operateDatetime DATETIME, @operateRemarkText VARCHAR(600), @otherFeeAmt DECIMAL(19,4) = 0,
  @stampTaxAmt DECIMAL(19,4) = 0, @transferFeeAmt DECIMAL(19,4) = 0, @secuTradeTypeCode VARCHAR(30) = '', @tradeUnitValue DECIMAL(19,4) = 0, @brokerTradeUnitValue DECIMAL(19,4) = 1,
  @originSecuCode VARCHAR(30), @bizTypeCode VARCHAR(30) = '', @qtyUnitFactorCode VARCHAR(30) = '0', @qtyUnitFactorValue DECIMAL(19,4), @todayDate VARCHAR(10),
  @tmp_fundAcctCode VARCHAR(30), @l_fundAcctCode VARCHAR(4096), @tmp_secuTradeTypeCode VARCHAR(30) = '',
  @findRow INT = 0,
  @bizSubTypeCode VARCHAR(30), @buySellFlagCode VARCHAR(30), @openCloseFlagCode VARCHAR(30), @hedgeFlagCode VARCHAR(30) = '1', @coveredFlagCode VARCHAR(1) = '1',
  @dataSourceFlagCode VARCHAR(30) = '0', @marketLevelCode VARCHAR(30) = '2', @brokerOrderID_compare VARCHAR(25) = '', @longShortFlagCode VARCHAR(30), @secuTradeTypeCode_temp VARCHAR(30) = '',
  @fundAcctCodes VARCHAR(2048) = ','+ @i_fundAcctCode + ','

  SELECT @todayDate = CONVERT(VARCHAR(10), GETDATE(), 120), @l_fundAcctCode = ','

  SELECT settleDate AS operateDate, cast('' AS VARCHAR(30)) AS operateTime, secuBizTypeCode,
         CAST('' AS VARCHAR(30)) AS longShortFlagCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode,
         hedgeFlagCode, cast('' AS VARCHAR(1)) AS coveredFlagCode, originSecuBizTypeCode,
         brokerOrderID, brokerOriginOrderID,
         cast('' AS VARCHAR(25)) AS brokerOrderID_compare,
         prodCode, fundAcctCode, currencyCode, brokerJrnlSerialID,
         brokerSecuBizTypeCode, brokerSecuBizTypeName,
         cashSettleAmt, cashBalanceAmt, posiBalanceQty,
         exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode,
         cast(0 AS DECIMAL(19,4)) AS tradingUnitValue,
         matchQty, matchNetPrice, matchSettleAmt AS matchNetAmt, cast('' AS VARCHAR(1)) AS dataSourceFlagCode,
         cast(0 AS DECIMAL(19,4)) AS stampTaxAmt, cast(0 AS DECIMAL(19,4)) AS commissionFeeAmt,
         cast(0 AS DECIMAL(19,4)) AS transferFeeAmt, cast(0 AS DECIMAL(19,4)) AS otherFeeAmt,
         matchDate, matchTime, matchID,
         cast('' AS VARCHAR(1)) AS marketLevelCode,
         operateRemarkText
         INTO #brokerRawJrnlDealHistF
         FROM sims2016TradeToday..prodRawJrnlFToday WHERE 0 = 1

  SELECT @brokerBranchCode = brokerBranchCode, @currencyCode = currencyCode
         FROM sims2016TradeToday..prodCapital WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
  IF @@ROWCOUNT = 0
    RETURN

  SELECT @counterVersionCode = brokerCounterVersionCode FROM sims2016TradeToday..brokerBranch WHERE brokerBranchCode = @brokerBranchCode
  IF @@ROWCOUNT = 0
    RETURN

  SELECT prodCode, currencyCode, fundAcctCode, brokerFundAcctCode, brokerBranchCode,
         CASE WHEN brokerCounterAcctDate IS NOT NULL AND brokerCounterAcctDate > @i_beginDate THEN brokerCounterAcctDate
              ELSE @i_beginDate END AS beginDate
         INTO #prodCapitalF
         FROM sims2016TradeToday..prodCapital
         WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
           AND fundAcctCode = '1'
  IF @@ROWCOUNT = 0
    RETURN
  
  SELECT COUNT(*) FROM sims2016DataExchg..brokerRawJrnlFutureTmp a
                  JOIN #prodCapitalF b ON a.fundAcctCode = b.fundAcctCode
                  WHERE a.settleDate >= b.beginDate
                    AND a.settleDate BETWEEN @i_beginDate AND @i_endDate
  IF @@ROWCOUNT = 0
    RETURN

  DECLARE cur_RawJrnlF CURSOR FOR SELECT serialNO, b.prodCode, b.fundAcctCode, settleDate, brokerJrnlSerialID,
                                        exchangeCode, secuAcctCode, secuCode, secuName,
                                        brokerSecuBizTypeCode, brokerSecuBizTypeName,
                                        brokerOrderID, brokerOriginOrderID,
                                        orderQty, orderNetPrice, orderNetAmt,
                                        matchDate, matchTime, matchNetPrice, matchQty, matchNetAmt, matchID,
                                        cashSettleAmt, cashBalanceAmt, posiBalanceQty,
                                        commissionFeeAmt, recentRlzProfit, otherFeeAmt,
                                        brokerReportQtyUnitCode, contractMultiplierValue, hedgeFlagCode, brokerBizTypeCode,
                                        operatorCode, operateDatetime, operateRemarkText
                                        FROM sims2016DataExchg..brokerRawJrnlFutureTmp a
                                        JOIN #prodCapitalF b ON a.fundAcctCode = b.fundAcctCode
                                        WHERE a.settleDate >= b.beginDate AND a.settleDate BETWEEN @i_beginDate AND @i_endDate
                                        ORDER BY a.fundAcctCode, settleDate, serialNO
  OPEN cur_RawJrnlF
  SELECT @tmp_fundAcctCode = NULL
  FETCH cur_RawJrnlF INTO @serialNO, @prodCode, @fundAcctCode, @settleDate, @brokerJrnlSerialID,
                          @exchangeCode, @secuAcctCode, @secuCode, @secuName,
                          @bizCode, @bizName,
                          @brokerOrderID, @brokerOriginOrderID,
                          --@orderQty, @orderNetPrice, @orderNetAmt,
                          @matchDate, @matchTime, @matchNetPrice, @matchQty, @matchNetAmt, @matchID,
                          @cashSettleAmt, @cashBalanceAmt, @posiBalanceQty,
                          @commissionFeeAmt, @recentRlzProfit, @otherFeeAmt,
                          @brokerReportQtyUnitCode, @contractMultiplierValue, @hedgeFlagCode, @brokerBizTypeCode,
                          @operatorCode, @operateDatetime, @operateRemarkText
  WHILE @@FETCH_STATUS = 0
    BEGIN
      SELECT @bizCode = RTRIM(@bizCode), @bizName = RTRIM(@bizName)

      IF @tmp_fundAcctCode IS NULL OR @tmp_fundAcctCode != @fundAcctCode
        SELECT @tmp_fundAcctCode = @fundAcctCode, @l_fundAcctCode = @l_fundAcctCode + @fundAcctCode + ','

      IF @matchDate IS NULL
        SELECT @matchDate = @settleDate

      SELECT @originSecuCode = @secuCode
      IF @exchangeCode IS NOT NULL AND @exchangeCode NOT IN('CCFX', 'XSGE', 'XDCE', 'XZCE')
        SELECT @exchangeCode = ''

      IF @exchangeCode IS NULL AND @secuCode IS NOT NULL
        BEGIN
          SELECT @exchangeCode = exchangeCode FROM sims2016TradeToday..secuTable WHERE secuCode = @secuCode
          IF @@ROWCOUNT != 1
          BEGIN
            SELECT @exchangeCode = exchangeCode FROM sims2016TradeToday..futureTmpl WHERE @secuCode BETWEEN beginSecuCode AND endSecuCode
            IF @@ROWCOUNT != 1
              SELECT @exchangeCode = ''
          END
        END

      IF @exchangeCode IS NULL AND @secuAcctCode != ''
        SELECT @exchangeCode = exchangeCode FROM sims2016TradeToday..secuAcct WHERE fundAcctCode = @fundAcctCode AND secuAcctCode = @secuAcctCode

      --ctp柜台没有给证券账户代码
      IF RTRIM(@secuAcctCode) IS NULL
        SELECT @secuAcctCode = secuAcctCode FROM sims2016TradeToday..secuAcct WHERE fundAcctCode = @fundAcctCode AND exchangeCode = @exchangeCode

      --交易类别代码
      IF RTRIM(@secuTradeTypeCode) IS NULL
        SELECT @secuTradeTypeCode = secuTradeTypeCode  FROM sims2016TradeToday..secuTable WHERE exchangeCode = @exchangeCode AND secuCode = @secuCode

      IF RTRIM(@secuTradeTypeCode) IS NULL
        BEGIN
          SELECT @secuTradeTypeCode_temp = secuTradeTypeCode
            FROM sims2016TradeToday..secuTmpl
            WHERE exchangeCode = @exchangeCode
              AND @secuCode BETWEEN beginSecuCode AND endSecuCode

          IF RTRIM(@secuTradeTypeCode_temp) IS NOT NULL
            BEGIN
              IF dbo.fnCharIndexDh(@secuTradeTypeCode_temp, '.') > 0
                select @secuTradeTypeCode = substring(@secuTradeTypeCode_temp, 1, dbo.fnCharIndexDh(@secuTradeTypeCode_temp, '.') - 1)
              ELSE
                select @secuTradeTypeCode = @secuTradeTypeCode_temp
            END
        END
      
      EXEC ip_convertBrokerSecuBizType @i_operatorCode, @i_operatorPassword, @i_operateStationText, @counterVersionCode, @fundAcctCode, @currencyCode,
                                       @operatorCode, @bizCode OUT, @bizName OUT, @cashSettleAmt OUT,
                                       @exchangeCode OUT, @secuCode OUT, @secuName OUT, @secuTradeTypeCode OUT, @tradeUnitValue OUT, @brokerTradeUnitValue OUT,
                                       @matchQty OUT, @matchNetPrice OUT, @matchNetAmt OUT,
                                       @stampTaxAmt OUT, @commissionFeeAmt OUT, @transferFeeAmt OUT, @otherFeeAmt OUT,
                                       @secuAcctCode OUT, @brokerOrderID OUT, @operateRemarkText OUT, @bizTypeCode OUT

      SELECT @buySellFlagCode = buySellFlagCode, @bizSubTypeCode = bizSubTypeCode,
             @openCloseFlagCode = openCloseFlagCode, @longShortFlagCode = longShortFlagCode
             FROM sims2016TradeToday..secuBizType
             WHERE secuBizTypeCode = @bizTypeCode

      SELECT @buySellFlagCode = ISNULL(@buySellFlagCode, ''), @bizSubTypeCode = ISNULL(@bizSubTypeCode, ''),
             @openCloseFlagCode = ISNULL(@openCloseFlagCode, ''), @longShortFlagCode = ISNULL(@longShortFlagCode, '')

      --资金存取类业务，证券交易类别代码为空
      IF @bizTypeCode IN('8001', '8002', '8003', '8004')
        SELECT @secuTradeTypeCode = ' '

      SELECT @brokerOrderID_compare = CASE WHEN @brokerOrderID IS NOT NULL THEN 'A' + @brokerOrderID
                                           WHEN @brokerOriginOrderID IS NOT NULL THEN 'B' + @brokerOriginOrderID ELSE '' END

      INSERT #brokerRawJrnlDealHistF(operateDate, secuBizTypeCode, buySellFlagCode, longShortFlagCode, bizSubTypeCode, openCloseFlagCode,
                                    hedgeFlagCode, coveredFlagCode, originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName,
                                    brokerOrderID, brokerOriginOrderID,
                                    brokerOrderID_compare,
                                    brokerJrnlSerialID, prodCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode,
                                    secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, matchNetAmt, dataSourceFlagCode,
                                    stampTaxAmt, commissionFeeAmt, transferFeeAmt, otherFeeAmt,
                                    matchDate, matchTime, matchID,
                                    marketLevelCode, operateRemarkText)
                             VALUES(@settleDate, @bizTypeCode, @buySellFlagCode, @longShortFlagCode, @bizSubTypeCode, @openCloseFlagCode,
                                    @hedgeFlagCode, @coveredFlagCode, @bizCode, @bizCode, @bizName,
                                    @brokerOrderID, @brokerOriginOrderID,
                                    @brokerOrderID_compare,
                                    @brokerJrnlSerialID, @prodCode, @fundAcctCode, @currencyCode, @cashSettleAmt, @cashBalanceAmt, @exchangeCode, @secuAcctCode,
                                    @secuCode, @originSecuCode, @secuName, @secuTradeTypeCode, @matchQty, @posiBalanceQty, @matchNetPrice, @matchNetAmt, @dataSourceFlagCode,
                                    0, @commissionFeeAmt, 0, @otherFeeAmt,
                                    @matchDate, @matchTime, @matchID,
                                    @marketLevelCode, @operateRemarkText)
      
      FETCH cur_RawJrnlF INTO @serialNO, @prodCode, @fundAcctCode, @settleDate, @brokerJrnlSerialID,
                              @exchangeCode, @secuAcctCode, @secuCode, @secuName,
                              @bizCode, @bizName,
                              @brokerOrderID, @brokerOriginOrderID,
                              --@orderQty, @orderNetPrice, @orderNetAmt,
                              @matchDate, @matchTime, @matchNetPrice, @matchQty, @matchNetAmt, @matchID,
                              @cashSettleAmt, @cashBalanceAmt, @posiBalanceQty,
                              @commissionFeeAmt, @recentRlzProfit, @otherFeeAmt,
                              @brokerReportQtyUnitCode, @contractMultiplierValue, @hedgeFlagCode, @brokerBizTypeCode,
                              @operatorCode, @operateDatetime, @operateRemarkText
    END
  CLOSE cur_RawJrnlF
  DEALLOCATE cur_RawJrnlF

  SELECT @findRow = COUNT(*) FROM #brokerRawJrnlDealHistF
  IF @@ROWCOUNT = 0
    RETURN

  --取只有一个产品单元的产品及投资组合信息
  SELECT a.prodCode, MAX(a.prodCellCode) AS prodCellCode, MAX(b.investPortfolioCode) AS investPortfolioCode
         INTO #defaultProdCellPortfolio
         FROM sims2016TradeToday..prodCell a
         JOIN sims2016TradeToday..investPortfolio b ON a.prodCode = b.prodCode AND a.prodCellCode = b.prodCellCode
         JOIN #prodCapitalF c ON a.prodCode = c.prodCode
         GROUP BY a.prodCode
         HAVING COUNT(a.prodCode) = 1

  --取成交信息
  SELECT orderNO, matchDate, matchID, a.prodCode, a.prodCellCode, a.fundAcctCode, secuAcctCode, exchangeCode, secuCode, longShortFlagCode
         INTO #prodCellDealFHist
         FROM sims2016TradeHist..prodCellDealFHist a
         JOIN #prodCapitalF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
         WHERE a.matchDate BETWEEN @i_beginDate AND @i_endDate
           AND a.matchID IS NOT NULL
           AND a.matchQty > 0

  SELECT a.orderNO, a.tradeDate, a.tradeTime, a.investInstrucNO, a.traderInstrucNO,
         a.prodCode, a.prodCellCode, a.fundAcctCode, a.currencyCode, a.exchangeCode, a.secuCode, a.secuAcctCode,
         a.secuTradeTypeCode, a.hedgeFlagCode,
         a.marketLevelCode, a.investPortfolioCode,
         a.assetLiabilityTypeCode, a.transactionNO,
         a.orderNetAmt, a.orderNetPrice,
         a.orderQty, a.orderSettleAmt,
         a.orderSettlePrice, a.orderTradeFeeAmt,
         a.traderCode, c.matchID, a.brokerOrderID,
         a.brokerOriginOrderID, a.brokerErrorMsg,
         CASE WHEN a.brokerOrderID IS NOT NULL THEN 'A'+ a.brokerOrderID
              WHEN a.brokerOriginOrderID IS NOT NULL THEN 'B' + a.brokerOriginOrderID
              ELSE '' END as brokerOrderID_compare,
         CASE WHEN sign(a.cashAvailableChgAmt) < 0 THEN -1 ELSE 1 END as cashCurrentSettleAmt_sign
         INTO #prodCellOrderFHist
    FROM sims2016TradeHist..prodCellOrderFHist a
    JOIN #prodCapitalF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
    JOIN #prodCellDealFHist c ON a.tradeDate = c.matchDate AND a.orderNO = c.orderNO
   WHERE a.tradeDate BETWEEN @i_beginDate AND @i_endDate
     AND a.orderWithdrawFlagCode = '1' --委托

  SELECT a.operateDate, a.brokerSecuBizTypeCode, a.originSecuBizTypeCode, a.secuBizTypeCode,
         a.brokerJrnlSerialID,  ISNULL(c.secuBizTypeName, a.brokerSecuBizTypeCode) AS brokerSecuBizTypeName,
         a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode, a.prodCode,
         ISNULL(b.prodCellCode, d.prodCellCode) as prodCellCode, a.fundAcctCode, a.currencyCode,
         a.cashSettleAmt, a.cashBalanceAmt, a.exchangeCode, a.secuCode, a.originSecuCode, a.secuName, a.secuTradeTypeCode,
         CASE WHEN c.buySellFlagCode IS NULL THEN a.matchQty
              WHEN c.posiDirectFlagValue > 0 THEN abs(a.matchQty)
              WHEN c.posiDirectFlagValue < 0 THEN -abs(a.matchQty)
              ELSE a.matchQty END as matchQty,
         a.matchNetPrice, a.posiBalanceQty,
         CASE WHEN c.buySellFlagCode IS NULL THEN a.matchNetAmt
              WHEN c.cashDirectFlagValue > 0 THEN abs(a.matchNetAmt)
              WHEN c.cashDirectFlagValue < 0 THEN -abs(a.matchNetAmt)
              ELSE a.matchNetAmt END as matchNetAmt,
         a.stampTaxAmt, a.commissionFeeAmt, a.transferFeeAmt, a.otherFeeAmt,
         a.stampTaxAmt + a.commissionFeeAmt + a.transferFeeAmt + a.otherFeeAmt as matchTradeFeeAmt,
         a.matchDate, a.matchTime, a.matchID,
         a.secuAcctCode, a.brokerOrderID, a.brokerOriginOrderID, a.brokerOrderID_compare, a.operateRemarkText,
         a.marketLevelCode,
         --委托字段信息
         ISNULL(b.orderNO, 0) as orderNO, ISNULL(b.investInstrucNO, 0) as investInstrucNO, ISNULL(b.traderInstrucNO, 0) as traderInstrucNO,
         CASE WHEN ISNULL(b.prodCellCode, d.prodCellCode) = d.prodCellCode THEN ISNULL(d.investPortfolioCode, ' ')
              ELSE ISNULL(b.investPortfolioCode, ' ') END as investPortfolioCode,
         ISNULL(b.orderQty, 0) as orderQty, ISNULL(b.orderNetPrice, 0) as orderNetPrice, ISNULL(b.orderNetAmt, 0) as orderNetAmt,
         ISNULL(b.orderSettleAmt, 0) as orderSettleAmt, ISNULL(b.orderSettlePrice, 0) as orderSettlePrice, ISNULL(b.orderTradeFeeAmt, 0) as orderTradeFeeAmt,
         ISNULL(b.tradeTime, '') as tradeTime,
         ISNULL(b.traderCode, '') as traderCode, ISNULL(b.transactionNO, 0) as transactionNO, ISNULL(b.assetLiabilityTypeCode, '0') as assetLiabilityTypeCode,
         ISNULL(b.hedgeFlagCode, '1') as hedgeFlagCode, ISNULL(b.brokerErrorMsg, '') as brokerErrorMsg
    INTO #dataSyncRawJrnlF
    FROM #brokerRawJrnlDealHistF a
    JOIN #prodCapitalF e ON a.prodCode = e.prodCode AND a.fundAcctCode = e.fundAcctCode
    LEFT JOIN #prodCellOrderFHist b ON a.operateDate = b.tradeDate AND a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode AND a.matchID = b.matchID
    LEFT JOIN sims2016TradeToday..secuBizType c ON a.secuBizTypeCode = c.secuBizTypeCode
    LEFT JOIN #defaultProdCellPortfolio d ON a.prodCode = d.prodCode

  --产品资金证券流水当日总流水表
  DELETE FROM sims2016TradeToday..prodRawJrnlToday WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                     AND settleDate >= @todayDate
                                                     AND dataSourceFlagCode = '0';

  INSERT INTO sims2016TradeToday..prodRawJrnlToday(settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, coveredFlagCode,
                                                   originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, prodCode, fundAcctCode,
                                                   currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName,
                                                   secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode,
                                                   operateDatetime, operateRemarkText)
                                            SELECT operateDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, @coveredFlagCode,
                                                   originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, a.prodCode, a.fundAcctCode,
                                                   a.currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName,
                                                   secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, @dataSourceFlagCode, marketLevelCode,
                                                   GETDATE(), operateRemarkText
                                              FROM #dataSyncRawJrnlF a
                                              JOIN #prodCapitalF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
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
                                     SELECT a.operateDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, @coveredFlagCode,
                                            originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, a.prodCode, a.fundAcctCode,
                                            a.currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName,
                                            secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, @dataSourceFlagCode, marketLevelCode,
                                            GETDATE(), operateRemarkText
                                       FROM #dataSyncRawJrnlF a
                                       JOIN #prodCapitalF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
                                      WHERE a.operateDate < @todayDate
                                        AND a.operateDate BETWEEN @i_beginDate AND @i_endDate

  --产品资金证券流水表股票当日(纯交易流水)
  DELETE FROM sims2016TradeToday..prodRawJrnlFToday WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                      AND settleDate >= @todayDate
                                                      AND dataSourceFlagCode = '0'

  INSERT sims2016TradeToday..prodRawJrnlFToday(serialNO, settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
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
                                          FROM #dataSyncRawJrnlF a
                                          JOIN #prodCapitalF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
                                          JOIN sims2016TradeToday..prodRawJrnlToday c ON a.operateDate = c.settleDate and a.brokerJrnlSerialID = c.brokerJrnlSerialID
                                         WHERE a.operateDate >= @todayDate
                                           AND a.secuBizTypeCode NOT IN('8001', '8002', '8003', '8004')

  --产品资金证券流水表股票历史(纯交易流水)
  DELETE FROM sims2016TradeHist..prodRawJrnlFHist WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                    AND settleDate BETWEEN @i_beginDate AND @i_endDate
                                                    AND dataSourceFlagCode = '0'

  INSERT sims2016TradeHist..prodRawJrnlFHist(serialNO, settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
                                             originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID, prodCode, prodCellCode,
                                             fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode,
                                             secuName, secuTradeTypeCode, matchQty, posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode, matchSettleAmt,
                                             matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID, brokerOriginOrderID, brokerErrorMsg, transactionNO, investPortfolioCode,
                                             assetLiabilityTypeCode, investInstrucNO, traderInstrucNO, orderNO, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt, orderSettlePrice,
                                             orderTradeFeeAmt, directorCode, traderCode, operatorCode, operateDatetime, operateRemarkText)
                                      SELECT c.serialNO, a.operateDate, a.secuBizTypeCode, a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode, a.hedgeFlagCode,
                                             a.originSecuBizTypeCode, a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName, a.brokerJrnlSerialID, a.prodCode, a.prodCellCode,
                                             a.fundAcctCode, a.currencyCode, a.cashSettleAmt, a.cashBalanceAmt, a.exchangeCode, a.secuAcctCode, a.secuCode, a.originSecuCode,
                                             a.secuName, ISNULL(a.secuTradeTypeCode, ' '), a.matchQty, a.posiBalanceQty, a.matchNetPrice, @dataSourceFlagCode, a.marketLevelCode, a.matchNetAmt,
                                             a.matchTradeFeeAmt, a.matchDate, a.matchTime, a.matchID, a.brokerOrderID, a.brokerOriginOrderID, a.brokerErrorMsg, a.transactionNO, ISNULL(a.investPortfolioCode, ' '),
                                             a.assetLiabilityTypeCode, a.investInstrucNO, a.traderInstrucNO, a.orderNO, a.orderNetAmt, a.orderNetPrice, a.orderQty, a.orderSettleAmt, a.orderSettlePrice,
                                             a.orderTradeFeeAmt, '', a.traderCode, '', GETDATE(), a.operateRemarkText
                                        FROM #dataSyncRawJrnlF a
                                        JOIN #prodCapitalF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode
                                        JOIN sims2016TradeHist..prodRawJrnlHist c ON a.operateDate = c.settleDate and a.brokerJrnlSerialID = c.brokerJrnlSerialID
                                       WHERE a.operateDate < @todayDate
                                         AND a.secuBizTypeCode NOT IN('8001', '8002', '8003', '8004')
                                         AND a.operateDate BETWEEN @i_beginDate AND @i_endDate

  --产品单元资金证券流水当日总流水表(从产品资金证券流水当日总流水表派生)
  DELETE FROM sims2016TradeToday..prodCellRawJrnlToday WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                         AND settleDate >= @todayDate
                                                         AND dataSourceFlagCode = '0'

  INSERT sims2016TradeToday..prodCellRawJrnlToday(serialNO, originSerialNO, settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode,
                                                  hedgeFlagCode, coveredFlagCode, originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName,
                                                  brokerJrnlSerialID, prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt,
                                                  exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty,
                                                  posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode, operatorCode, operateDatetime, operateRemarkText)
                                           SELECT a.serialNO, a.serialNO, a.settleDate, a.secuBizTypeCode, a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode,
                                                  a.hedgeFlagCode, a.coveredFlagCode, a.originSecuBizTypeCode, a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName,
                                                  a.brokerJrnlSerialID, a.prodCode, b.prodCellCode, a.fundAcctCode, a.currencyCode, a.cashSettleAmt, a.cashBalanceAmt,
                                                  a.exchangeCode, a.secuAcctCode, a.secuCode, a.originSecuCode, a.secuName, a.secuTradeTypeCode, a.matchQty,
                                                  a.posiBalanceQty, a.matchNetPrice, a.dataSourceFlagCode, a.marketLevelCode, a.operatorCode, GETDATE(), a.operateRemarkText
                                             FROM sims2016TradeToday..prodRawJrnlToday a
                                             JOIN #prodCapitalF d ON a.prodCode = d.prodCode AND a.fundAcctCode = d.fundAcctCode
                                             JOIN #dataSyncRawJrnlF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode AND
                                                                         a.exchangeCode = b.exchangeCode AND a.secuCode = b.secuCode AND
                                                                         a.secuAcctCode = b.secuAcctCode AND a.settleDate = b.operateDate AND
                                                                         a.brokerJrnlSerialID = b.brokerJrnlSerialID
                                            WHERE b.prodCode != b.prodCellCode
                                              AND a.secuBizTypeCode NOT IN('605', '606', '8070', '8071','8001', '8002', '8003', '8004') -- 排除卖交割(多头交割)、买交割(空头交割)
                                              AND a.settleDate >= @todayDate

  --产品单元资金证券流水历史总流水表(从产品资金证券流水历史总流水表派生)
  DELETE FROM sims2016TradeHist..prodCellRawJrnlHist WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                       AND settleDate BETWEEN @i_beginDate AND @i_endDate
                                                       AND dataSourceFlagCode = '0';

  INSERT sims2016TradeHist..prodCellRawJrnlHist(originSerialNO, settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode,
                                                hedgeFlagCode, coveredFlagCode, originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName,
                                                brokerJrnlSerialID, prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt,
                                                exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty,
                                                posiBalanceQty, matchNetPrice, dataSourceFlagCode, marketLevelCode, operatorCode, operateDatetime, operateRemarkText)
                                         SELECT a.serialNO, a.settleDate, a.secuBizTypeCode, a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode,
                                                a.hedgeFlagCode, a.coveredFlagCode, a.originSecuBizTypeCode, a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName,
                                                a.brokerJrnlSerialID, a.prodCode, b.prodCellCode, a.fundAcctCode, a.currencyCode, a.cashSettleAmt, a.cashBalanceAmt,
                                                a.exchangeCode, a.secuAcctCode, a.secuCode, a.originSecuCode, a.secuName, a.secuTradeTypeCode, a.matchQty,
                                                a.posiBalanceQty, a.matchNetPrice, a.dataSourceFlagCode, a.marketLevelCode, a.operatorCode, GETDATE(), a.operateRemarkText
                                           FROM sims2016TradeHist..prodRawJrnlHist a
                                           JOIN #prodCapitalF d ON a.prodCode = d.prodCode AND a.fundAcctCode = d.fundAcctCode
                                           JOIN #dataSyncRawJrnlF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode AND
                                                                      a.exchangeCode = b.exchangeCode AND a.secuCode = b.secuCode AND
                                                                      a.secuAcctCode = b.secuAcctCode AND a.settleDate = b.operateDate AND
                                                                      a.brokerJrnlSerialID = b.brokerJrnlSerialID
                                          WHERE b.prodCode != b.prodCellCode
                                            AND a.secuBizTypeCode NOT IN('605', '606', '8070', '8071', '8001', '8002', '8003', '8004') -- 排除卖交割(多头交割)、买交割(空头交割)
                                            AND a.settleDate BETWEEN @i_beginDate AND @i_endDate

  --产品单元资金证券流水表股票当日(纯交易流水:从产品单元资金证券流水当日总流水表派生)
  DELETE FROM sims2016TradeToday..prodCellRawJrnlFToday WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                          AND settleDate >= @todayDate
                                                          AND dataSourceFlagCode = '0'

  INSERT INTO sims2016TradeToday..prodCellRawJrnlFToday(serialNO, settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
                                                        originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID,
                                                        prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode,
                                                        secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty, posiBalanceQty,
                                                        matchNetPrice, matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID, brokerOriginOrderID,
                                                        brokerErrorMsg, dataSourceFlagCode, transactionNO, investPortfolioCode, assetLiabilityTypeCode, investInstrucNO, traderInstrucNO,
                                                        orderNO, marketLevelCode, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt, orderSettlePrice, orderTradeFeeAmt, directorCode,
                                                        traderCode, operatorCode, operateDatetime, operateRemarkText)
                                                 SELECT a.serialNO, a.settleDate, a.secuBizTypeCode, a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode, a.hedgeFlagCode,
                                                        a.originSecuBizTypeCode, a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName, a.brokerJrnlSerialID,
                                                        a.prodCode, b.prodCellCode, a.fundAcctCode, a.currencyCode, a.cashSettleAmt, a.cashBalanceAmt, a.exchangeCode,
                                                        a.secuAcctCode, a.secuCode, a.originSecuCode, a.secuName, a.secuTradeTypeCode, a.matchQty, a.posiBalanceQty,
                                                        b.matchNetPrice, b.matchNetAmt, b.matchTradeFeeAmt, b.matchDate, b.matchTime, b.matchID, b.brokerOrderID, b.brokerOriginOrderID,
                                                        b.brokerErrorMsg, a.dataSourceFlagCode, b.transactionNO, ISNULL(b.investPortfolioCode, ' '), b.assetLiabilityTypeCode, b.investInstrucNO, b.traderInstrucNO,
                                                        b.orderNO, b.marketLevelCode, b.orderNetAmt, b.orderNetPrice, b.orderQty, b.orderSettleAmt, b.orderSettlePrice, b.orderTradeFeeAmt, '',--b.directorCode,
                                                        b.traderCode, a.operatorCode, GETDATE(), a.operateRemarkText
                                                   FROM sims2016TradeToday..prodCellRawJrnlToday a
                                                   JOIN #prodCapitalF d ON a.prodCode = d.prodCode AND a.fundAcctCode = d.fundAcctCode
                                                   JOIN #dataSyncRawJrnlF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode AND
                                                                              a.exchangeCode = b.exchangeCode AND a.secuCode = b.secuCode AND
                                                                              a.secuAcctCode = b.secuAcctCode AND a.settleDate = b.operateDate AND
                                                                              a.brokerJrnlSerialID = b.brokerJrnlSerialID
                                                  WHERE a.prodCode != a.prodCellCode
                                                    AND a.secuBizTypeCode NOT IN('605', '606', '8070', '8071') -- 排除卖交割(多头交割)、买交割(空头交割)
                                                    AND a.settleDate >= @todayDate

  --产品单元资金证券流水表股票历史(纯交易流水:从产品单元资金证券流水历史总流水表派生)
  DELETE FROM sims2016TradeHist..prodCellRawJrnlFHist WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
                                                        AND settleDate BETWEEN @i_beginDate AND @i_endDate
                                                        AND dataSourceFlagCode = '0'

  INSERT sims2016TradeHist..prodCellRawJrnlFHist(serialNO, settleDate, secuBizTypeCode, buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode,
                                                 originSecuBizTypeCode, brokerSecuBizTypeCode, brokerSecuBizTypeName, brokerJrnlSerialID,
                                                 prodCode, prodCellCode, fundAcctCode, currencyCode, cashSettleAmt, cashBalanceAmt, exchangeCode,
                                                 secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode, matchQty, posiBalanceQty,
                                                 matchNetPrice, matchSettleAmt, matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID, brokerOriginOrderID,
                                                 brokerErrorMsg, dataSourceFlagCode, transactionNO, investPortfolioCode, assetLiabilityTypeCode, investInstrucNO, traderInstrucNO,
                                                 orderNO, marketLevelCode, orderNetAmt, orderNetPrice, orderQty, orderSettleAmt, orderSettlePrice, orderTradeFeeAmt, directorCode,
                                                 traderCode, operatorCode, operateDatetime, operateRemarkText)
                                          SELECT a.serialNO, a.settleDate, a.secuBizTypeCode, a.buySellFlagCode, a.bizSubTypeCode, a.openCloseFlagCode, a.hedgeFlagCode,
                                                 a.originSecuBizTypeCode, a.brokerSecuBizTypeCode, a.brokerSecuBizTypeName, a.brokerJrnlSerialID,
                                                 a.prodCode, a.prodCellCode, a.fundAcctCode, a.currencyCode, a.cashSettleAmt, a.cashBalanceAmt, a.exchangeCode,
                                                 a.secuAcctCode, a.secuCode, a.originSecuCode, a.secuName, a.secuTradeTypeCode, a.matchQty, a.posiBalanceQty,
                                                 ISNULL(b.matchNetPrice, 0), ISNULL(b.matchNetAmt, 0), ISNULL(b.matchTradeFeeAmt, 0), ISNULL(b.matchDate, ''), ISNULL(b.matchTime, ''), ISNULL(b.matchID, ''), b.brokerOrderID, b.brokerOriginOrderID,
                                                 b.brokerErrorMsg, a.dataSourceFlagCode, ISNULL(b.transactionNO, 0), ISNULL(b.investPortfolioCode, ' '), ISNULL(b.assetLiabilityTypeCode, '0'), ISNULL(b.investInstrucNO, 0), ISNULL(b.traderInstrucNO, 0),
                                                 ISNULL(b.orderNO, 0), ISNULL(b.marketLevelCode, '2'), ISNULL(b.orderNetAmt, 0), ISNULL(b.orderNetPrice, 0), ISNULL(b.orderQty, 0), ISNULL(b.orderSettleAmt, 0), ISNULL(b.orderSettlePrice, 0), ISNULL(b.orderTradeFeeAmt, 0), '',--b.directorCode,
                                                 ISNULL(b.traderCode, ''), a.operatorCode, GETDATE(), a.operateRemarkText
                                            FROM sims2016TradeHist..prodCellRawJrnlHist a
                                            JOIN #prodCapitalF d ON a.prodCode = d.prodCode AND a.fundAcctCode = d.fundAcctCode
                                            JOIN #dataSyncRawJrnlF b ON a.prodCode = b.prodCode AND a.fundAcctCode = b.fundAcctCode AND
                                                                        a.exchangeCode = b.exchangeCode AND a.secuCode = b.secuCode AND
                                                                        a.secuAcctCode = b.secuAcctCode AND a.settleDate = b.operateDate AND
                                                                        a.brokerJrnlSerialID = b.brokerJrnlSerialID
                                           WHERE a.prodCode != a.prodCellCode
                                             AND a.secuBizTypeCode NOT IN('605', '606', '8070', '8071') -- 排除卖交割(多头交割)、买交割(空头交割)
                                             AND a.settleDate BETWEEN @i_beginDate AND @i_endDate
  RETURN 0
go

