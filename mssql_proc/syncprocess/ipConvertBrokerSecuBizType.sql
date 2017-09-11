USE sims2016Proc
go

IF OBJECT_ID(N'ipConvertBrokerSecuBizType',N'p') IS NOT NULL
  DROP PROC ipConvertBrokerSecuBizType
go

CREATE PROC ipConvertBrokerSecuBizType
  @i_operatorCode                     VARCHAR(30)      ,
  @i_operatorPassword                 VARCHAR(30)      ,
  @i_operateStationText               VARCHAR(600)     ,
  @i_brokerCounterVersionCode         VARCHAR(30)      ,           --柜台版本代码
  @i_fundAcctCode                     VARCHAR(30)      ,           --资金账户代码
  @i_currencyCode                     VARCHAR(4)       ,           --货币代码
  @i_operateDate                      VARCHAR(10)      ,           --发生日期
  @o_brokerBizCode                    VARCHAR(30)   OUT,           --营业部的业务代码
  @o_brokerBizName                    VARCHAR(60)   OUT,           --营业部的业务名称
  @o_cashCurrentSettleAmt             DECIMAL(19,4) OUT,           --资金发生数

  @o_exchangeCode                     VARCHAR(4)    OUT,           --交易所代码
  @o_secuCode                         VARCHAR(30)   OUT,           --证券代码
  @o_secuName                         VARCHAR(60)   OUT,           --证券名称
  @o_tradeTypeCode                    VARCHAR(30)   OUT,           --证券交易类别代码
  @o_tradeUnitValue                   INT           OUT,           --交易单位
  @o_brokerTradeUnitValue             INT           OUT,           --营业部交易单位
  @o_matchQty                         INT           OUT,           --成交数量
  @o_matchNetPrice                    DECIMAL(19,4) OUT,           --成交价格
  @o_matchNetAmt                      DECIMAL(19,4) OUT,           --成交金额
  @o_stampTaxAmt                      DECIMAL(19,4) OUT,           --印花税
  @o_commissionFeeAmt                 DECIMAL(19,4) OUT,           --手续费
  @o_transferFeeAmt                   DECIMAL(19,4) OUT,           --过户费
  @o_otherFeeAmt                      DECIMAL(19,4) OUT,           --其他费用

  @o_secuAcctCode                     VARCHAR(30)   OUT,           --证券账户代码
  @o_brokerOrderID                    VARCHAR(30)   OUT,           --营业部订单编号
  @o_brokerRemarkText                 VARCHAR(600)  OUT,           --营业部备注信息
  @o_bizTypeCode                    VARCHAR(30)   OUT            --翻译成蜂虎的业务类别
