USE sims2016Proc
go

IF OBJECT_ID(N'opDoDataSync', N'P') IS NOT NULL
  DROP PROC opDoDataSync
go

--EXEC opDoDataSync @O_ERRORMSGCODE, @O_ERRORMSGTEXT, '9999', '', '', '9999-01', '2017-03-13', '2017-03-20', '1', '1'
CREATE PROC opDoDataSync
  @O_ERRORMSGCODE                    INT            OUT, --������Ϣ����[yugy20170104]
  @O_ERRORMSGTEXT                    VARCHAR(600)   OUT, --������Ϣ�ı�[yugy20170104]
  @i_operatorCode                    VARCHAR(30)       , --����Ա����
  @i_operatorPassword                VARCHAR(30)       , --����Ա����
  @i_operateStationText              VARCHAR(600)      , --������Ϣ
  @i_fundAcctCode                    VARCHAR(30)       , --�ʽ��˻�����
  @i_beginDate                       VARCHAR(10)       , --ͬ����ʼ����
  @i_endDate                         VARCHAR(10)       , --ͬ����������
  @i_selected_rawJrnl                VARCHAR(30)       , --�Ƿ�ѡ���ʽ���ˮͬ��   '0' ��  '1' �ǣ�������ʷ���ݴ�����Oracle�д���
  @i_selected_dealHist               VARCHAR(30)         --�Ƿ�ѡ����ʷ�ɽ�ͬ��   '0' ��  '1' �ǣ�������ʷ���ݴ�����Oracle�д���
