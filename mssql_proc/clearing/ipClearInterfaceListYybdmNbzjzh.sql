USE sims2016Proc
go

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'ipClearInterfaceListYybdmNbzjzh')
  DROP PROC ipClearInterfaceListYybdmNbzjzh
go

CREATE PROC ipClearInterfaceListYybdmNbzjzh
  @p_exchangeCode VARCHAR(4) = '',    --交易所代码
  @p_secuAcctCode VARCHAR(30) = '',   --证券账户代码
  @p_seatID       VARCHAR(40) = '',     --席位代码
  @p_errormsg     VARCHAR(250) = '' OUT
AS
  SET NOCOUNT ON

  DECLARE @errorcode INT
  --返回交易所代码、席位代码、证券账户代码、营业部代码、资金账户代码、资金账户名称
  SELECT a.exchangeCode, c.seatID, a.secuAcctCode, a.brokerBranchCode, a.fundAcctCode, b.fundAcctName
         FROM sims2016TradeToday.dbo.secuAcct a
         INNER JOIN sims2016TradeToday.dbo.prodCapital b ON a.brokerBranchCode = b.brokerBranchCode AND a.fundAcctCode = b.fundAcctCode
         INNER JOIN sims2016TradeToday.dbo.brokerBranchSeat c ON b.brokerBranchCode = c.brokerBranchCode AND a.exchangeCode = c.exchangeCode
         WHERE a.exchangeCode NOT IN ('XZCE','CCFX','XDCE','XSGE')
           AND (a.exchangeCode = @p_exchangeCode OR @p_exchangeCode = '')
           AND (a.secuAcctCode = @p_secuAcctCode OR @p_exchangeCode = '')
           AND (c.seatID = @p_seatID OR @p_seatID = '')
         GROUP BY a.brokerBranchCode, a.secuAcctCode, a.exchangeCode, a.fundAcctCode, c.seatID, b.fundAcctName

  RETURN 0
go