AS
  DECLARE 
  --蜂虎的业务类别代码，不能为空
  @outSecuBizTypeCode VARCHAR(30) = '',
  /* 蜂虎的资金发生数的符号
   * '=' 等于交易通道的资金发生数
   * '-' 等于交易通道的资金发生数的相反数
   * '+' 等于交易通道的资金发生数的绝对值
   */
  @outCashSettleAmtRuleCode VARCHAR(30) = '',
  --交易通道的交易所代码，可以多选，逗号分隔
  @exchangeCodeRuleCodes VARCHAR(255) = '',
  ----交易通道的证券交易类别代码，对V系列，可以多选，逗号分隔；对T、A、J系列，必须单选
  @secuTradeTypeCodeCodes VARCHAR(255) = '',
  /* 蜂虎的成交数量的符号
   * '=' 等于交易通道的成交数量
   * '-' 等于交易通道的成交数量的相反数
   * '+' 等于交易通道的成交数量的绝对值
   * '0' 强制为0
   * '-abs' 绝对值负数
   * 'S' p_cjsl 成 p_jydw
   * 'SS' p_cjsl 成 p_yyb_jydw
   */
  @outMatchQtyRuleCode VARCHAR(255) = '',
  /* 蜂虎的成交数量的符号
   * '=' 等于交易通道的成交金额
   * '-' 等于交易通道的成交金额的相反数
   * '+' 等于交易通道的成交金额的绝对值
   * '0' 强制为0
   * 'PT' -- 资金发生数 + 费用
   * 'HG' -- 自动计算 手续费
   */
  @outMatchSettleAmtRuleCode VARCHAR(255)= '',
  /* 蜂虎的成交价格的符号
   * '=' 等于交易通道的成交数量
   * '-' 等于交易通道的成交数量的相反数
   * '+' 等于交易通道的成交数量的绝对值
   * '0' 强制为0
   * 'PT' abs(@p_cjje / @p_cjsl)
   */
  @outMatchNetPriceRuleCode  VARCHAR(255)= '',
  /* 蜂虎的证券发生数的符号
   * '=' 等于交易通道的成交数量
   * '-' 等于交易通道的成交数量的相反数
   * '+' 等于交易通道的成交数量的绝对值
   * '0' 强制为0
   */
  @outPosiSettleQtyRuleCode VARCHAR(255) = '',
  --蜂虎的资金发生数的乘数
  @outCashSettleAmtFactorValue INT = 1,
  --蜂虎的成交数量的乘数
  @outMatchQtyFactorValue INT = 1,
  --蜂虎的成交价格的乘数
  @outMatchNetPriceFactorValue INT = 1,
  --蜂虎的证券发生数的乘数
  @outPosiSettleQtyFactorValue INT = 1,
  --蜂虎的成交金额的乘数
  @outMatchSettleAmtFactorValue INT = 1,
  /* 蜂虎证券业务类别代码
   * '' 不处理
   * '郑商所' 郑商所期货代码转换，郑商所期货代码为 "编号YMM"柜台返回的可能是 "编号YYMM"
   * '大写' 字母转换为大写
   * '小写' 字母转换为小写
   */
  @outSecuCodeRuleCode VARCHAR(255) = '',
  --蜂虎合同序号, '' 不处理 '去前缀' 中金系统历史资金流水返回合同序号增加了字母前缀
  @outBrokerOrderIDRuleCode VARCHAR(255) = '',

  @exchangeCode_temp VARCHAR(4) = '',
  @secuName_temp VARCHAR(30) = '',
  @findRow INT = 0,
  @eu_exchangeCode VARCHAR(4) = ''

  SELECT @o_brokerBizCode = LTRIM(RTRIM(@o_brokerBizCode)), @o_brokerBizName = LTRIM(RTRIM(@o_brokerBizName))
  
  IF @o_cashCurrentSettleAmt > 0
    SELECT @o_bizTypeCode = '8090'
  ELSE IF @o_cashCurrentSettleAmt < 0
    SELECT @o_bizTypeCode = '8091'
  ELSE
    SELECT @o_bizTypeCode = '9000'

  IF @o_secuCode = '799998' --指定交易撤销
    BEGIN
      SELECT @o_bizTypeCode = 'ZDJYCX', @o_tradeUnitValue = 1
      RETURN
    END
  ELSE IF @o_secuCode = '799999' --指定交易登记
    BEGIN
      SELECT @o_bizTypeCode = 'ZDJYDJ', @o_tradeUnitValue = 1
      RETURN
    END
  ELSE IF @o_secuCode = '799996' --回购指定撤销
    BEGIN
      SELECT @o_bizTypeCode = 'HGZDCX', @o_tradeUnitValue = 1
      RETURN
    END
  ELSE IF @o_secuCode = '799997' --回购指定登记
    BEGIN
      SELECT @o_bizTypeCode = 'HGZDDJ', @o_tradeUnitValue = 1
      RETURN
    END

  IF @o_matchQty = 0
    SELECT @o_tradeUnitValue = 0

  --金证Bug
  IF (@i_brokerCounterVersionCode IN('KD20') OR @i_brokerCounterVersionCode LIKE 'KDJZJY%') AND @o_matchNetPrice >= 900
    SELECT @o_matchQty = @o_matchQty * 10, @o_matchNetPrice = @o_matchNetPrice / 10

  --招商证券集中交易版特殊处理
  IF @i_brokerCounterVersionCode = 'ZSZQ'
    BEGIN
      SELECT @exchangeCode_temp = exchangeCode, @secuName_temp = secuName
             FROM sims2016TradeToday..secuTable
             WHERE exchangeCode = @o_exchangeCode AND secuCode = @o_secuCode
      IF @secuName_temp IS NOT NULL
        SELECT @o_exchangeCode = @exchangeCode_temp, @o_secuName = @secuName_temp
    END

  IF @o_brokerBizCode != '' AND @o_brokerBizName != ''
    BEGIN
      --按业务代码、业务名称不为空，其他模糊匹配进行查找
      SELECT @outSecuBizTypeCode = outSecuBizTypeCode, @outCashSettleAmtRuleCode = outCashSettleAmtRuleCode, @exchangeCodeRuleCodes = exchangeCodeRuleCodes,
             @secuTradeTypeCodeCodes = secuTradeTypeCodeRuleCodes, @outMatchQtyRuleCode = outMatchQtyRuleCode, @outMatchSettleAmtRuleCode = outMatchSettleAmtRuleCode,
             @outMatchNetPriceRuleCode = outMatchNetPriceRuleCode, @outPosiSettleQtyRuleCode = outPosiSettleQtyRuleCode, @outCashSettleAmtFactorValue = outCashSettleAmtFactorValue,
             @outMatchQtyFactorValue = outMatchQtyFactorValue, @outMatchNetPriceFactorValue = outMatchNetPriceFactorValue, @outPosiSettleQtyFactorValue = outPosiSettleQtyFactorValue,
             @outMatchSettleAmtFactorValue = outMatchSettleAmtFactorValue, @outSecuCodeRuleCode = outSecuCodeRuleCode, @outBrokerOrderIDRuleCode = outBrokerOrderIDRuleCode
             FROM sims2016TradeToday..brokerSecuBizTypeRule
             WHERE brokerCounterVersionCode = @i_brokerCounterVersionCode
               AND inSecuBizTypeCodes = @o_brokerBizCode
               AND inSecuBizTypeNames = @o_brokerBizName
               AND (inCashSettleAmtRuleCode = '' OR
                    (inCashSettleAmtRuleCode = '=' AND inCashSettleAmt = @o_cashCurrentSettleAmt) OR
                    (inCashSettleAmtRuleCode = '>' AND inCashSettleAmt > @o_cashCurrentSettleAmt) OR
                    (inCashSettleAmtRuleCode = '>=' AND inCashSettleAmt >= @o_cashCurrentSettleAmt) OR
                    (inCashSettleAmtRuleCode = '<=' AND inCashSettleAmt <= @o_cashCurrentSettleAmt) OR
                    (inCashSettleAmtRuleCode = '<' AND inCashSettleAmt < @o_cashCurrentSettleAmt) OR
                    (inCashSettleAmtRuleCode = '!=' AND inCashSettleAmt != @o_cashCurrentSettleAmt)
                   )
               AND (inExchangeCodes = '' OR
                    (inExchangeCodes IS NOT NULL AND dbo.fnCharIndexDh(inExchangeCodes, @o_exchangeCode ) > 0)
                   )
               AND (inSecuNames = '' OR
                    dbo.fnCharIndexDh(inSecuNames, @o_secuName) > 0 OR
                    inSecuNames LIKE '%[%]%' AND @o_secuName LIKE inSecuNames
                   )
               AND (inSecuTradeRuleCodes = '' OR
                    dbo.fnCharIndexDh(inSecuTradeRuleCodes, @o_tradeTypeCode) > 0 OR
                    (inSecuTradeRuleCodes LIKE '%[%]%' AND @o_tradeTypeCode LIKE inSecuTradeRuleCodes)
                   )
               AND (inMatchQtyRuleCode = '' OR
                    (inMatchQtyRuleCode = '=' AND inMatchQty = @o_matchQty) OR
                    (inMatchQtyRuleCode = '>' AND inMatchQty > @o_matchQty) OR
                    (inMatchQtyRuleCode = '>=' AND inMatchQty >= @o_matchQty) OR
                    (inMatchQtyRuleCode = '<=' AND inMatchQty <= @o_matchQty) OR
                    (inMatchQtyRuleCode = '<' AND inMatchQty < @o_matchQty) OR
                    (inMatchQtyRuleCode = '!=' AND inMatchQty != @o_matchQty)
                   )
               AND (inMatchSettleAmtRuleCode = '' OR
                    (inMatchSettleAmtRuleCode = '=' AND inMatchSettleAmt = @o_matchNetAmt) OR
                    (inMatchSettleAmtRuleCode = '>' AND inMatchSettleAmt > @o_matchNetAmt) OR
                    (inMatchSettleAmtRuleCode = '>=' AND inMatchSettleAmt >= @o_matchNetAmt) OR
                    (inMatchSettleAmtRuleCode = '<=' AND inMatchSettleAmt <= @o_matchNetAmt) OR
                    (inMatchSettleAmtRuleCode = '<' AND inMatchSettleAmt < @o_matchNetAmt) OR
                    (inMatchSettleAmtRuleCode = '!=' AND inMatchSettleAmt != @o_matchNetAmt)
                   )
             ORDER BY inSecuBizTypeCodes, priorityLevelValue;
      SELECT @findRow = @@ROWCOUNT
    END

  IF @findRow = 0
    BEGIN
      --按业务代码、业务名称不为空，其他模糊匹配进行查找
      IF @o_brokerBizCode != '' AND @o_brokerBizName = ''
        BEGIN
          SELECT @outSecuBizTypeCode = outSecuBizTypeCode, @outCashSettleAmtRuleCode = outCashSettleAmtRuleCode, @exchangeCodeRuleCodes = exchangeCodeRuleCodes,
                 @secuTradeTypeCodeCodes = secuTradeTypeCodeRuleCodes, @outMatchQtyRuleCode = outMatchQtyRuleCode, @outMatchSettleAmtRuleCode = outMatchSettleAmtRuleCode,
                 @outMatchNetPriceRuleCode = outMatchNetPriceRuleCode, @outPosiSettleQtyRuleCode = outPosiSettleQtyRuleCode, @outCashSettleAmtFactorValue = outCashSettleAmtFactorValue,
                 @outMatchQtyFactorValue = outMatchQtyFactorValue, @outMatchNetPriceFactorValue = outMatchNetPriceFactorValue, @outPosiSettleQtyFactorValue = outPosiSettleQtyFactorValue,
                 @outMatchSettleAmtFactorValue = outMatchSettleAmtFactorValue, @outSecuCodeRuleCode = outSecuCodeRuleCode, @outBrokerOrderIDRuleCode = outBrokerOrderIDRuleCode
                 FROM sims2016TradeToday..brokerSecuBizTypeRule
                 WHERE brokerCounterVersionCode = @i_brokerCounterVersionCode
                   AND inSecuBizTypeCodes = @o_brokerBizCode
                   AND (inCashSettleAmtRuleCode = '' OR
                        (inCashSettleAmtRuleCode = '=' AND inCashSettleAmt = @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '>' AND inCashSettleAmt > @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '>=' AND inCashSettleAmt >= @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '<=' AND inCashSettleAmt <= @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '<' AND inCashSettleAmt < @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '!=' AND inCashSettleAmt != @o_cashCurrentSettleAmt)
                       )
                   AND (inExchangeCodes = '' OR
                        (inExchangeCodes IS NOT NULL AND dbo.fnCharIndexDh(inExchangeCodes, @o_exchangeCode ) > 0)
                       )
                   AND (inSecuNames = '' OR
                        dbo.fnCharIndexDh(inSecuNames, @o_secuName) > 0 OR
                        inSecuNames LIKE '%[%]%' AND @o_secuName LIKE inSecuNames
                       )
                   AND (inSecuTradeRuleCodes = '' OR
                        dbo.fnCharIndexDh(inSecuTradeRuleCodes, @o_tradeTypeCode) > 0 OR
                        (inSecuTradeRuleCodes LIKE '%[%]%' AND @o_tradeTypeCode LIKE inSecuTradeRuleCodes)
                       )
                   AND (inMatchQtyRuleCode = '' OR
                        (inMatchQtyRuleCode = '=' AND inMatchQty = @o_matchQty) OR
                        (inMatchQtyRuleCode = '>' AND inMatchQty > @o_matchQty) OR
                        (inMatchQtyRuleCode = '>=' AND inMatchQty >= @o_matchQty) OR
                        (inMatchQtyRuleCode = '<=' AND inMatchQty <= @o_matchQty) OR
                        (inMatchQtyRuleCode = '<' AND inMatchQty < @o_matchQty) OR
                        (inMatchQtyRuleCode = '!=' AND inMatchQty != @o_matchQty)
                       )
                   AND (inMatchSettleAmtRuleCode = '' OR
                        (inMatchSettleAmtRuleCode = '=' AND inMatchSettleAmt = @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '>' AND inMatchSettleAmt > @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '>=' AND inMatchSettleAmt >= @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '<=' AND inMatchSettleAmt <= @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '<' AND inMatchSettleAmt < @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '!=' AND inMatchSettleAmt != @o_matchNetAmt)
                       )
                 ORDER BY inSecuBizTypeCodes, priorityLevelValue;
          SELECT @findRow = @@ROWCOUNT;
        END
    END

  IF @findRow = 0
    BEGIN
      --按业务名称不为空，其他模糊匹配进行查找
      IF @o_brokerBizName != '' AND @o_brokerBizCode = ''
        BEGIN
          SELECT @outSecuBizTypeCode = outSecuBizTypeCode, @outCashSettleAmtRuleCode = outCashSettleAmtRuleCode, @exchangeCodeRuleCodes = exchangeCodeRuleCodes,
                 @secuTradeTypeCodeCodes = secuTradeTypeCodeRuleCodes, @outMatchQtyRuleCode = outMatchQtyRuleCode, @outMatchSettleAmtRuleCode = outMatchSettleAmtRuleCode,
                 @outMatchNetPriceRuleCode = outMatchNetPriceRuleCode, @outPosiSettleQtyRuleCode = outPosiSettleQtyRuleCode, @outCashSettleAmtFactorValue = outCashSettleAmtFactorValue,
                 @outMatchQtyFactorValue = outMatchQtyFactorValue, @outMatchNetPriceFactorValue = outMatchNetPriceFactorValue, @outPosiSettleQtyFactorValue = outPosiSettleQtyFactorValue,
                 @outMatchSettleAmtFactorValue = outMatchSettleAmtFactorValue, @outSecuCodeRuleCode = outSecuCodeRuleCode, @outBrokerOrderIDRuleCode = outBrokerOrderIDRuleCode
                 FROM sims2016TradeToday..brokerSecuBizTypeRule
                 WHERE brokerCounterVersionCode = @i_brokerCounterVersionCode
                   AND inSecuBizTypeNames = @o_brokerBizName
                   AND (inCashSettleAmtRuleCode = '' OR
                        (inCashSettleAmtRuleCode = '=' AND inCashSettleAmt = @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '>' AND inCashSettleAmt > @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '>=' AND inCashSettleAmt >= @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '<=' AND inCashSettleAmt <= @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '<' AND inCashSettleAmt < @o_cashCurrentSettleAmt) OR
                        (inCashSettleAmtRuleCode = '!=' AND inCashSettleAmt != @o_cashCurrentSettleAmt)
                       )
                   AND (inExchangeCodes = '' OR
                        (inExchangeCodes IS NOT NULL AND dbo.fnCharIndexDh(inExchangeCodes, @o_exchangeCode ) > 0)
                       )
                   AND (inSecuNames = '' OR
                        dbo.fnCharIndexDh(inSecuNames, @o_secuName) > 0 OR
                        inSecuNames LIKE '%[%]%' AND @o_secuName LIKE inSecuNames
                       )
                   AND (inSecuTradeRuleCodes = '' OR
                        dbo.fnCharIndexDh(inSecuTradeRuleCodes, @o_tradeTypeCode) > 0 OR
                        (inSecuTradeRuleCodes LIKE '%[%]%' AND @o_tradeTypeCode LIKE inSecuTradeRuleCodes)
                       )
                   AND (inMatchQtyRuleCode = '' OR
                        (inMatchQtyRuleCode = '=' AND inMatchQty = @o_matchQty) OR
                        (inMatchQtyRuleCode = '>' AND inMatchQty > @o_matchQty) OR
                        (inMatchQtyRuleCode = '>=' AND inMatchQty >= @o_matchQty) OR
                        (inMatchQtyRuleCode = '<=' AND inMatchQty <= @o_matchQty) OR
                        (inMatchQtyRuleCode = '<' AND inMatchQty < @o_matchQty) OR
                        (inMatchQtyRuleCode = '!=' AND inMatchQty != @o_matchQty)
                       )
                   AND (inMatchSettleAmtRuleCode = '' OR
                        (inMatchSettleAmtRuleCode = '=' AND inMatchSettleAmt = @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '>' AND inMatchSettleAmt > @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '>=' AND inMatchSettleAmt >= @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '<=' AND inMatchSettleAmt <= @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '<' AND inMatchSettleAmt < @o_matchNetAmt) OR
                        (inMatchSettleAmtRuleCode = '!=' AND inMatchSettleAmt != @o_matchNetAmt)
                       )
                 ORDER BY inSecuBizTypeCodes, priorityLevelValue;
          SELECT @findRow = @@ROWCOUNT;
        END
    END

  IF @findRow = 1
    BEGIN
      SELECT @o_bizTypeCode = @outSecuBizTypeCode
      IF @outSecuCodeRuleCode = '='
        SELECT @o_bizTypeCode = @o_brokerBizCode

      --资金发生数
      IF @outCashSettleAmtRuleCode = '-'
        SELECT @o_cashCurrentSettleAmt = -(@o_cashCurrentSettleAmt)
      ELSE IF @outCashSettleAmtRuleCode = '+'
        SELECT @o_cashCurrentSettleAmt = ABS(@o_cashCurrentSettleAmt)
      ELSE IF @outCashSettleAmtRuleCode = '0'
        SELECT @o_cashCurrentSettleAmt = 0
      ELSE
        SELECT @o_cashCurrentSettleAmt = @o_cashCurrentSettleAmt

      SELECT @o_cashCurrentSettleAmt = @o_cashCurrentSettleAmt * ISNULL(@outCashSettleAmtFactorValue, 1)

      --成交数量
      IF @outMatchQtyRuleCode = '-'
        SELECT @o_matchQty = -(@o_matchQty)
      ELSE IF @outMatchQtyRuleCode = '+'
        SELECT @o_matchQty = ABS(@o_matchQty)
      ELSE IF @outMatchQtyRuleCode = '0'
        SELECT @o_matchQty = 0
      ELSE IF @outMatchQtyRuleCode = '-abs'
        SELECT @o_matchQty = - ABS(@o_matchQty)
      ELSE IF @outMatchQtyRuleCode = 'S' AND @o_tradeUnitValue != 0 --按手转换 恒生企业版_申报按手
        SELECT @o_matchQty = @o_matchQty * @o_tradeUnitValue
      ELSE IF @outMatchQtyRuleCode = 'SS' AND @o_tradeUnitValue != 0 --按手转换 招商证券
        BEGIN
          IF @o_brokerTradeUnitValue > 0
            SELECT @o_matchQty = @o_matchQty * @o_brokerTradeUnitValue
          ELSE
            SELECT @o_matchQty = @o_matchQty * @o_tradeUnitValue
        END
      ELSE
        SELECT @o_matchQty = @o_matchQty

      SELECT @o_matchQty = @o_matchQty * ISNULL(@outMatchQtyFactorValue, 1)

      --成交金额的处理
      IF @outMatchSettleAmtRuleCode = '-'
        SELECT @o_matchNetAmt = -(@o_matchNetAmt);
      ELSE IF @outMatchSettleAmtRuleCode = '+'
        SELECT @o_matchNetAmt = ABS(@o_matchNetAmt);
      ELSE IF @outMatchSettleAmtRuleCode = '0'
        SELECT @o_matchNetAmt = 0;
      ELSE IF @outMatchSettleAmtRuleCode = 'PT' --'PT' 资金发生数 + 费用
        IF @o_exchangeCode IS NOT NULL AND @o_secuCode IS NOT NULL AND @i_brokerCounterVersionCode NOT LIKE 'QH_%'
          SELECT @o_matchNetAmt = @o_matchNetAmt + @o_stampTaxAmt + @o_commissionFeeAmt + @o_transferFeeAmt + @o_otherFeeAmt
      ELSE IF @outMatchSettleAmtRuleCode = 'HG' -- 'HG' 自动计算 手续费
        BEGIN
          SELECT @o_matchNetAmt = ABS(@o_matchQty) * 100 * SIGN(@o_cashCurrentSettleAmt);
          SELECT @o_commissionFeeAmt = ABS(@o_cashCurrentSettleAmt - @o_matchNetAmt);
        END
      ELSE
        SELECT @o_matchNetAmt = @o_matchNetAmt

      SELECT @o_matchNetAmt = @o_matchNetAmt * ISNULL(@outMatchSettleAmtFactorValue, 1)

      --成交价格
      IF (@exchangeCodeRuleCodes IS NULL OR dbo.fnCharIndexDh(@exchangeCodeRuleCodes, @o_exchangeCode) > 0) and
         (@secuTradeTypeCodeCodes IS NULL OR dbo.fnCharIndexDh(@secuTradeTypeCodeCodes, @o_tradeTypeCode) > 0)
        BEGIN
          IF @outMatchNetPriceRuleCode = '-'
            SELECT @o_matchNetPrice = -(@o_matchNetPrice)
          ELSE IF @outMatchNetPriceRuleCode = '+'
            SELECT @o_matchNetPrice = ABS(@o_matchNetPrice)
          ELSE IF @outMatchNetPriceRuleCode = '0'
            SELECT @o_matchNetPrice = 0
          ELSE
            SELECT @o_matchNetPrice = @o_matchNetPrice
        END
      SELECT @o_matchNetPrice = ISNULL(@o_matchNetPrice, 0) * ISNULL(@outMatchNetPriceFactorValue, 1);
    
      IF ISNULL(@outSecuBizTypeCode, '') IS NOT NULL
        BEGIN
          IF @o_exchangeCode = 'XZCE' and @o_tradeTypeCode like 'F%' and @o_secuCode like '%[0-9][0-9][0-9][0-9]' 
             and dbo.fnCharIndexDh(@outSecuCodeRuleCode,'郑商所') > 0
            SELECT @o_secuCode = LEFT(@o_secuCode, 2) + RIGHT(@o_secuCode, 3);

          IF dbo.fnCharIndexDh(@outSecuCodeRuleCode, '大写') > 0
            SELECT @o_secuCode = UPPER(@o_secuCode);
          
          IF dbo.fnCharIndexDh(@outSecuCodeRuleCode, '小写') > 0
            SELECT @o_secuCode = LOWER(@o_secuCode);
        END

      IF @outBrokerOrderIDRuleCode = '去前缀' and @o_brokerOrderID not like '[0-9]%'
        SELECT @o_brokerOrderID = SUBSTRING(@o_brokerOrderID, 3, DATALENGTH(@o_brokerOrderID));

      IF @i_brokerCounterVersionCode = 'HSENP' and @o_brokerBizCode = '2324' --股息红利税补缴
        BEGIN
          SELECT @o_bizTypeCode = 'PXS'
          IF dbo.fnCharIndexDh(@o_brokerRemarkText, '股息红利税补缴') > 0 and dbo.fnCharIndexDh(@o_brokerRemarkText, '计税日') > 0
            SELECT @o_secuCode = LTRIM(RTRIM(RIGHT(LEFT(@o_brokerRemarkText,19), 6)));
          ELSE IF dbo.fnCharIndexDh(@o_brokerRemarkText, '股息红利税补缴') > 0 and dbo.fnCharIndexDh(@o_brokerRemarkText, 'stock_code') > 0
            SELECT @o_secuCode = LTRIM(RTRIM(RIGHT(@o_brokerRemarkText, 6)));
        END
    END
  ELSE
    BEGIN
      IF @o_cashCurrentSettleAmt > 0
        SELECT @o_bizTypeCode = '8090'
      ELSE IF @o_cashCurrentSettleAmt < 0
        SELECT @o_bizTypeCode = '8091'
      ELSE
        SELECT @o_bizTypeCode = '9000'
    END

  IF @o_matchQty > 300 and @i_brokerCounterVersionCode = 'KS_JZJY' and -- 金仕达集中交易版 特殊处理
    (@o_tradeTypeCode in('DBT', 'DBEM', 'DBVE', 'DBCM', 'DBVW', 'DBG') or @o_bizTypeCode in('MRRZ', 'MCRQ', 'RZGH', 'RQGH'))
    SELECT @o_matchNetPrice = ABS(@o_matchNetAmt / @o_matchQty)

  IF @i_brokerCounterVersionCode = 'ZSZQ' --招商证券特殊处理
    BEGIN
      select @eu_exchangeCode = exchangeCode from sims2016TradeToday..secuAcct where secuAcctCode = @o_secuAcctCode and fundAcctCode = @i_fundAcctCode;
      IF @eu_exchangeCode = 'OTCU'--场外基金
        BEGIN
          IF @o_cashCurrentSettleAmt > 0
            SELECT @o_bizTypeCode = '8090'; --其他资金增加
          ELSE IF @o_cashCurrentSettleAmt < 0
            SELECT @o_bizTypeCode = '8091'; --其他资金减少
        END
      
      IF @o_brokerBizCode IN ('XYZJDJ', 'XYZJJD','8MC')
        SELECT @o_cashCurrentSettleAmt = 0;

      IF @o_matchNetAmt = 0 AND @o_cashCurrentSettleAmt != 0 and @o_matchNetPrice != 0
        SELECT @o_matchNetAmt = @o_cashCurrentSettleAmt + @o_stampTaxAmt + @o_commissionFeeAmt + @o_transferFeeAmt + @o_otherFeeAmt;
    END

  SELECT @o_brokerTradeUnitValue = 1

  IF @o_exchangeCode = 'XZCE'
    IF @o_secuCode like '[a-zA-Z][a-zA-Z][0-9][0-9][0-9][0-9]'
      SELECT @o_secuCode = LEFT(@o_secuCode, 2) + RIGHT(@o_secuCode,3);

  RETURN 0
go

