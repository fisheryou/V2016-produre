USE sims2016Proc
go

IF OBJECT_ID(N'opDoDataSync', N'P') IS NOT NULL
  DROP PROC opDoDataSync
go

--EXEC opDoDataSync @O_ERRORMSGCODE, @O_ERRORMSGTEXT, '9999', '', '', '9999-01', '2017-03-13', '2017-03-20', '1', '1'
CREATE PROC opDoDataSync
  @O_ERRORMSGCODE                    INT            OUT, --错误信息代码[yugy20170104]
  @O_ERRORMSGTEXT                    VARCHAR(600)   OUT, --错误信息文本[yugy20170104]
  @i_operatorCode                    VARCHAR(30)       , --操作员代码
  @i_operatorPassword                VARCHAR(30)       , --操作员密码
  @i_operateStationText              VARCHAR(600)      , --留痕信息
  @i_fundAcctCode                    VARCHAR(30)       , --资金账户代码
  @i_beginDate                       VARCHAR(10)       , --同步开始日期
  @i_endDate                         VARCHAR(10)       , --同步结束日期
  @i_selected_rawJrnl                VARCHAR(30)       , --是否选中资金流水同步   '0' 否  '1' 是；属于历史数据处理，在Oracle中处理
  @i_selected_dealHist               VARCHAR(30)         --是否选中历史成交同步   '0' 否  '1' 是；属于历史数据处理，在Oracle中处理
AS
  DECLARE
  @brokerBranchCode VARCHAR(30), @currencyCode VARCHAR(4), @counterVersionCode VARCHAR(30), @innerCounterVersionCode VARCHAR(30),
  @procName VARCHAR(30), @sqlStr VARCHAR(4096), @findRow INT, @sqlCode INT, @sqlErrM VARCHAR(2048), @fundAcctTypeCode VARCHAR(1),
  @tempDate VARCHAR(10), @todayDate VARCHAR(10)

  SELECT @todayDate = CONVERT(VARCHAR(10), GETDATE(), 120)
  SELECT @findRow = COUNT(distinct brokerBranchCode) FROM sims2016TradeToday..prodCapital WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @O_ERRORMSGCODE = -100, @O_ERRORMSGTEXT = '选择的资金账户(' + @i_fundAcctCode + ')不存在'
      RETURN
    END
  
  IF @findRow > 1
    BEGIN
      SELECT @O_ERRORMSGCODE = -200, @O_ERRORMSGTEXT = '选择的资金账户(' + @i_fundAcctCode + ')不属于同一个营业部或同一币种'
      RETURN
    END

  SELECT @brokerBranchCode = brokerBranchCode, @currencyCode = currencyCode, @fundAcctTypeCode = fundAcctTypeCode
         FROM sims2016TradeToday..prodCapital
         WHERE dbo.fnCharIndexDh(fundAcctCode, @i_fundAcctCode) > 0
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @O_ERRORMSGCODE = -300, @O_ERRORMSGTEXT = '选择的资金账户(' + @i_fundAcctCode + ')找不到所属的营业部'
      RETURN
    END

  SELECT @counterVersionCode = brokerCounterVersionCode FROM sims2016TradeToday..brokerBranch WHERE brokerBranchCode = @brokerBranchCode
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @O_ERRORMSGCODE = -400, @O_ERRORMSGTEXT = '找不到营业部(' + @brokerBranchCode + ')所对应的柜台版本'
      RETURN
    END

  SELECT @innerCounterVersionCode = innerBrokerCounterVersionCode FROM sims2016TradeToday..brokerCounterVersionCfg WHERE brokerCounterVersionCode = @counterVersionCode
  IF @@ROWCOUNT = 0
    BEGIN
      SELECT @O_ERRORMSGCODE = -400, @O_ERRORMSGTEXT = '找不到柜台版本(' + @counterVersionCode + ')所对应的柜台版本'
      RETURN
    END

  --同步回来的资金流水信息表(brokerRawJrnlTemp)与历史成交信息表(brokerDealHistTemp)的处理,合并成资金流水历史成交信息表(brokerRawJrnlDealHistTemp)
  IF @i_selected_rawJrnl = '1' AND @i_selected_dealHist = '1' AND @fundAcctTypeCode = '3'
    BEGIN
      --取不同柜台流水处理的存储过程名    
      BEGIN
        SELECT @procName = mergeRawJrnlDealProcedureName FROM sims2016TradeToday..brokerCounterProcedureCfg WHERE innerBrokerCounterVersionCode = @innerCounterVersionCode
        IF @@ROWCOUNT = 0
          BEGIN
            SELECT @O_ERRORMSGCODE = -500, @O_ERRORMSGTEXT = '找不到柜台版本(' + @innerCounterVersionCode + ')所对应的不同柜台流水处理的存储过程名'
            RETURN
          END
      END;
    
      --检查对应柜台版本的存过过程是否存在
      IF NOT EXISTS(SELECT * FROM sysobjects where name = @procName and xtype = 'P')
        BEGIN
          SELECT @O_ERRORMSGCODE = -600, @O_ERRORMSGTEXT = '找不到对应柜台版本的原始流水处理的存储过程'
          RETURN
        END

      SELECT @sqlStr = @procName + CHAR(39) + @i_operatorCode + CHAR(39) + ',' + CHAR(39) + @i_operatorPassword + CHAR(39) + ',' + CHAR(39) + @i_operateStationText + CHAR(39) + ','
      SELECT @sqlStr = @sqlStr + CHAR(39) + @i_fundAcctCode + CHAR(39) + ',' + CHAR(39) + @currencyCode + CHAR(39) + ',' + CHAR(39) + @i_beginDate + CHAR(39) + ',' + CHAR(39) + @i_endDate + CHAR(39)
      --动态存储过程的语句块
      EXEC (@sqlStr)
      IF @@ERROR != 0
        BEGIN
          SELECT @O_ERRORMSGCODE = -700, @O_ERRORMSGTEXT = 'SQL错误'
          RETURN
        END
    END

  --将brokerRawJrnlDealHistTemp转换成产品、产品单元流水(现货)
  IF (@i_selected_rawJrnl = '1' or @i_selected_dealHist = '1') AND @fundAcctTypeCode = '3'
    BEGIN
      EXEC ip_convertRawJrnlDealTmpES @i_operatorCode, @i_operatorPassword, @i_operateStationText,@i_fundAcctCode, @i_beginDate, @i_endDate
      IF @@ERROR != 0 OR @O_ERRORMSGCODE != 0
        BEGIN
          SELECT @O_ERRORMSGCODE = -800, @O_ERRORMSGTEXT = 'ip_convertRawJrnlDealTmpES:SQL错误'
          RETURN
        END

    ----产品成本计算
    --EXEC op_calcProdCheckJrnlES @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate

    ----产品单元成本计算
    --EXEC op_calcProdCellCheckJrnlES @i_operatorCode, @i_operatorPassword, @i_operateStationText, @i_fundAcctCode, '', '', @i_beginDate

    ----产品单元投资组合成本计算
    --EXEC op_calcPortfolioCheckJrnlES @i_operatorCode, @i_operatorPassword, @i_operateStationText, @i_fundAcctCode, '', '', @i_beginDate
    END

  --将brokerRawJrnlFutureTmp转换成产品、产品单元流水(期货)
  IF (@i_selected_rawJrnl = '1' or @i_selected_dealHist = '1') AND @fundAcctTypeCode = '1'
    BEGIN
      EXEC ip_convertRawJrnlDealTmpF @O_ERRORMSGCODE, @O_ERRORMSGTEXT, @i_operatorCode, @i_operatorPassword, @i_operateStationText, @i_fundAcctCode, @i_beginDate, @i_endDate
      IF @@ERROR != 0
        BEGIN
          SELECT @O_ERRORMSGCODE = -800, @O_ERRORMSGTEXT = 'ip_convertRawJrnlDealTmpF:SQL错误'
          RETURN
        END

      ----产品逐日盯市成本计算
      --EXEC op_calcProdCheckJrnlFMTM @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate

      ----产品逐笔对冲成本计算
      --EXEC op_calcProdCheckJrnlFSDH @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate

      ----产品单元逐日盯市成本计算
      --EXEC op_calcProdCellCheckJrnlFMTM @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate

      ----产品单元逐笔对冲成本计算
      --EXEC op_calcProdCellCheckJrnlFSDH @i_operatorCode, @i_operatorPassword, @i_operateStationText, '', @i_fundAcctCode, '', '', @i_beginDate
    
    END

  ----计算持仓存入实体表
  --SELECT @tempDate = @i_beginDate
  --WHILE (@tempDate <= @i_endDate)
  --  BEGIN
  --    IF @tempDate >= @todayDate
  --      BREAK;

  --    EXEC op_calcProdPosiJrnl '9999', '', '', @tempDate, 'CNY', '', '', '', '', '', ''

  --    SELECT @tempDate = convert(varchar(10), DATEADD(dd, 1, @tempDate), 120)
  --  END

  ----计算产品资产资产状况存入实体表
  --BEGIN
  --  SELECT @tempDate = @i_endDate
  --  IF @tempDate >= @todayDate
  --    SELECT @tempDate = CONVERT(VARCHAR(10), DATEADD(dd, -1, @tempDate), 120)

  --  EXEC op_calcProdAssetsStatus '9999', '', '', @i_beginDate, @tempDate, 'CNY', '', '', @i_fundAcctCode, ''
  --END

  SELECT @O_ERRORMSGCODE = 0, @O_ERRORMSGTEXT = '数据同步处理完成'
  RETURN 0
go

--declare @O_ERRORMSGCODE int,@O_ERRORMSGTEXT varchar(255),
--        @s_date datetime, @e_date datetime
--select @s_date = getdate()
--EXEC opDoDataSync @O_ERRORMSGCODE out, @O_ERRORMSGTEXT out, '9999', '', '', '9999-01', '2017-03-13', '2017-03-20', '1', '1'
--select @e_date = getdate()
--select @O_ERRORMSGCODE, @O_ERRORMSGTEXT,
--       @s_date as 执行开始时间, @e_date 执行结束时间, datediff(ms, @s_date, @e_date) as 执行耗时时间

