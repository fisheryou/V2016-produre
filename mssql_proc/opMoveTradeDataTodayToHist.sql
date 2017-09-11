USE sims2016Proc
go
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'opMoveTradeDataTodayToHist')
  DROP PROC opMoveTradeDataTodayToHist
go

CREATE PROC opMoveTradeDataTodayToHist
(
  @O_ERRORMSGCODE          INT            OUT,
  @O_ERRORMSGTEXT          VARCHAR(255)   OUT,
  @i_operatorCode          VARCHAR(255),       --����Ա����
  @i_operatorPassword      VARCHAR(255),       --����Ա����
  @i_operateStationText    VARCHAR(255),       --������Ϣ
  @i_currenttradeDate      VARCHAR(255)        --��ǰ��������      
  )
AS
  
  --����: opMoveTradeDataTodayToHist
  --����: ����Ǩ��
  
  SET NOCOUNT ON
  DECLARE
  @v_tradeDate               CHAR(10),
  @v_operateDate             CHAR(10),
  @v_operateDatetime         datetime,
  @v_sequence                numeric(10,0),
  @v_countF                  numeric(10,0),
  @v_countES                 numeric(10,0),
  @v_serialNO                numeric(10,0),          -- ��������
  @v_countESInt              numeric(10,0),       -- ��������  �ֻ�����
  @v_countFInt               numeric(10,0)        -- ��������  �ڻ�����
  
   --ɾ����Ʒ��Ԫ���չ�Ʊ�ɽ��� 
    DELETE sims2016TradeToday..prodCellDealESToday
    --ɾ����Ʒ��Ԫ�����ڻ��ɽ���
    DELETE sims2016TradeToday..prodCellDealFToday
    --ɾ����Ʒ��Ԫ���չ�Ʊί�б�
    DELETE sims2016TradeToday..prodCellOrderESToday
    --ɾ����Ʒ��Ԫ�����ڻ�ί�б�
    DELETE sims2016TradeToday..prodCellOrderFToday
    --ɾ����Ʒ��Ԫ���չ�Ʊί�з�����ϸ      
    DELETE sims2016TradeToday..prodCellOrderFeeESToday
    --ɾ����Ʒ��Ԫ�����ڻ�ί�з�����ϸ
    DELETE sims2016TradeToday..prodCellOrderFeeFToday
    --ɾ����Ʒ��Ԫ���չ�Ʊ�ɽ�������ϸ
    DELETE sims2016TradeToday..prodCellDealFeeESToday
    --ɾ����Ʒ��Ԫ�����ڻ��ɽ�������ϸ
    DELETE sims2016TradeToday..prodCellDealFeeFToday
        
    --��Ʒ�ʽ��˻��ڻ���֤���������,prodCapitalMarginRateFHist������Ϊ(prodCode,fundAcctCode,exchangeCode,secuCode,hedgeFlagCode,tradeDate)

    --ɾ����ʷ
    SELECT @v_tradeDate = MAX(tradeDate) FROM sims2016TradeToday..prodCapitalMarginRateFToday
    DELETE FROM sims2016TradeHist..prodCapitalMarginRateFHist WHERE tradeDate=@v_tradeDate
    --������ʷ
         
    INSERT INTO sims2016TradeHist..prodCapitalMarginRateFHist (prodCode,fundAcctCode,exchangeCode,secuCode,hedgeFlagCode,longMarginRatioVolumeValue,
                                               longMarginRatioMoneyValue,shortMarginRatioVolumeValue,shortMarginRatioMoneyValue,tradeDate,operatorCode,
                                               operateDatetime,operateRemarkText)
                                        SELECT prodCode,fundAcctCode,exchangeCode,secuCode,hedgeFlagCode,longMarginRatioVolumeValue,longMarginRatioMoneyValue,shortMarginRatioVolumeValue,shortMarginRatioMoneyValue,tradeDate,operatorCode,operateDatetime,operateRemarkText
                                          FROM sims2016TradeToday..prodCapitalMarginRateFToday
    DELETE sims2016TradeToday..prodCapitalMarginRateFToday--�h������
    --���ɵ��ձ�
    INSERT INTO sims2016TradeToday..prodCapitalMarginRateFToday (prodCode,fundAcctCode,exchangeCode,secuCode,hedgeFlagCode,
                                                longMarginRatioVolumeValue,longMarginRatioMoneyValue,shortMarginRatioVolumeValue,
                                                shortMarginRatioMoneyValue,tradeDate,operatorCode,operateDatetime,operateRemarkText)
                                         SELECT prodCode,fundAcctCode,exchangeCode,secuCode,hedgeFlagCode,
                                                longMarginRatioVolumeValue,longMarginRatioMoneyValue,longMarginRatioMoneyValue,
                                                shortMarginRatioMoneyValue,@i_currenttradeDate,operatorCode,GETDATE(),operateRemarkText
                                           FROM sims2016TradeToday..prodCapitalMarginRateF where @i_currenttradeDate between beginDate and endDate

    --��Ʒ�ʽ��������Ǩ��prodCapitalChgHist

    --ɾ����ʷ
    SELECT  @v_operateDate = MAX(operateDate) FROM sims2016TradeToday..prodCapitalChgToday
    DELETE sims2016TradeHist..prodCapitalChgHist WHERE operateDate = @v_operateDate
    --���հ��Ƶ���ʷ
    INSERT INTO sims2016TradeHist..prodCapitalChgHist (operateDate,prodCode,fundAcctCode,cashAvailableChgAmt,cashAvailableFrzChgAmt,
                                       operatorCode,operateDatetime,operateRemarkText)
                                SELECT operateDate,prodCode,fundAcctCode,cashAvailableChgAmt,cashAvailableFrzChgAmt,
                                       operatorCode,operateDatetime,operateRemarkText
                                  FROM sims2016TradeToday..prodCapitalChgToday
    DELETE sims2016TradeToday..prodCapitalChgToday
   
  --��Ʒ�ڻ��ֲֵ�������Ǩ��(�ݲ������д�������:������һ�����յ��������ڵ�����)

    --ɾ����ʷ
    SELECT @v_operateDate = MAX(operateDate) FROM sims2016TradeToday..prodPosiFChgToday
    DELETE sims2016TradeHist..prodPosiFChgHist WHERE operateDate=@v_operateDate
    --���հ�����ʷ
    INSERT INTO sims2016TradeHist..prodPosiFChgHist (operateDate,prodCode,fundAcctCode,exchangeCode,secuCode,longShortFlagCode,
                                     hedgeFlagCode,posiAvailableChgQty,posiAvailableFrzChgQty,posiBuyedChgQty,posiBuyedFrzChgQty,
                                     posiBuyingChgQty,investRecentRlzChgProfit,investCostChgAmt,investMarginChgAmt,operatorCode,operateDatetime,operateRemarkText)
                              SELECT operateDate,prodCode,fundAcctCode,exchangeCode,secuCode,longShortFlagCode,
                                     hedgeFlagCode,posiAvailableChgQty,posiAvailableFrzChgQty,posiBuyedChgQty,posiBuyedFrzChgQty,
                                     posiBuyingChgQty,investRecentRlzChgProfit,investCostChgAmt,investMarginChgAmt,operatorCode,operateDatetime,operateRemarkText
                                FROM sims2016TradeToday..prodPosiFChgToday
    DELETE sims2016TradeToday..prodPosiFChgToday
 
  --��Ʒ��Ԫ�ʽ��������Ǩ��(�ݲ������д�������:������һ�����յ��������ڵ�����)

    --ɾ����ʷ
    SELECT  @v_operateDate = MAX(operateDate) FROM sims2016TradeToday..prodCellCapitalChgToday
    DELETE sims2016TradeHist..prodCellCapitalChgHist WHERE operateDate=@v_operateDate
    --���հ�����ʷ
    INSERT INTO sims2016TradeHist..prodCellCapitalChgHist (operateDate,prodCode,prodCellCode,fundAcctCode,cashAvailableChgAmt,
                                           cashAvailableFrzChgAmt,operatorCode,operateDatetime,operateRemarkText)
                                    SELECT operateDate,prodCode,prodCellCode,fundAcctCode,cashAvailableChgAmt,
                                           cashAvailableFrzChgAmt,operatorCode,operateDatetime,operateRemarkText
                                      FROM sims2016TradeToday..prodCellCapitalChgToday
    DELETE sims2016TradeToday..prodCellCapitalChgToday
    
    --��Ʒ��Ԫ�ڻ��ֲֵ�����Ǩ��prodCellPosiFChgToday
  
    --ɾ����ʷ
    SELECT @v_operateDate = MAX(operateDate) FROM sims2016TradeToday..prodCellPosiFChgToday
    DELETE sims2016TradeHist..prodCellPosiFChgHist WHERE operateDate=@v_operateDate
    --���հ�����ʷ
    INSERT INTO sims2016TradeHist..prodCellPosiFChgHist (operateDate,prodCode,prodCellCode,fundAcctCode,exchangeCode,secuCode,
                                         longShortFlagCode,hedgeFlagCode,investPortfolioCode,transactionNO,posiAvailableChgQty,posiAvailableFrzChgQty,
                                         posiBuyedChgQty,posiBuyedFrzChgQty,posiBuyingChgQty,investRecentRlzChgProfit,investCostChgAmt,investMarginChgAmt,
                                         operatorCode,operateDatetime,operateRemarkText)
                                  SELECT operateDate,prodCode,prodCellCode,fundAcctCode,exchangeCode,secuCode,
                                         longShortFlagCode,hedgeFlagCode,investPortfolioCode,transactionNO,posiAvailableChgQty,posiAvailableFrzChgQty,
                                         posiBuyedChgQty,posiBuyedFrzChgQty,posiBuyingChgQty,investRecentRlzChgProfit,investCostChgAmt,investMarginChgAmt,
                                         operatorCode,operateDatetime,operateRemarkText
                                    FROM sims2016TradeToday..prodCellPosiFChgToday
    DELETE sims2016TradeToday..prodCellPosiFChgToday

    
  --��Ʒ��Ԫ�ʽ�֤ȯ��ˮ�����prodCellRawJrnlToday prodCellRawJrnlFToday prodCellRawJrnlESToday

    --ɾ����ʷ
    SELECT  @v_operateDatetime = convert(char(10), MAX(operateDatetime), 20) FROM sims2016TradeToday..prodCellRawJrnlToday
    DELETE sims2016TradeHist..prodCellRawJrnlHist WHERE convert(char(10), operateDatetime, 20)=@v_operateDatetime
    DELETE sims2016TradeHist..prodCellRawJrnlFHist WHERE matchDate=@v_operateDatetime
    DELETE sims2016TradeHist..prodCellRawJrnlESHist WHERE matchDate=@v_operateDatetime
    --���ʽ���ˮ������ʷ
    INSERT INTO sims2016TradeHist..prodCellRawJrnlHist (originSerialNO,settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,
                                        hedgeFlagCode,coveredFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,
                                        brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,
                                        secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,
                                        dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText)
                                 SELECT originSerialNO,settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,
                                        hedgeFlagCode,coveredFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,
                                        brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,
                                        secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,
                                        dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText 
                                   FROM sims2016TradeToday..prodCellRawJrnlToday WHERE secuBizTypeCode IN ('8001','8002','8003','8004')