AS
  DECLARE
  @brokerBranchCode VARCHAR(30), @currencyCode VARCHAR(4), @counterVersionCode VARCHAR(30), @innerCounterVersionCode VARCHAR(30),
  @procName VARCHAR(30), @sqlStr VARCHAR(4096), @findRow INT, @sqlCode INT, @sqlErrM VARCHAR(2048), @fundAcctTypeCode VARCHAR(1),
  @tempDate VARCHAR(10), @todayDate VARCHAR(10)

  SELECT @todayDate = CONVERT(VARCHAR(10), GETDATE(), 120)
  SELECT @findRow = COUNT(distinct brokerBranchCode) FROM sims2016TradeToday..prodCapital WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @O_ERRORMSGCODE = -100, @O_ERRORMSGTEXT = 'ѡ����ʽ��˻�(' + @i_fundAcctCode + ')������'
      RETURN
    END
  
  IF @findRow > 1
    BEGIN
      SELECT @O_ERRORMSGCODE = -200, @O_ERRORMSGTEXT = 'ѡ����ʽ��˻�(' + @i_fundAcctCode + ')������ͬһ��Ӫҵ����ͬһ����'
      RETURN
    END

  SELECT @brokerBranchCode = brokerBranchCode, @currencyCode = currencyCode, @fundAcctTypeCode = fundAcctTypeCode
         FROM sims2016TradeToday..prodCapital
         WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @O_ERRORMSGCODE = -300, @O_ERRORMSGTEXT = 'ѡ����ʽ��˻�(' + @i_fundAcctCode + ')�Ҳ���������Ӫҵ��'
      RETURN
    END

  SELECT @counterVersionCode = brokerCounterVersionCode FROM sims2016TradeToday..brokerBranch WHERE brokerBranchCode = @brokerBranchCode
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @O_ERRORMSGCODE = -400, @O_ERRORMSGTEXT = '�Ҳ���Ӫҵ��(' + @brokerBranchCode + ')����Ӧ�Ĺ�̨�汾'
      RETURN
    END

  SELECT @innerCounterVersionCode = innerBrokerCounterVersionCode FROM sims2016TradeToday..brokerCounterVersionCfg WHERE brokerCounterVersionCode = @counterVersionCode
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @O_ERRORMSGCODE = -400, @O_ERRORMSGTEXT = '�Ҳ�����̨�汾(' + @counterVersionCode + ')����Ӧ�Ĺ�̨�汾'
      RETURN
    END

  --ͬ���������ʽ���ˮ��Ϣ��(brokerRawJrnlTemp)����ʷ�ɽ���Ϣ��(brokerDealHistTemp)�Ĵ���,�ϲ����ʽ���ˮ��ʷ�ɽ���Ϣ��(brokerRawJrnlDealHistTemp)
  IF @i_selected_rawJrnl = '1' AND @i_selected_dealHist = '1' AND @fundAcctTypeCode = '3'
    BEGIN
      --ȡ��ͬ��̨��ˮ����Ĵ洢������    
      BEGIN
        SELECT @procName = mergeRawJrnlDealProcedureName FROM sims2016TradeToday..brokerCounterProcedureCfg WHERE innerBrokerCounterVersionCode = @innerCounterVersionCode
        IF @@ROWCOUNT = 0
          BEGIN
            SELECT @O_ERRORMSGCODE = -500, @O_ERRORMSGTEXT = '�Ҳ�����̨�汾(' + @innerCounterVersionCode + ')����Ӧ�Ĳ�ͬ��̨��ˮ����Ĵ洢������'
            RETURN
          END
      END;
    
      --����Ӧ��̨�汾�Ĵ�������Ƿ����
      IF NOT EXISTS(SELECT * FROM sysobjects where name = @procName and xtype = 'P')
        BEGIN
          SELECT @O_ERRORMSGCODE = -600, @O_ERRORMSGTEXT = '�Ҳ�����Ӧ��̨�汾��ԭʼ��ˮ����Ĵ洢����'
          RETURN
        END

      SELECT @sqlStr = @procName + CHAR(39) + @i_operatorCode + CHAR(39) + ',' + CHAR(39) + @i_operatorPassword + CHAR(39) + ',' + CHAR(39) + @i_operateStationText + CHAR(39) + ','
      SELECT @sqlStr = @sqlStr + CHAR(39) + @i_fundAcctCode + CHAR(39) + ',' + CHAR(39) + @currencyCode + CHAR(39) + ',' + CHAR(39) + @i_beginDate + CHAR(39) + ',' + CHAR(39) + @i_endDate + CHAR(39)
      --��̬�洢���̵�����
      EXEC (@sqlStr)
      IF @@ERROR != 0
        BEGIN
          SELECT @O_ERRORMSGCODE = -700, @O_ERRORMSGTEXT = 'SQL����'
          RETURN
        END
    END

  --��brokerRawJrnlDealHistTempת���ɲ�Ʒ����Ʒ��Ԫ��ˮ(�ֻ�)
  IF (@i_selected_rawJrnl = '1' or @i_selected_dealHist = '1') AND @fundAcctTypeCode = '3'
    BEGIN
      EXEC ip_convertRawJrnlDealTmpES @i_operatorCode, @i_operatorPassword, @i_operateStationText,@i_fundAcctCode, @i_beginDate, @i_endDate
      IF @@ERROR != 0 OR @O_ERRORMSGCODE != 0
        BEGIN
          SELECT @O_ERRORMSGCODE = -800, @O_ERRORMSGTEXT = 'ip_convertRawJrnlDealTmpES:SQL����'
          RETURN
        END

    ----��Ʒ�ɱ�����
    --EXEC op_calcProdCheckJrnlES @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate

    ----��Ʒ��Ԫ�ɱ�����
    --EXEC op_calcProdCellCheckJrnlES @i_operatorCode, @i_operatorPassword, @i_operateStationText, @i_fundAcctCode, '', '', @i_beginDate

    ----��Ʒ��ԪͶ����ϳɱ�����
    --EXEC op_calcPortfolioCheckJrnlES @i_operatorCode, @i_operatorPassword, @i_operateStationText, @i_fundAcctCode, '', '', @i_beginDate
    END

  --��brokerRawJrnlFutureTmpת���ɲ�Ʒ����Ʒ��Ԫ��ˮ(�ڻ�)
  IF (@i_selected_rawJrnl = '1' or @i_selected_dealHist = '1') AND @fundAcctTypeCode = '1'
    BEGIN
      EXEC ip_convertRawJrnlDealTmpF @O_ERRORMSGCODE, @O_ERRORMSGTEXT, @i_operatorCode, @i_operatorPassword, @i_operateStationText, @i_fundAcctCode, @i_beginDate, @i_endDate
      IF @@ERROR != 0
        BEGIN
          SELECT @O_ERRORMSGCODE = -800, @O_ERRORMSGTEXT = 'ip_convertRawJrnlDealTmpF:SQL����'
          RETURN
        END

      ----��Ʒ���ն��гɱ�����
      --EXEC op_calcProdCheckJrnlFMTM @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate

      ----��Ʒ��ʶԳ�ɱ�����
      --EXEC op_calcProdCheckJrnlFSDH @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate

      ----��Ʒ��Ԫ���ն��гɱ�����
      --EXEC op_calcProdCellCheckJrnlFMTM @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate

      ----��Ʒ��Ԫ��ʶԳ�ɱ�����
      --EXEC op_calcProdCellCheckJrnlFSDH @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate
    
    END

  ----����ֲִ���ʵ���
  --SELECT @tempDate = @i_beginDate
  --WHILE (@tempDate <= @i_endDate)
  --  BEGIN
  --    IF @tempDate >= @todayDate
  --      BREAK;

  --    EXEC op_calcProdPosiJrnl '9999', '', '', @tempDate, 'CNY', '', '', '', '', '', ''

  --    SELECT @tempDate = convert(varchar(10), DATEADD(dd, 1, @tempDate), 120)
  --  END

  ----�����Ʒ�ʲ��ʲ�״������ʵ���
  --BEGIN
  --  SELECT @tempDate = @i_endDate
  --  IF @tempDate >= @todayDate
  --    SELECT @tempDate = CONVERT(VARCHAR(10), DATEADD(dd, -1, @tempDate), 120)

  --  EXEC op_calcProdAssetsStatus '9999', '', '', @i_beginDate, @tempDate, 'CNY', '', '', @i_fundAcctCode, ''
  --END

  SELECT @O_ERRORMSGCODE = 0, @O_ERRORMSGTEXT = '����ͬ���������'
  RETURN 0
go

--declare @O_ERRORMSGCODE int,@O_ERRORMSGTEXT varchar(255),
--        @s_date datetime, @e_date datetime
--select @s_date = getdate()
--EXEC opDoDataSync @O_ERRORMSGCODE out, @O_ERRORMSGTEXT out, '9999', '', '', '9999-01', '2017-03-13', '2017-03-20', '1', '1'
--select @e_date = getdate()
--select @O_ERRORMSGCODE, @O_ERRORMSGTEXT,
--       @s_date as ִ�п�ʼʱ��, @e_date ִ�н���ʱ��, datediff(ms, @s_date, @e_date) as ִ�к�ʱʱ��

