USE sims2016Proc
go

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'ipClearInterfaceGetYybdmNbzjzh')
  DROP PROC ipClearInterfaceGetYybdmNbzjzh
go

CREATE PROC ipClearInterfaceGetYybdmNbzjzh
  @p_exchangeCode     VARCHAR(4),     --����������
  @p_secuAcctCode     VARCHAR(30),      --֤ȯ�˻�����
  @p_seatID           VARCHAR(40),        --ϯλ����
  @p_errormsg         VARCHAR(250) OUT,
  @p_brokerBranchCode VARCHAR(4) OUT, --Ӫҵ������
  @p_fundAcctCode     VARCHAR(30) OUT   --�ʽ��˻�����
AS
  SET NOCOUNT ON

  DECLARE @errorcode INT, @seatID VARCHAR(40)
  SELECT @seatID = seatID FROM sims2016TradeToday.dbo.seatTable WHERE exchangeCode = @p_exchangeCode
 
  SELECT @p_brokerBranchCode = '', @p_fundAcctCode = '', @p_errormsg = ''

  SELECT @p_brokerBranchCode = brokerBranchCode FROM sims2016TradeToday.dbo.brokerBranchSeat WHERE exchangeCode = @p_exchangeCode AND seatID = @p_seatID-- or seatID = @seatID
  
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @errorcode = -100, @p_errormsg = 'Ӫҵ�����벻����'
      RETURN -100
    END

  SELECT @p_fundAcctCode = a.fundAcctCode
         FROM sims2016TradeToday.dbo.secuAcct a
         INNER JOIN sims2016TradeToday.dbo.prodCapital b ON a.fundAcctCode = b.fundAcctCode AND a.brokerBranchCode = b.brokerBranchCode
         WHERE a.brokerBranchCode = @p_brokerBranchCode
           AND a.exchangeCode = @p_exchangeCode
           AND a.secuAcctCode = @p_secuAcctCode
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @errorcode = -100, @p_errormsg = '�ʽ��˻�������'
      RETURN -100
    END

  RETURN 0
go