DECLARE 
  @v_serialNO1 numeric(10,0),
  @v_originSerialNO numeric(10,0),
  @v_settleDate CHAR(10),
  @v_secuBizTypeCode   VARCHAR(255),
  @v_buySellFlagCode   VARCHAR(255),
  @v_bizSubTypeCode   VARCHAR(255),
  @v_openCloseFlagCode   VARCHAR(255),
  @v_hedgeFlagCode   VARCHAR(255),
  @v_coveredFlagCode   VARCHAR(255),
  @v_originSecuBizTypeCode   VARCHAR(255),
  @v_brokerSecuBizTypeCode   VARCHAR(255),
  @v_brokerSecuBizTypeName VARCHAR(255),
  @v_brokerJrnlSerialID numeric(20,0),
  @v_prodCode   VARCHAR(255),
  @v_prodCellCode   VARCHAR(255),
  @v_fundAcctCode   VARCHAR(255),
  @v_currencyCode   VARCHAR(255),
  @v_cashCurrentSettleAmt numeric(19,2),
  @v_cashCurrentBalanceAmt numeric(19,2),
  @v_exchangeCode   VARCHAR(255),
  @v_secuAcctCode   VARCHAR(255),
  @v_secuCode   VARCHAR(255),
  @v_originSecuCode   VARCHAR(255),
  @v_secuName VARCHAR(255),
  @v_secuTradeTypeCode   VARCHAR(255),
  @v_matchQty numeric(19,2),
  @v_posiCurrentBalanceQty numeric(19,2),
  @v_matchNetPrice numeric(19,2),
  @v_dataSourceFlagCode   VARCHAR(255),
  @v_marketLevelCode   VARCHAR(255),
  @v_operatorCode   VARCHAR(255),
  @v_operateDatetime1 DATETIME,
  @v_operateRemarkText VARCHAR(255)
  
   DECLARE prodCellRawJrnlToday_data cursor for SELECT serialNO,originSerialNO,settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,
                                                  openCloseFlagCode,hedgeFlagCode,coveredFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,
                                                  brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,
                                                  cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,matchQty,
                                                  posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText 
                                             FROM sims2016TradeToday..prodCellRawJrnlToday where secuBizTypeCode NOT IN ('8001','8002','8003','8004')
   open prodCellRawJrnlToday_data
   fetch prodCellRawJrnlToday_data into @v_serialNO1,@v_originSerialNO,@v_settleDate,@v_secuBizTypeCode,@v_buySellFlagCode,@v_bizSubTypeCode,@v_openCloseFlagCode,
                                        @v_hedgeFlagCode,@v_coveredFlagCode,@v_originSecuBizTypeCode,@v_brokerSecuBizTypeCode,@v_brokerSecuBizTypeName,@v_brokerJrnlSerialID,
                                        @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_currencyCode,@v_cashCurrentSettleAmt,@v_cashCurrentBalanceAmt,@v_exchangeCode,@v_secuAcctCode,
                                        @v_secuCode,@v_originSecuCode,@v_secuName,@v_secuTradeTypeCode,@v_matchQty,@v_posiCurrentBalanceQty,@v_matchNetPrice,@v_dataSourceFlagCode,
                                        @v_marketLevelCode,@v_operatorCode,@v_operateDatetime1,@v_operateRemarkText                                                                                  
   WHILE @@FETCH_STATUS = 0
     BEGIN
        IF EXISTS(SELECT 1 FROM sims2016TradeToday..prodCellRawJrnlFToday WHERE @v_serialNO1=serialNO)
          BEGIN
            INSERT INTO sims2016TradeHist..prodCellRawJrnlFHist (settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,
                                               hedgeFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,
                                               brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,
                                               exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,matchQty,posiBalanceQty,
                                               matchNetPrice,matchSettleAmt,matchTradeFeeAmt,matchDate,matchTime,matchID,brokerOrderID,brokerOriginOrderID,brokerErrorMsg,dataSourceFlagCode,
                                               transactionNO,investPortfolioCode,assetLiabilityTypeCode,investInstrucNO,traderInstrucNO,orderNO,marketLevelCode,orderNetAmt,orderNetPrice,orderQty,
                                               orderSettleAmt,orderSettlePrice,orderTradeFeeAmt,directorCode,traderCode,operatorCode,operateDatetime,operateRemarkText)
                                        SELECT settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,
                                               hedgeFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,
                                               brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,
                                               exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,matchQty,posiBalanceQty,
                                               matchNetPrice,matchSettleAmt,matchTradeFeeAmt,matchDate,matchTime,matchID,brokerOrderID,brokerOriginOrderID,brokerErrorMsg,dataSourceFlagCode,
                                               transactionNO,investPortfolioCode,assetLiabilityTypeCode,investInstrucNO,traderInstrucNO,orderNO,marketLevelCode,orderNetAmt,orderNetPrice,orderQty,
                                               orderSettleAmt,orderSettlePrice,orderTradeFeeAmt,directorCode,traderCode,operatorCode,operateDatetime,operateRemarkText
                                          FROM sims2016TradeToday..prodCellRawJrnlFToday WHERE @v_serialNO1=serialNO  
          END
        IF EXISTS(SELECT 1 FROM sims2016TradeToday..prodCellRawJrnlESToday WHERE @v_serialNO1=serialNO)
          BEGIN
            INSERT INTO sims2016TradeHist..prodCellRawJrnlESHist (settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,
                                                originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,
                                                prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,
                                                originSecuCode,secuName,secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,matchSettleAmt,matchTradeFeeAmt,matchDate,
                                                matchTime,matchID,brokerOrderID,brokerOriginOrderID,brokerErrorMsg,dataSourceFlagCode,transactionNO,investPortfolioCode,assetLiabilityTypeCode,
                                                investInstrucNO,traderInstrucNO,orderNO,marketLevelCode,orderNetAmt,orderNetPrice,orderQty,orderSettleAmt,orderSettlePrice,orderTradeFeeAmt,directorCode,
                                                traderCode,operatorCode,operateDatetime,operateRemarkText)
                                         SELECT settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,
                                                originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,
                                                prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,
                                                originSecuCode,secuName,secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,matchSettleAmt,matchTradeFeeAmt,matchDate,
                                                matchTime,matchID,brokerOrderID,brokerOriginOrderID,brokerErrorMsg,dataSourceFlagCode,transactionNO,investPortfolioCode,assetLiabilityTypeCode,
                                                investInstrucNO,traderInstrucNO,orderNO,marketLevelCode,orderNetAmt,orderNetPrice,orderQty,orderSettleAmt,orderSettlePrice,orderTradeFeeAmt,directorCode,
                                                traderCode,operatorCode,operateDatetime,operateRemarkText
                                           FROM sims2016TradeToday..prodCellRawJrnlESToday WHERE @v_serialNO1=serialNO                                        
          END
          
         INSERT INTO  sims2016TradeHist..prodCellRawJrnlHist (originSerialNO,settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,coveredFlagCode,
                      originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,
                      currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,
                      matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText)
               VALUES (@v_originSerialNO,@v_settleDate,@v_secuBizTypeCode,@v_buySellFlagCode,
                      @v_bizSubTypeCode,@v_openCloseFlagCode,@v_hedgeFlagCode,@v_coveredFlagCode,@v_originSecuBizTypeCode,
                      @v_brokerSecuBizTypeCode,@v_brokerSecuBizTypeName,@v_brokerJrnlSerialID,@v_prodCode,@v_prodCellCode,
                      @v_fundAcctCode,@v_currencyCode,@v_cashCurrentSettleAmt,@v_cashCurrentBalanceAmt,@v_exchangeCode,@v_secuAcctCode,
                      @v_secuCode,@v_originSecuCode,@v_secuName,@v_secuTradeTypeCode,@v_matchQty,@v_posiCurrentBalanceQty,@v_matchNetPrice,
                      @v_dataSourceFlagCode,@v_marketLevelCode,@v_operatorCode,@v_operateDatetime1,@v_operateRemarkText)
        
         fetch prodCellRawJrnlToday_data into @v_serialNO1,@v_originSerialNO,@v_settleDate,@v_secuBizTypeCode,@v_buySellFlagCode,@v_bizSubTypeCode,@v_openCloseFlagCode,
                                        @v_hedgeFlagCode,@v_coveredFlagCode,@v_originSecuBizTypeCode,@v_brokerSecuBizTypeCode,@v_brokerSecuBizTypeName,@v_brokerJrnlSerialID,
                                        @v_prodCode,@v_prodCellCode,@v_fundAcctCode,@v_currencyCode,@v_cashCurrentSettleAmt,@v_cashCurrentBalanceAmt,@v_exchangeCode,@v_secuAcctCode,
                                        @v_secuCode,@v_originSecuCode,@v_secuName,@v_secuTradeTypeCode,@v_matchQty,@v_posiCurrentBalanceQty,@v_matchNetPrice,@v_dataSourceFlagCode,
                                        @v_marketLevelCode,@v_operatorCode,@v_operateDatetime1,@v_operateRemarkText
       
     END 
     
       CLOSE prodCellRawJrnlToday_data
       DEALLOCATE prodCellRawJrnlToday_data                                            
       DELETE FROM sims2016TradeToday..prodCellRawJrnlToday
       DELETE FROM sims2016TradeToday..prodCellRawJrnlFToday
       DELETE FROM sims2016TradeToday..prodCellRawJrnlESToday
    
     -- ��Ʒ�ʽ�֤ȯ��ˮ���ձ�Ǩ��  prodRawJrnlHist��¼���������  ���ڵ��ձ�ֻ������һ�������
    
      -- ɾ����ʷ EXISTS��IN�ڴ˴�����һ��
      DELETE aa FROM sims2016TradeHist..prodRawJrnlHist aa WHERE  convert(char(10), aa.operateDatetime, 20)  IN(SELECT convert(char(10), bb.operateDatetime, 20) FROM sims2016TradeToday..prodRawJrnlToday bb) 
      -- ɾ���ֻ���ʷ��֤ȯ��ˮ
      DELETE sims2016TradeHist..prodRawJrnlESHist WHERE convert(char(10), operateDatetime, 20) IN(SELECT convert(char(10), bb.operateDatetime, 20) FROM sims2016TradeToday..prodRawJrnlESToday bb)
      -- ɾ���ڻ���ʷ��֤ȯ��ˮ
      DELETE sims2016TradeHist..prodRawJrnlFHist WHERE convert(char(10), operateDatetime, 20) IN(SELECT convert(char(10), bb.operateDatetime, 20) FROM sims2016TradeToday..prodRawJrnlFToday bb)
      
      -- ���ʽ���ˮֱ�ӷ�����ʷ
      INSERT INTO sims2016TradeHist..prodRawJrnlHist(settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,coveredFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,
                                     brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,
                                     secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText)
                              SELECT settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,coveredFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,
                                     brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,
                                     secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText 
                                FROM sims2016TradeToday..prodRawJrnlToday WHERE convert(char(10), operateDatetime, 20) IN(SELECT convert(char(10), bb.operateDatetime, 20) FROM sims2016TradeToday..prodRawJrnlToday bb)
                                     AND secuBizTypeCode IN ('8001','8002','8003','8004')
                                     
      -- ����Ǩ�Ƶ���ʷ
