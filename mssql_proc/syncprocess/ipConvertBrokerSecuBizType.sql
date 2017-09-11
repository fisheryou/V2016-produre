USE sims2016Proc
go

IF OBJECT_ID(N'ipConvertBrokerSecuBizType',N'p') IS NOT NULL
  DROP PROC ipConvertBrokerSecuBizType
go

CREATE PROC ipConvertBrokerSecuBizType
  @i_operatorCode                     VARCHAR(30)      ,
  @i_operatorPassword                 VARCHAR(30)      ,
  @i_operateStationText               VARCHAR(600)     ,
  @i_brokerCounterVersionCode         VARCHAR(30)      ,           --��̨�汾����
  @i_fundAcctCode                     VARCHAR(30)      ,           --�ʽ��˻�����
  @i_currencyCode                     VARCHAR(4)       ,           --���Ҵ���
  @i_operateDate                      VARCHAR(10)      ,           --��������
  @o_brokerBizCode                    VARCHAR(30)   OUT,           --Ӫҵ����ҵ�����
  @o_brokerBizName                    VARCHAR(60)   OUT,           --Ӫҵ����ҵ������
  @o_cashCurrentSettleAmt             DECIMAL(19,4) OUT,           --�ʽ�����

  @o_exchangeCode                     VARCHAR(4)    OUT,           --����������
  @o_secuCode                         VARCHAR(30)   OUT,           --֤ȯ����
  @o_secuName                         VARCHAR(60)   OUT,           --֤ȯ����
  @o_tradeTypeCode                    VARCHAR(30)   OUT,           --֤ȯ����������
  @o_tradeUnitValue                   INT           OUT,           --���׵�λ
  @o_brokerTradeUnitValue             INT           OUT,           --Ӫҵ�����׵�λ
  @o_matchQty                         INT           OUT,           --�ɽ�����
  @o_matchNetPrice                    DECIMAL(19,4) OUT,           --�ɽ��۸�
  @o_matchNetAmt                      DECIMAL(19,4) OUT,           --�ɽ����
  @o_stampTaxAmt                      DECIMAL(19,4) OUT,           --ӡ��˰
  @o_commissionFeeAmt                 DECIMAL(19,4) OUT,           --������
  @o_transferFeeAmt                   DECIMAL(19,4) OUT,           --������
  @o_otherFeeAmt                      DECIMAL(19,4) OUT,           --��������

  @o_secuAcctCode                     VARCHAR(30)   OUT,           --֤ȯ�˻�����
  @o_brokerOrderID                    VARCHAR(30)   OUT,           --Ӫҵ���������
  @o_brokerRemarkText                 VARCHAR(600)  OUT,           --Ӫҵ����ע��Ϣ
  @o_bizTypeCode                    VARCHAR(30)   OUT            --����ɷ仢��ҵ�����
