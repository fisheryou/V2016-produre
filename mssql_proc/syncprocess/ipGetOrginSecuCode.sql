USE sims2016Proc
go

IF OBJECT_ID(N'ipGetOrginSecuCode', N'P') IS NOT NULL
  DROP PROC ipGetOrginSecuCode
go

--名称: ipGetOrginSecuCode
--功能: 获取原始证券代码
CREATE PROC ipGetOrginSecuCode
  @i_operatorCode            VARCHAR(30),       --操作员代码
  @i_operatorPassword        VARCHAR(30),       --操作员密码
  @i_operateStationText      VARCHAR(600),      --留痕信息
  @i_exchangeCode            VARCHAR(4),        --交易所代码
  @i_secuCode                VARCHAR(30),       --证券代码
  @i_operateDate             VARCHAR(10),       --发生日期
  @o_secuTradeTypeCode       VARCHAR(30) OUT,       --证券交易类别代码
  @o_originalSecuCode        VARCHAR(30) OUT        --原始证券代码
AS
  DECLARE @secuCodePrefixText VARCHAR(120), @secuCodeLen INT, @secuCodePrefixTextLen INT
  SELECT @secuCodePrefixText = ISNULL(LTRIM(RTRIM(secuCodePrefixText)), ''), @o_secuTradeTypeCode = secuTradeTypeCode
         FROM sims2016TradeToday..secuTmpl 
         WHERE exchangeCode = @i_exchangeCode AND @i_secuCode BETWEEN beginSecuCode AND endSecuCode
         ORDER BY beginSecuCode
  IF @@ROWCOUNT = 0
    BEGIN
      IF EXISTS (SELECT * FROM sims2016TradeToday..secuTable WHERE exchangeCode = @i_exchangeCode AND secuCode = @i_secuCode)
        SELECT @o_secuTradeTypeCode = secuTradeTypeCode FROM sims2016TradeToday..secuTable WHERE exchangeCode = @i_exchangeCode AND secuCode = @i_secuCode
      ELSE
        SELECT @o_secuTradeTypeCode = ''

      SELECT @o_originalSecuCode = @i_secuCode
      
      RETURN 0
    END

  IF EXISTS (SELECT * FROM sims2016TradeToday..secuTable WHERE exchangeCode = @i_exchangeCode AND secuCode = @i_secuCode)
      SELECT @o_secuTradeTypeCode = secuTradeTypeCode
             FROM sims2016TradeToday..secuTable
             WHERE exchangeCode = @i_exchangeCode AND secuCode = @i_secuCode

  IF @secuCodePrefixText != ''
    BEGIN
      SELECT @secuCodeLen = DATALENGTH(RTRIM(@i_secuCode)), @secuCodePrefixTextLen = DATALENGTH(RTRIM(@secuCodePrefixText))
      SELECT @o_originalSecuCode = LTRIM(RTRIM(@secuCodePrefixText)) + RIGHT(@i_secuCode, @secuCodeLen - @secuCodePrefixTextLen)
    end
  ELSE
    SELECT @o_originalSecuCode = @i_secuCode

  RETURN 0
go