declare     
  @v1_serialNO numeric(10,0),
  @v1_settleDate CHAR(10),
  @v1_secuBizTypeCode    VARCHAR(255),
  @v1_buySellFlagCode    VARCHAR(255),
  @v1_bizSubTypeCode    VARCHAR(255),
  @v1_openCloseFlagCode    VARCHAR(255),
  @v1_hedgeFlagCode    VARCHAR(255),
  @v1_coveredFlagCode    VARCHAR(255),
  @v1_originSecuBizTypeCode    VARCHAR(255),
  @v1_brokerSecuBizTypeCode    VARCHAR(255),
  @v1_brokerSecuBizTypeName VARCHAR(255) ,
  @v1_brokerJrnlSerialID numeric(20,0),
  @v1_prodCode    VARCHAR(255),
  @v1_fundAcctCode    VARCHAR(255),
  @v1_currencyCode    VARCHAR(255),
  @v1_cashCurrentSettleAmt numeric(19,2),
  @v1_cashCurrentBalanceAmt numeric(19,2),
  @v1_exchangeCode    VARCHAR(255),
  @v1_secuAcctCode    VARCHAR(255),
  @v1_secuCode    VARCHAR(255),
  @v1_originSecuCode    VARCHAR(255),
  @v1_secuName VARCHAR(255),
  @v1_secuTradeTypeCode    VARCHAR(255),
  @v1_matchQty numeric(19,2),
  @v1_posiCurrentBalanceQty numeric(19,2),
  @v1_matchNetPrice numeric(19,2),
  @v1_dataSourceFlagCode    VARCHAR(255),
  @v1_marketLevelCode    VARCHAR(255),
  @v1_operatorCode    VARCHAR(255),
  @v1_operateDatetime  DATETIME,
  @v1_operateRemarkText  VARCHAR(2048) 
  
        
        
      DECLARE  prodRawJrnlToday_cursor CURSOR FOR  -- �����α�
      SELECT serialNO,settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,coveredFlagCode,originSecuBizTypeCode,
             brokerSecuBizTypeCode,brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,
             secuCode,originSecuCode,secuName,secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText 
        FROM sims2016TradeToday..prodRawJrnlToday WHERE convert(char(10), operateDatetime, 20) IN(SELECT convert(char(10), bb.operateDatetime, 20) FROM sims2016TradeToday..prodRawJrnlToday bb)
             AND secuBizTypeCode NOT IN ('8001','8002','8003','8004') -- �����α�
       
       
       open prodRawJrnlToday_cursor
       
       fetch prodRawJrnlToday_cursor into @v1_serialNO, @v1_settleDate,@v1_secuBizTypeCode,@v1_buySellFlagCode,@v1_bizSubTypeCode,@v1_openCloseFlagCode,
             @v1_hedgeFlagCode,@v1_coveredFlagCode,@v1_originSecuBizTypeCode,@v1_brokerSecuBizTypeCode,@v1_brokerSecuBizTypeName,@v1_brokerJrnlSerialID,
             @v1_prodCode,@v1_fundAcctCode,@v1_currencyCode,@v1_cashCurrentSettleAmt,@v1_cashCurrentBalanceAmt,@v1_exchangeCode,@v1_secuAcctCode,@v1_secuCode,
             @v1_originSecuCode,@v1_secuName,@v1_secuTradeTypeCode,@v1_matchQty,@v1_posiCurrentBalanceQty,@v1_matchNetPrice,@v1_dataSourceFlagCode,@v1_marketLevelCode,
             @v1_operatorCode,@v1_operateDatetime,@v1_operateRemarkText      
      while @@FETCH_STATUS = 0       
      BEGIN
        
            
            -- �� �ܵĲ�Ʒ�ʽ�֤ȯ��ˮ�ŵ��ܵ���ʷ�ʽ�֤ȯ��ˮ����
            INSERT INTO sims2016TradeHist..prodRawJrnlHist(settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,coveredFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,
                                           brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,
                                           secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText)
                                    SELECT settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,coveredFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,
                                           brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,
                                           secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,operatorCode,operateDatetime,operateRemarkText 
                                      FROM sims2016TradeToday..prodRawJrnlToday WHERE serialNO = @v1_serialNO      
                                               
            IF exists(select 1 from  sims2016TradeToday..prodRawJrnlESToday WHERE serialNO = @v1_serialNO)
              begin
                INSERT INTO sims2016TradeHist..prodRawJrnlESHist(settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,
                                               brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,
                                               secuName,secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,matchSettleAmt,matchTradeFeeAmt,matchDate,matchTime,matchID,brokerOrderID,brokerOriginOrderID,
                                               brokerErrorMsg,transactionNO,investPortfolioCode,assetLiabilityTypeCode,investInstrucNO,traderInstrucNO,orderNO,orderNetAmt,orderNetPrice,orderQty,orderSettleAmt,orderSettlePrice,orderTradeFeeAmt,directorCode,
                                               traderCode,operatorCode,operateDatetime,operateRemarkText)
                                        SELECT settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,
                                               brokerSecuBizTypeName,brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,
                                               secuName,secuTradeTypeCode,matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,matchSettleAmt,matchTradeFeeAmt,matchDate,matchTime,matchID,brokerOrderID,brokerOriginOrderID,
                                               brokerErrorMsg,transactionNO,investPortfolioCode,assetLiabilityTypeCode,investInstrucNO,traderInstrucNO,orderNO,orderNetAmt,orderNetPrice,orderQty,orderSettleAmt,orderSettlePrice,orderTradeFeeAmt,directorCode,
                                               traderCode,operatorCode,operateDatetime,operateRemarkText 
                                          FROM sims2016TradeToday..prodRawJrnlESToday WHERE serialNO = @v1_serialNO
              
              end
            IF exists(select 1 from  sims2016TradeToday..prodRawJrnlFToday WHERE serialNO = @v1_serialNO)
              begin
                INSERT INTO sims2016TradeHist..prodRawJrnlFHist(settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,
                                              brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,
                                              matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,matchSettleAmt,matchTradeFeeAmt,matchDate,matchTime,matchID,brokerOrderID,brokerOriginOrderID,brokerErrorMsg,transactionNO,investPortfolioCode,
                                              assetLiabilityTypeCode,investInstrucNO,traderInstrucNO,orderNO,orderNetAmt,orderNetPrice,orderQty,orderSettleAmt,orderSettlePrice,orderTradeFeeAmt,directorCode,traderCode,operatorCode,operateDatetime,operateRemarkText)
                                       SELECT settleDate,secuBizTypeCode,buySellFlagCode,bizSubTypeCode,openCloseFlagCode,hedgeFlagCode,originSecuBizTypeCode,brokerSecuBizTypeCode,brokerSecuBizTypeName,
                                              brokerJrnlSerialID,prodCode,prodCellCode,fundAcctCode,currencyCode,cashSettleAmt,cashBalanceAmt,exchangeCode,secuAcctCode,secuCode,originSecuCode,secuName,secuTradeTypeCode,
                                              matchQty,posiBalanceQty,matchNetPrice,dataSourceFlagCode,marketLevelCode,matchSettleAmt,matchTradeFeeAmt,matchDate,matchTime,matchID,brokerOrderID,brokerOriginOrderID,brokerErrorMsg,transactionNO,investPortfolioCode,
                                              assetLiabilityTypeCode,investInstrucNO,traderInstrucNO,orderNO,orderNetAmt,orderNetPrice,orderQty,orderSettleAmt,orderSettlePrice,orderTradeFeeAmt,directorCode,traderCode,operatorCode,operateDatetime,operateRemarkText
                                         FROM sims2016TradeToday..prodRawJrnlFToday aa WHERE aa.serialNO = @v1_serialNO
              end
          fetch prodRawJrnlToday_cursor into @v1_serialNO, @v1_settleDate,@v1_secuBizTypeCode,@v1_buySellFlagCode,@v1_bizSubTypeCode,@v1_openCloseFlagCode,
             @v1_hedgeFlagCode,@v1_coveredFlagCode,@v1_originSecuBizTypeCode,@v1_brokerSecuBizTypeCode,@v1_brokerSecuBizTypeName,@v1_brokerJrnlSerialID,
             @v1_prodCode,@v1_fundAcctCode,@v1_currencyCode,@v1_cashCurrentSettleAmt,@v1_cashCurrentBalanceAmt,@v1_exchangeCode,@v1_secuAcctCode,@v1_secuCode,
             @v1_originSecuCode,@v1_secuName,@v1_secuTradeTypeCode,@v1_matchQty,@v1_posiCurrentBalanceQty,@v1_matchNetPrice,@v1_dataSourceFlagCode,@v1_marketLevelCode,
             @v1_operatorCode,@v1_operateDatetime,@v1_operateRemarkText   
     
      END
        CLOSE prodRawJrnlToday_cursor
        DEALLOCATE prodRawJrnlToday_cursor 
      
        -- ɾ�����ʽ�֤ȯ��ˮ����
        DELETE sims2016TradeToday..prodRawJrnlToday
        -- ɾ���ڻ������ʽ�֤ȯ��ˮ
        DELETE sims2016TradeToday..prodRawJrnlESToday
        -- ɾ���ֻ������ʽ�֤ȯ��ˮ
        DELETE sims2016TradeToday..prodRawJrnlFToday
        
        
        -- ������־���ձ�/������ϸ��־���ձ�Ǩ��
   
        -- ɾ����ʷ EXISTS��IN�ڴ˴�����һ�� sq_operateLogHist
        DELETE aa FROM sims2016TradeHist..operateLogHist aa WHERE convert(char(10), aa.operateDatetime, 20) IN(SELECT convert(char(10), bb.operateDatetime, 20) FROM sims2016TradeToday..operateLogToday bb WHERE convert(char(10), bb.operateDatetime, 20) != convert(char(10), GETDATE(), 20))  
        -- ɾ����ʷ EXISTS��IN�ڴ˴�����һ��
        DELETE aa FROM sims2016TradeHist..operateLogDetailHist aa WHERE EXISTS
          (SELECT bb.serialNO, bb.tableName, bb.tagCode, bb.operateDatetime FROM sims2016TradeToday..operateLogDetailToday bb WHERE aa.serialNO = bb.serialNO AND aa.tableName = bb.tableName AND aa.tagCode = bb.tagCode AND convert(char(10), bb.operateDatetime, 20) != convert(char(10), GETDATE(), 20))  


        DECLARE 
        @v2_serialNO numeric(10,0),
        @v2_logLevelCode VARCHAR(255),
        @v2_functionNO numeric(10,0),
        @v2_operateStationText VARCHAR(2048),
        @v2_operatorCode VARCHAR(255),
        @v2_operateDatetime DATETIME,
        @v2_operateRemarkText VARCHAR(2048)
        DECLARE  operateLogToday_cursor CURSOR FOR  -- �����α�
        SELECT serialNO,logLevelCode,functionNO,operateStationText,operatorCode,operateDatetime,operateRemarkText FROM sims2016TradeToday..operateLogToday -- �����α�
        OPEN operateLogToday_cursor
          FETCH operateLogToday_cursor INTO @v2_serialNO,
                                            @v2_logLevelCode,
                                            @v2_functionNO,
                                            @v2_operateStationText,
                                            @v2_operatorCode,
                                            @v2_operateDatetime,
                                            @v2_operateRemarkText
      WHILE @@FETCH_STATUS =0
                                                  
        BEGIN
      
           -- Emp_record Ϊ��������ļ�¼����,ѭ����ִ�д������α�ȡ�õ����ݵ�������һ��  
              --��������ֵ(����)
  
              
              -- ��Ʒ��Ԫ��Ʊ�ֲֵ������ձ�Ǩ�Ƶ���ʷ һ��һ���İ���
              INSERT INTO sims2016TradeHist..operateLogHist(logLevelCode,functionNO,operateStationText,operatorCode,operateDatetime,operateRemarkText)
                   SELECT logLevelCode,functionNO,operateStationText,operatorCode,operateDatetime,operateRemarkText 
                     FROM sims2016TradeToday..operateLogToday WHERE serialNO = @v2_serialNO AND convert(char(10), operateDatetime, 20) != convert(char(10), GETDATE(), 20)
              
              -- ������ϸ��־���ձ�Ǩ�� ���ܳ��ֶ�������(ԭ���ǣ�һ��������־��¼���ܶ�Ӧ������¼�����ͬ�Ĳ�����־��ϸ��¼) OperateLogDetailHist��¼��ſ����ظ�,��Ϊ����Ψһ����
              INSERT INTO sims2016TradeHist..operateLogDetailHist(tableName,tagCode,tagName,oldValueText,newValueText,operatorCode,operateDatetime,operateRemarkText)
                   SELECT tableName,tagCode,tagName,oldValueText,newValueText,operatorCode,operateDatetime,operateRemarkText
                     FROM sims2016TradeToday..operateLogDetailToday WHERE serialNO = @v2_serialNO AND convert(char(10), operateDatetime, 20) != convert(char(10), GETDATE(), 20)
              
                    FETCH operateLogToday_cursor INTO @v2_serialNO,
                                            @v2_logLevelCode,
                                            @v2_functionNO,
                                            @v2_operateStationText,
                                            @v2_operatorCode,
                                            @v2_operateDatetime,
                                            @v2_operateRemarkText
           
        END
        
        CLOSE operateLogToday_cursor
        DEALLOCATE operateLogToday_cursor 
        
        -- �����־����
        DELETE sims2016TradeToday..operateLogToday WHERE convert(char(10), operateDatetime, 20) != convert(char(10), GETDATE(), 20)
        -- ���������ϸ��־���ձ�
        DELETE sims2016TradeToday..operateLogDetailToday WHERE convert(char(10), operateDatetime, 20) != convert(char(10), GETDATE(), 20)
      
      
      -- ������֤��¼���ձ�Ǩ�� PasswordValidateJrnlHist��¼���������
    
        -- ɾ����ʷ EXISTS��IN�ڴ˴�����һ��
        DELETE aa FROM sims2016TradeHist..passwordValidateJrnlHist aa WHERE convert(char(10), aa.operateDatetime, 20) IN (SELECT convert(char(10), bb.operateDatetime, 20) FROM sims2016TradeToday..passwordValidateJrnlToday bb)  
        -- ������֤��¼���ձ�Ǩ��
        INSERT INTO sims2016TradeHist..passwordValidateJrnlHist(staffCode,macAddressText,operateDatetime)
        SELECT staffCode,macAddressText,operateDatetime FROM sims2016TradeToday..passwordValidateJrnlToday
        
        -- �������
        DELETE sims2016TradeToday..passwordValidateJrnlToday
        
         -- ��Ʒ�ֻ��ֲֵ������ձ�Ǩ��  prodPosiESChgHist��¼���������
      BEGIN
        -- ɾ����ʷ 
        DELETE aa FROM sims2016TradeHist..prodPosiESChgHist aa WHERE aa.operateDate IN (SELECT bb.operateDate FROM sims2016TradeToday..prodPosiESChgToday bb)  
        -- ��Ʒ�ֻ��ֲֵ������ձ�Ǩ��
        INSERT INTO sims2016TradeHist..prodPosiESChgHist(operateDate,prodCode,fundAcctCode,secuAcctCode,exchangeCode,secuCode,longShortFlagCode,hedgeFlagCode,posiAvailableChgQty,posiAvailableFrzChgQty,
                                         posiBuyedChgQty,posiBuyedFrzChgQty,posiBuyingChgQty,investRecentRlzChgProfit,investCostChgAmt,operatorCode,operateDatetime,operateRemarkText)
                                  SELECT operateDate,prodCode,fundAcctCode,secuAcctCode,exchangeCode,secuCode,longShortFlagCode,hedgeFlagCode,posiAvailableChgQty,posiAvailableFrzChgQty,
                                         posiBuyedChgQty,posiBuyedFrzChgQty,posiBuyingChgQty,investRecentRlzChgProfit,investCostChgAmt,operatorCode,operateDatetime,operateRemarkText
                                    FROM sims2016TradeToday..prodPosiESChgToday    
        -- �������
        DELETE sims2016TradeToday..prodPosiESChgToday
        
      END
      
      -- ��Ʒ��Ԫ��Ʊ�ֲֵ������ձ�Ǩ�� prodCellPosiESChgHist��¼���������
      BEGIN
        -- ɾ����ʷ 
        DELETE aa FROM sims2016TradeHist..prodCellPosiESChgHist aa WHERE aa.operateDate IN (SELECT operateDate FROM sims2016TradeToday..prodCellPosiESChgToday bb)
    
        -- ��Ʒ��Ԫ��Ʊ�ֲֵ������ձ�Ǩ��
        INSERT INTO sims2016TradeHist..prodCellPosiESChgHist(operateDate,prodCode,prodCellCode,fundAcctCode,secuAcctCode,exchangeCode,secuCode,longShortFlagCode,hedgeFlagCode,investPortfolioCode,transactionNO,posiAvailableChgQty,posiAvailableFrzChgQty,
                                             posiBuyedChgQty,posiBuyedFrzChgQty,posiBuyingChgQty,investRecentRlzChgProfit,investCostChgAmt,operatorCode,operateDatetime,operateRemarkText)
                                      SELECT operateDate,prodCode,prodCellCode,fundAcctCode,secuAcctCode,exchangeCode,secuCode,longShortFlagCode,hedgeFlagCode,investPortfolioCode,transactionNO,posiAvailableChgQty,posiAvailableFrzChgQty,
                                             posiBuyedChgQty,posiBuyedFrzChgQty,posiBuyingChgQty,investRecentRlzChgProfit,investCostChgAmt,operatorCode,operateDatetime,operateRemarkText
                                        FROM sims2016TradeToday..prodCellPosiESChgToday
        
        -- �������
        DELETE sims2016TradeToday..prodCellPosiESChgToday
      END
      
      -- ע���¼��
      BEGIN
        -- ɾ������ļ�¼
        DELETE sims2016TradeToday..loginJrnl WHERE convert(char(10), operateDatetime, 20) != convert(char(10), GETDATE(), 20)
      END

  SELECT @O_ERRORMSGCODE = 0, @O_ERRORMSGTEXT = '����Ǩ�����'

  RETURN 0
go    

--exec opMoveTradeDataTodayToHist '' ,'','',''