AS
  DECLARE 
  --�仢��ҵ�������룬����Ϊ��
  @outSecuBizTypeCode VARCHAR(30) = '',
  /* �仢���ʽ������ķ���
   * '=' ���ڽ���ͨ�����ʽ�����
   * '-' ���ڽ���ͨ�����ʽ��������෴��
   * '+' ���ڽ���ͨ�����ʽ������ľ���ֵ
   */
  @outCashSettleAmtRuleCode VARCHAR(30) = '',
  --����ͨ���Ľ��������룬���Զ�ѡ�����ŷָ�
  @exchangeCodeRuleCodes VARCHAR(255) = '',
  ----����ͨ����֤ȯ���������룬��Vϵ�У����Զ�ѡ�����ŷָ�����T��A��Jϵ�У����뵥ѡ
  @secuTradeTypeCodeCodes VARCHAR(255) = '',
  /* �仢�ĳɽ������ķ���
   * '=' ���ڽ���ͨ���ĳɽ�����
   * '-' ���ڽ���ͨ���ĳɽ��������෴��
   * '+' ���ڽ���ͨ���ĳɽ������ľ���ֵ
   * '0' ǿ��Ϊ0
   * '-abs' ����ֵ����
   * 'S' p_cjsl �� p_jydw
   * 'SS' p_cjsl �� p_yyb_jydw
   */
  @outMatchQtyRuleCode VARCHAR(255) = '',
  /* �仢�ĳɽ������ķ���
   * '=' ���ڽ���ͨ���ĳɽ����
   * '-' ���ڽ���ͨ���ĳɽ������෴��
   * '+' ���ڽ���ͨ���ĳɽ����ľ���ֵ
   * '0' ǿ��Ϊ0
   * 'PT' -- �ʽ����� + ����
   * 'HG' -- �Զ����� ������
   */
  @outMatchSettleAmtRuleCode VARCHAR(255)= '',
  /* �仢�ĳɽ��۸�ķ���
   * '=' ���ڽ���ͨ���ĳɽ�����
   * '-' ���ڽ���ͨ���ĳɽ��������෴��
   * '+' ���ڽ���ͨ���ĳɽ������ľ���ֵ
   * '0' ǿ��Ϊ0
   * 'PT' abs(@p_cjje / @p_cjsl)
   */
  @outMatchNetPriceRuleCode  VARCHAR(255)= '',
  /* �仢��֤ȯ�������ķ���
   * '=' ���ڽ���ͨ���ĳɽ�����
   * '-' ���ڽ���ͨ���ĳɽ��������෴��
   * '+' ���ڽ���ͨ���ĳɽ������ľ���ֵ
   * '0' ǿ��Ϊ0
   */
  @outPosiSettleQtyRuleCode VARCHAR(255) = '',
  --�仢���ʽ������ĳ���
  @outCashSettleAmtFactorValue INT = 1,
  --�仢�ĳɽ������ĳ���
  @outMatchQtyFactorValue INT = 1,
  --�仢�ĳɽ��۸�ĳ���
  @outMatchNetPriceFactorValue INT = 1,
  --�仢��֤ȯ�������ĳ���
  @outPosiSettleQtyFactorValue INT = 1,
  --�仢�ĳɽ����ĳ���
  @outMatchSettleAmtFactorValue INT = 1,
  /* �仢֤ȯҵ��������
   * '' ������
   * '֣����' ֣�����ڻ�����ת����֣�����ڻ�����Ϊ "���YMM"��̨���صĿ����� "���YYMM"
   * '��д' ��ĸת��Ϊ��д
   * 'Сд' ��ĸת��ΪСд
   */
  @outSecuCodeRuleCode VARCHAR(255) = '',
  --�仢��ͬ���, '' ������ 'ȥǰ׺' �н�ϵͳ��ʷ�ʽ���ˮ���غ�ͬ�����������ĸǰ׺
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

  IF @o_secuCode = '799998' --ָ�����׳���
    BEGIN
      SELECT @o_bizTypeCode = 'ZDJYCX', @o_tradeUnitValue = 1
      RETURN
    END
  ELSE IF @o_secuCode = '799999' --ָ�����׵Ǽ�
    BEGIN
      SELECT @o_bizTypeCode = 'ZDJYDJ', @o_tradeUnitValue = 1
      RETURN
    END
  ELSE IF @o_secuCode = '799996' --�ع�ָ������
    BEGIN
      SELECT @o_bizTypeCode = 'HGZDCX', @o_tradeUnitValue = 1
      RETURN
    END
  ELSE IF @o_secuCode = '799997' --�ع�ָ���Ǽ�
    BEGIN
      SELECT @o_bizTypeCode = 'HGZDDJ', @o_tradeUnitValue = 1
      RETURN
    END

  IF @o_matchQty = 0
    SELECT @o_tradeUnitValue = 0

  --��֤Bug
  IF (@i_brokerCounterVersionCode IN('KD20') OR @i_brokerCounterVersionCode LIKE 'KDJZJY%') AND @o_matchNetPrice >= 900
    SELECT @o_matchQty = @o_matchQty * 10, @o_matchNetPrice = @o_matchNetPrice / 10

  --����֤ȯ���н��װ����⴦��
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
      --��ҵ����롢ҵ�����Ʋ�Ϊ�գ�����ģ��ƥ����в���
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
      --��ҵ����롢ҵ�����Ʋ�Ϊ�գ�����ģ��ƥ����в���
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
      --��ҵ�����Ʋ�Ϊ�գ�����ģ��ƥ����в���
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

      --�ʽ�����
      IF @outCashSettleAmtRuleCode = '-'
        SELECT @o_cashCurrentSettleAmt = -(@o_cashCurrentSettleAmt)
      ELSE IF @outCashSettleAmtRuleCode = '+'
        SELECT @o_cashCurrentSettleAmt = ABS(@o_cashCurrentSettleAmt)
      ELSE IF @outCashSettleAmtRuleCode = '0'
        SELECT @o_cashCurrentSettleAmt = 0
      ELSE
        SELECT @o_cashCurrentSettleAmt = @o_cashCurrentSettleAmt

      SELECT @o_cashCurrentSettleAmt = @o_cashCurrentSettleAmt * ISNULL(@outCashSettleAmtFactorValue, 1)

      --�ɽ�����
      IF @outMatchQtyRuleCode = '-'
        SELECT @o_matchQty = -(@o_matchQty)
      ELSE IF @outMatchQtyRuleCode = '+'
        SELECT @o_matchQty = ABS(@o_matchQty)
      ELSE IF @outMatchQtyRuleCode = '0'
        SELECT @o_matchQty = 0
      ELSE IF @outMatchQtyRuleCode = '-abs'
        SELECT @o_matchQty = - ABS(@o_matchQty)
      ELSE IF @outMatchQtyRuleCode = 'S' AND @o_tradeUnitValue != 0 --����ת�� ������ҵ��_�걨����
        SELECT @o_matchQty = @o_matchQty * @o_tradeUnitValue
      ELSE IF @outMatchQtyRuleCode = 'SS' AND @o_tradeUnitValue != 0 --����ת�� ����֤ȯ
        BEGIN
          IF @o_brokerTradeUnitValue > 0
            SELECT @o_matchQty = @o_matchQty * @o_brokerTradeUnitValue
          ELSE
            SELECT @o_matchQty = @o_matchQty * @o_tradeUnitValue
        END
      ELSE
        SELECT @o_matchQty = @o_matchQty

      SELECT @o_matchQty = @o_matchQty * ISNULL(@outMatchQtyFactorValue, 1)

      --�ɽ����Ĵ���
      IF @outMatchSettleAmtRuleCode = '-'
        SELECT @o_matchNetAmt = -(@o_matchNetAmt);
      ELSE IF @outMatchSettleAmtRuleCode = '+'
        SELECT @o_matchNetAmt = ABS(@o_matchNetAmt);
      ELSE IF @outMatchSettleAmtRuleCode = '0'
        SELECT @o_matchNetAmt = 0;
      ELSE IF @outMatchSettleAmtRuleCode = 'PT' --'PT' �ʽ����� + ����
        IF @o_exchangeCode IS NOT NULL AND @o_secuCode IS NOT NULL AND @i_brokerCounterVersionCode NOT LIKE 'QH_%'
          SELECT @o_matchNetAmt = @o_matchNetAmt + @o_stampTaxAmt + @o_commissionFeeAmt + @o_transferFeeAmt + @o_otherFeeAmt
      ELSE IF @outMatchSettleAmtRuleCode = 'HG' -- 'HG' �Զ����� ������
        BEGIN
          SELECT @o_matchNetAmt = ABS(@o_matchQty) * 100 * SIGN(@o_cashCurrentSettleAmt);
          SELECT @o_commissionFeeAmt = ABS(@o_cashCurrentSettleAmt - @o_matchNetAmt);
        END
      ELSE
        SELECT @o_matchNetAmt = @o_matchNetAmt

      SELECT @o_matchNetAmt = @o_matchNetAmt * ISNULL(@outMatchSettleAmtFactorValue, 1)

      --�ɽ��۸�
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
             and dbo.fnCharIndexDh(@outSecuCodeRuleCode,'֣����') > 0
            SELECT @o_secuCode = LEFT(@o_secuCode, 2) + RIGHT(@o_secuCode, 3);

          IF dbo.fnCharIndexDh(@outSecuCodeRuleCode, '��д') > 0
            SELECT @o_secuCode = UPPER(@o_secuCode);
          
          IF dbo.fnCharIndexDh(@outSecuCodeRuleCode, 'Сд') > 0
            SELECT @o_secuCode = LOWER(@o_secuCode);
        END

      IF @outBrokerOrderIDRuleCode = 'ȥǰ׺' and @o_brokerOrderID not like '[0-9]%'
        SELECT @o_brokerOrderID = SUBSTRING(@o_brokerOrderID, 3, DATALENGTH(@o_brokerOrderID));

      IF @i_brokerCounterVersionCode = 'HSENP' and @o_brokerBizCode = '2324' --��Ϣ����˰����
        BEGIN
          SELECT @o_bizTypeCode = 'PXS'
          IF dbo.fnCharIndexDh(@o_brokerRemarkText, '��Ϣ����˰����') > 0 and dbo.fnCharIndexDh(@o_brokerRemarkText, '��˰��') > 0
            SELECT @o_secuCode = LTRIM(RTRIM(RIGHT(LEFT(@o_brokerRemarkText,19), 6)));
          ELSE IF dbo.fnCharIndexDh(@o_brokerRemarkText, '��Ϣ����˰����') > 0 and dbo.fnCharIndexDh(@o_brokerRemarkText, 'stock_code') > 0
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

  IF @o_matchQty > 300 and @i_brokerCounterVersionCode = 'KS_JZJY' and -- ���˴Ｏ�н��װ� ���⴦��
    (@o_tradeTypeCode in('DBT', 'DBEM', 'DBVE', 'DBCM', 'DBVW', 'DBG') or @o_bizTypeCode in('MRRZ', 'MCRQ', 'RZGH', 'RQGH'))
    SELECT @o_matchNetPrice = ABS(@o_matchNetAmt / @o_matchQty)

  IF @i_brokerCounterVersionCode = 'ZSZQ' --����֤ȯ���⴦��
    BEGIN
      select @eu_exchangeCode = exchangeCode from sims2016TradeToday..secuAcct where secuAcctCode = @o_secuAcctCode and fundAcctCode = @i_fundAcctCode;
      IF @eu_exchangeCode = 'OTCU'--�������
        BEGIN
          IF @o_cashCurrentSettleAmt > 0
            SELECT @o_bizTypeCode = '8090'; --�����ʽ�����
          ELSE IF @o_cashCurrentSettleAmt < 0
            SELECT @o_bizTypeCode = '8091'; --�����ʽ����
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

