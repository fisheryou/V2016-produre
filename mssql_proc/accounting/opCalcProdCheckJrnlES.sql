
  USE sims2016Proc
go

IF(SELECT count(*) FROM sysobjects WHERE name = 'opCalcProdCheckJrnlES') > 0
    DROP PROC opCalcProdCheckJrnlES
go

--'9999','','','','','','','2017-01-01'
CREATE PROC opCalcProdCheckJrnlES

  @i_operatorCode          VARCHAR(30),     --����Ա����
  @i_operatorPassword      VARCHAR(30),     --����Ա����
  @i_operateStationText    VARCHAR(30),     --������Ϣ
  @i_prodCode              VARCHAR(4096),     --��Ʒ����
  @i_fundAcctCode          VARCHAR(4096),     --�ʽ��˻�
  @i_exchangecode          VARCHAR(4096),     --����������
  @i_secuCode              VARCHAR(4096),     --֤ȯ����
  @i_beginDate             VARCHAR(10)           --��ʼ����

AS
/*****************************************************************************
 *
 *                            sims2016derive
 *
 * ===========================================================================
 *
 * FileName      �� opCalcProdCheckJrnlES.sql
 * ProcedureName �� opCalcProdCheckJrnlES
 * Description   :  ��Ʒ��Ʊ���������ɱ��ĺ��㡢ת�봫������,��Ӧ��ˮ����
 * Author        :  zhangkh
 * Date          :  2017-03-20
 * Version       :  1.0.0.0
 *       V1.0.0.0:  ֧�ֹ�Ʊ�����ɽ�ҵ��ת��ת��ҵ��
 * Function List :  opCalcProdCheckJrnlES
 * History       :  
 * 1. Date         :  2017-03-20
 *    Author       :  zhangkh
 *    ModIFication :  ���±�д
 * ===========================================================================
 * NOTE :
 *   2. DateBase: Oracle11gR2
 *   1. Platform: UNIX/Windows
\*****************************************************************************/
--�α����BEGIN
DECLARE @v_serialNO                      NUMERIC(19,0),      --��¼���
        @v_orderID                       NUMERIC(10,0),      --����Id
        @v_settleDate                    VARCHAR(10),        --��������
        @v_shareRecordDate               VARCHAR(10),        --�Ǽ�����
        @v_fundAcctCode                  VARCHAR(30),        --�ʽ��˻�
        @v_exchangeCode                  VARCHAR(4),         --����������
        @v_secuCode                      VARCHAR(40),        --֤ȯ����
        @v_originSecuCode                VARCHAR(40),        --ԭʼ֤ȯ����
        @v_secuName                      VARCHAR(60),        --֤ȯ����
        @v_secuTradeTypeCode             VARCHAR(30),        --֤ȯ���
        @v_prodCode                      VARCHAR(30),        --��Ʒ����
        @v_buySellFlagCode               VARCHAR(16),         --�������
        @v_openCloseFlagCode             VARCHAR(16),         --��ƽ��־
        @v_marketLevelCode               VARCHAR(16),         --�г���Դ
        @v_currencyCode                  VARCHAR(16),         --���Ҵ���
        @v_longShortFlagCode             VARCHAR(16),        --��ձ�־
        @v_hedgeFlagCode                 VARCHAR(16),         --Ͷ����־
        @v_secuBizTypeCode               VARCHAR(30),        --ҵ������
        @v_matchQty                      NUMERIC(19,4),      --�ɽ�����
        @v_matchNetPrice                 NUMERIC(10,4),      --�ɽ��۸�
        @v_cashCurrentSettleAmt          NUMERIC(19,4),      --�ʽ�����
        @v_matchTradeFeeAmt              NUMERIC(19,4),      --������
        @v_matchSettleAmt                NUMERIC(19,4),      --�ɽ�������
        @v_costChgAmt                    NUMERIC(19,4),      --�ƶ�ƽ���ɱ��䶯
        @v_rlzChgProfit                  NUMERIC(19,4),      --ʵ��ӯ���䶯
        --�α����END
        
        @v_createPosiDate                VARCHAR(10),        --��������
        @v_posiQty                       NUMERIC(19,4),      --�ֲ�����
        @v_lastSettleDate                VARCHAR(10),        --��󽨲�����
        @v_buy_costChgAmt                NUMERIC(19,4),      --�ƶ�ƽ���ɱ�����          
        @v_occupyCostChgAmt              NUMERIC(19,4),      --ռ�óɱ��䶯
        @o_fundAcctCode                  VARCHAR(30),        --�ʽ��˻�,�α�ѭ����ǩ
        
        @v_realBeginDate                 VARCHAR(10),        --�ɱ����㿪ʼ����
        
        @v_today                         VARCHAR(10),        --��ǰ����--�α����
        @temp_shareRecordDate            VARCHAR(10),        --�Ǽ�����(��ʱ����)
        
        @temp_mc_matchQty                NUMERIC(19,4),      --�����ɽ�����(��ʱ����)
        @temp_mc_per_costChgAmt          NUMERIC(19,8),      --�����ƶ�ƽ���ɱ��䶯(��ʱ����)
        @temp_mc_costChgAmt              NUMERIC(19,4),      --�����ƶ�ƽ���ɱ��䶯(��ʱ����)
        @temp_mc_per_rlzChgProfit        NUMERIC(19,8),      --����ʵ��ӯ���䶯(��ʱ����)
        @temp_mc_rlzChgProfit            NUMERIC(19,4),      --����ʵ��ӯ���䶯(��ʱ����)
        @temp_mc_per_cashCurrSettleAmt   NUMERIC(19,8),      --�����ʽ�����(��ʱ����)
        @temp_mc_cashCurrSettleAmt       NUMERIC(19,4),      --�����ʽ�����(��ʱ����)
        @temp_mc_per_matchTradeFeeAmt    NUMERIC(19,8),      --�������׷���(��ʱ����)
        @temp_mc_matchTradeFeeAmt        NUMERIC(19,4),      --�������׷���(��ʱ����)
        
        @temp_mr_prodCode                VARCHAR(30),        --�����Ʒ����(��ʱ����)
        @temp_mr_matchQty                NUMERIC(19,4),      --����ɽ�����(��ʱ����)
        @temp_mr_per_costChgAmt          NUMERIC(19,8),      --�����ƶ�ƽ���ɱ��䶯1(��ʱ����)
        @temp_mr_costChgAmt              NUMERIC(19,4),      --�����ƶ�ƽ���ɱ��䶯(��ʱ����)
        @temp_mr_createPosiDate          VARCHAR(10),        --���뽨������(��ʱ����)
        
        @v_findRow                       NUMERIC(19,4),
        @v_prodCodes                     VARCHAR(4096),
        @v_fundAcctCodes                 VARCHAR(4096),
        @v_exchangeCodes                 VARCHAR(4096),
        @v_secuCodes                     VARCHAR(4096),
        @v_hasCapitalOnLine              NUMERIC(19,4),
        @v_divCode                       VARCHAR(1)       --��Ϣ�Ƿ����ɱ�
  
  SELECT @v_findRow = 0, @v_prodCodes = ',' + @i_prodCode + ',', @v_fundAcctCodes =',' + @i_fundAcctCode + ',' ,@v_exchangeCodes = ',' + @i_exchangecode + ',',
         @v_secuCodes = ',' + @i_secuCode + ',', @v_hasCapitalOnLine =0     
  SELECT @v_today = CONVERT(VARCHAR(10),GETDATE(), 21) 
  --����ɱ����㿪ʼ����
  SELECT @v_realBeginDate = dbo.fnGetCheckJrnlBeginDate(@i_beginDate)

  SELECT @v_hasCapitalOnLine = COUNT(fundAcctCode) FROM sims2016TradeToday.dbo.prodCapital 
    WHERE (ISNULL(@i_fundAcctCode, ' ') = ' ' OR CHARINDEX(',' + fundAcctCode + ',', @v_fundAcctCodes) > 0) AND capitalOffLineFlagCode = '1'  
    
  SELECT @v_divCode = itemValueText FROM sims2016TradeToday..commonCfg WHERE itemCode = '2009' --0 ����ʵ��ӯ���� 1 ����ƶ�ƽ���ɱ�
  --��ʱ
  IF ISNULL(@v_divCode, '') ='' 
  SELECT @v_divCode = '1'
  
  IF @v_hasCapitalOnLine > 0 
    RETURN

  --ɾ����ʷ������ˮ����ڿ�ʼ���ڵļ�¼

  DELETE FROM sims2016TradeHist.dbo.prodCheckJrnlESHist
          WHERE settleDate >= @v_realBeginDate 
            AND(ISNULL(@i_prodCode, ' ') = ' ' OR CHARINDEX(',' + prodCode + ',',@v_prodCodes) > 0)
            AND(ISNULL(@i_fundAcctCode, ' ') = ' ' OR CHARINDEX(',' + fundAcctCode + ',', @v_fundAcctCodes) > 0)
            AND(ISNULL(@i_exchangecode, ' ') = ' ' OR CHARINDEX(',' + exchangeCode + ',', @v_exchangeCodes) > 0)
            AND(ISNULL(@i_secuCode, ' ') = ' ' OR CHARINDEX(@v_secuCodes, ',' + secuCode + ',') > 0)

  SELECT serialNO, orderNO AS orderID, settleDate,shareRecordDate,  
         fundAcctCode, prodCode, currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
         secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, CONVERT(varchar(16),'1') AS longShortFlagCode, hedgeFlagCode, buySellFlagCode, 
         matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt,cashSettleAmt, cashSettleAmt AS costChgAmt, 0 AS rlzChgProfit
         INTO #tt_prodRawJrnl
         FROM sims2016TradeHist.dbo.prodRawJrnlESHist
         WHERE 0=1
                  
  SELECT serialNO, createPosiDate, settleDate,
         prodCode, fundAcctCode, currencyCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, marketLevelCode,
         buySellFlagCode, bizSubTypeCode, openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, matchQty,
         matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, costChgAmt, occupyCostChgAmt,
         rlzChgProfit, CONVERT(VARCHAR(10),'') AS shareRecordDate,CONVERT(VARCHAR(40),'') AS secuName
         INTO #tt_prodCheckJrnlES
         FROM sims2016TradeHist.dbo.prodCheckJrnlESHist
         WHERE 0=1
                  
  SELECT exchangeCode, secuCode, prodCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, matchQty AS posiQty, costChgAmt, settleDate AS lastestOperateDate
         INTO #tt_prodCreatePosiDate
         FROM sims2016TradeHist.dbo.prodCheckJrnlESHist
         WHERE 0=1
                  
  SELECT exchangeCode, secuCode, prodCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, matchQty AS posiQty, costChgAmt, settleDate AS lastestOperateDate
         INTO #tt_prodCreatePosiDateSum
         FROM sims2016TradeHist.dbo.prodCheckJrnlESHist
         WHERE 0=1                     
           
 --ȡ��Ʒ��Ʊ��ʷ�ʽ�֤ȯ��ˮ
    INSERT INTO #tt_prodRawJrnl(serialNO, orderID, settleDate,  
                               fundAcctCode, prodCode, currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
                               secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, longShortFlagCode, hedgeFlagCode, buySellFlagCode, 
                               matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt,cashSettleAmt, costChgAmt, rlzChgProfit
                               )
                        SELECT MAX(serialNO), 0, settleDate,  
                               fundAcctCode, prodCode,currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
                               secuBizTypeCode, MAX(bizSubTypeCode), openCloseFlagCode, '1', hedgeFlagCode, buySellFlagCode,
                               SUM(ABS(matchQty)), CASE WHEN SUM(matchQty) = 0 THEN 0 ELSE SUM(matchQty*matchNetPrice) / SUM(matchQty) END, SUM(matchSettleAmt), SUM(matchTradeFeeAmt), SUM(cashSettleAmt), SUM(-cashSettleAmt), 0
                          FROM sims2016TradeHist.dbo.prodRawJrnlESHist a
                         WHERE settleDate >= @v_realBeginDate
                           AND settleDate <= @v_today  
                           AND (ISNULL(@i_fundAcctCode, '') = '' OR CHARINDEX(',' + a.fundAcctCode + ',', @v_fundAcctCodes)> 0)
                           AND (ISNULL(@i_exchangecode, '') = '' OR CHARINDEX(',' + a.exchangeCode + ',', @v_exchangeCodes) > 0)
                           AND (ISNULL(@i_secuCode, '') = '' OR CHARINDEX(',' + a.secuCode + ',', @v_secuCodes) > 0 OR CHARINDEX(',' + a.originSecuCode + ',', @v_secuCodes) > 0)
                      GROUP BY settleDate, prodCode, fundAcctCode, currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, secuBizTypeCode, openCloseFlagCode, hedgeFlagCode, buySellFlagCode
                      ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, a.originSecuCode, secuBizTypeCode, buySellFlagCode, MAX(serialNO)
 

  --ȡ��Ʒ֤ȯ�ֲ�ת����ˮ(8101)
    INSERT INTO #tt_prodRawJrnl(serialNO, orderID, settleDate,  
                               fundAcctCode, prodCode, currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
                               secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, longShortFlagCode, hedgeFlagCode, buySellFlagCode, 
                               matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt,cashSettleAmt, costChgAmt, rlzChgProfit
                               )      
                        SELECT serialNO, 0, settleDate,  
                               fundAcctCode, prodCode, currencyCode, 
                               marketLevelCode, exchangeCode, secuCode, 
                               ' ', secuTradeTypeCode, secuBizTypeCode, 
                               'S1', '1', '1', 
                               hedgeFlagCode, '1', ABS(matchQty), 
                               CASE WHEN matchQty = 0 THEN 0 ELSE investCostAmt / matchQty END, 0, 0, 
                               0, investCostAmt, 0
                          FROM sims2016TradeHist.dbo.prodInOutESHist a
                         WHERE secuBizTypeCode = '8101'
                           AND settleDate >= @v_realBeginDate
                           AND settleDate <= @v_today                   
                           AND (ISNULL(@i_fundAcctCode, '') = '' OR CHARINDEX(',' + a.fundAcctCode + ',', @v_fundAcctCodes)> 0)
                           AND (ISNULL(@i_exchangecode, '') = '' OR CHARINDEX(',' + a.exchangeCode + ',', @v_exchangeCodes) > 0)
                           AND (ISNULL(@i_secuCode, '') = '' OR CHARINDEX(',' + a.secuCode + ',', @v_secuCodes) > 0 OR CHARINDEX(',' + a.originSecuCode + ',', @v_secuCodes) > 0)
                      ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, secuBizTypeCode

  
 --ȡ��Ʒ֤ȯ�ֲ�ת����ˮ(8103)
    INSERT INTO #tt_prodRawJrnl(serialNO, orderID, settleDate,  
                               fundAcctCode, prodCode, currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
                               secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, longShortFlagCode, hedgeFlagCode, buySellFlagCode, 
                               matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt,cashSettleAmt, costChgAmt, rlzChgProfit
                               )   
                       SELECT serialNO, 0, settleDate,  
                              fundAcctCode, prodCode, currencyCode, marketLevelCode, exchangeCode, secuCode, 
                              ' ', secuTradeTypeCode, secuBizTypeCode, 'S1', 'A', '1', 
                              hedgeFlagCode, '1', ABS(matchQty), 
                              CASE WHEN matchQty = 0 THEN 0 ELSE investCostAmt / matchQty END, 0, 0, 0, investCostAmt, 0
                         FROM sims2016TradeHist.dbo.prodInOutESHist a
                        WHERE secuBizTypeCode = '8103'
                          AND settleDate >= @v_realBeginDate
                          AND settleDate <= @v_today                   
                          AND (ISNULL(@i_fundAcctCode, '') = '' OR CHARINDEX(',' + a.fundAcctCode + ',', @v_fundAcctCodes)> 0)
                          AND (ISNULL(@i_exchangecode, '') = '' OR CHARINDEX(',' + a.exchangeCode + ',', @v_exchangeCodes) > 0)
                          AND (ISNULL(@i_secuCode, '') = '' OR CHARINDEX(',' + a.secuCode + ',', @v_secuCodes) > 0 OR CHARINDEX(',' + a.originSecuCode + ',', @v_secuCodes) > 0)
                     ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, secuBizTypeCode

  --��������
  SELECT @o_fundAcctCode =  NULL      
  DECLARE T_prodRawJrnl CURSOR FOR SELECT serialNO, orderID, settleDate, shareRecordDate, fundAcctCode, prodCode,
                          exchangeCode, secuCode, originSecuCode, '', secuTradeTypeCode,
                          buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, currencyCode, hedgeFlagCode, longShortFlagCode,
                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt, costChgAmt, rlzChgProfit
                     FROM #tt_prodRawJrnl 
                 ORDER BY fundAcctCode, settleDate, exchangeCode, secuCode, orderID, buySellFlagCode DESC, serialNO
    OPEN T_prodRawJrnl
    FETCH NEXT FROM T_prodRawJrnl INTO @v_serialNO,  @v_orderID, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,
      @v_exchangeCode, @v_secuCode, @v_originSecuCode, @v_secuName, @v_secuTradeTypeCode, 
      @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_currencyCode, @v_hedgeFlagCode, @v_longShortFlagCode, 
      @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, @v_costChgAmt, @v_rlzChgProfit
    WHILE @@fetch_status = 0
    BEGIN
      IF (@o_fundAcctCode IS NOT NULL)
        BEGIN
          INSERT INTO sims2016TradeHist.dbo.prodCheckJrnlESHist(createPosiDate, settleDate,
                                          prodCode, fundAcctCode, currencyCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, marketLevelCode,
                                          buySellFlagCode, bizSubTypeCode, openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, matchQty,
                                          matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, costChgAmt, occupyCostChgAmt,
                                          rlzChgProfit, investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                                   SELECT createPosiDate, settleDate, 
                                          prodCode, fundAcctCode, currencyCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode, marketLevelCode,
                                          buySellFlagCode, 'S1', openCloseFlagCode, '1', hedgeFlagCode, secuBizTypeCode, matchQty,
                                          matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, costChgAmt, occupyCostChgAmt,
                                          rlzChgProfit, costChgAmt, occupyCostChgAmt, rlzChgProfit
                                     FROM #tt_prodCheckJrnlES
          TRUNCATE TABLE #tt_prodCheckJrnlES
        END

      IF (@o_fundAcctCode IS NULL OR @o_fundAcctCode != @v_fundAcctCode) 
        BEGIN
          SELECT @o_fundAcctCode =  @v_fundAcctCode
          TRUNCATE TABLE #tt_prodCreatePosiDate
          TRUNCATE TABLE #tt_prodCreatePosiDateSum
          --ȡ���ձ�(TODO)
          --ȡ��ʷ������ˮ��

            INSERT INTO #tt_prodCreatePosiDate(exchangeCode, secuCode, prodCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                       SELECT exchangeCode, secuCode, prodCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, MAX(createPosiDate), SUM(matchQty), SUM(costChgAmt), MAX(settleDate)
                                         FROM sims2016TradeHist.dbo.prodCheckJrnlESHist
                                        WHERE settleDate < @v_realBeginDate -- AND settleDate > �������� (���������ձ���ƺú���ϴ�����)
                                          AND fundAcctCode = @v_fundAcctCode
                                          AND (ISNULL(@i_exchangecode, '') = '' OR CHARINDEX(@v_exchangeCodes, ',' + exchangeCode + ',') > 0)
                                          AND (ISNULL(@i_secuCode, '') = '' OR CHARINDEX(@v_secuCodes, ',' + secuCode + ',') > 0 OR CHARINDEX(@v_secuCodes, ',' + originSecuCode + ',') > 0)
                                     GROUP BY prodCode, exchangeCode, secuCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode
    

            INSERT INTO #tt_prodCreatePosiDateSum(exchangeCode, secuCode, prodCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                          SELECT exchangeCode, secuCode, prodCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, MAX(createPosiDate), SUM(posiQty), SUM(costChgAmt), MAX(lastestOperateDate)
                                            FROM #tt_prodCreatePosiDate
                                        GROUP BY prodCode, exchangeCode, secuCode, createPosiDate, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode
                                          HAVING SUM(posiQty) > 0
        END

      IF (@v_exchangeCode = '' AND @v_secuCode = '')
        BEGIN
          TRUNCATE TABLE #tt_prodCreatePosiDate
        END
       ELSE IF @v_secuBizTypeCode in('103','106') 
			BEGIN
		    INSERT #tt_prodCheckJrnlES( createPosiDate, settleDate,
                                    prodCode, fundAcctCode, currencyCode,  
                                    exchangeCode, secuCode, originSecuCode, secuName, secuTradeTypeCode,
                                    marketLevelCode, buySellFlagCode, 
                                    openCloseFlagCode,  longShortFlagCode, hedgeFlagCode, secuBizTypeCode,  
                                    matchQty,
                                    matchNetPrice, cashSettleAmt, matchSettleAmt,
                                    matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                            SELECT  @v_settleDate, @v_settleDate,
                                    @v_prodCode, @v_fundAcctCode, @v_currencyCode,
                                    @v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', @v_secuTradeTypeCode,
                                    @v_marketLevelCode, @v_buySellFlagCode,
                                    @v_openCloseFlagCode, '1', @v_hedgeFlagCode, @v_secuBizTypeCode, 
                                    @v_matchQty,
                                    @v_matchNetPrice, 0, 0,
                                    0, 0, 0, 0     										
			END
		-- �¹����С�
    ELSE IF(@v_secuBizTypeCode = '107')
			BEGIN			
				--�깺��ǩת����¼
		    INSERT #tt_prodCheckJrnlES( createPosiDate, settleDate,
																		prodCode, fundAcctCode, currencyCode,  
																		exchangeCode, secuCode, originSecuCode, secuName, secuTradeTypeCode,
																		marketLevelCode, buySellFlagCode, 
																		openCloseFlagCode, longShortFlagCode,  hedgeFlagCode, secuBizTypeCode,  
																		matchQty,
																		matchNetPrice, cashSettleAmt, matchSettleAmt,
																		matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
														SELECT  @v_settleDate, @v_settleDate,
																		@v_prodCode, @v_fundAcctCode, @v_currencyCode,
																		@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', @v_secuTradeTypeCode,
																		@v_marketLevelCode, @v_buySellFlagCode,
																		@v_openCloseFlagCode, '1', @v_hedgeFlagCode, '1071', 
																		-@v_matchQty,
																	  0 as matchNetPrice, @v_cashCurrentSettleAmt, 0,
                                    0, -@v_costChgAmt, @v_cashCurrentSettleAmt, 0  
																	
				
         --�깺��ǩ����ת��
		    INSERT #tt_prodCheckJrnlES( createPosiDate, settleDate,
																		prodCode, fundAcctCode, currencyCode,  
																		exchangeCode, secuCode, originSecuCode, secuName, secuTradeTypeCode,
																		marketLevelCode, buySellFlagCode, 
																		openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode,  
																		matchQty,
																		matchNetPrice, cashSettleAmt, matchSettleAmt,
																		matchTradeFeeAmt, costChgAmt, occupyCostChgAmt, rlzChgProfit) 
														SELECT  @v_settleDate, @v_settleDate,
																		@v_prodCode, @v_fundAcctCode, @v_currencyCode,
																		@v_exchangeCode, @v_secuCode, @v_originSecuCode, ' ', @v_secuTradeTypeCode,
																		@v_marketLevelCode, @v_buySellFlagCode,
																		@v_openCloseFlagCode, '1',@v_hedgeFlagCode, '1072', 
																		@v_matchQty,
																	  0 as matchNetPrice, @v_cashCurrentSettleAmt, 0,
                                    0, @v_costChgAmt, -@v_cashCurrentSettleAmt, 0  
																	
			END    
      ELSE IF (@v_buySellFlagCode = '1' AND @v_openCloseFlagCode = '1' AND @v_secuBizTypeCode != '183' AND @v_secuBizTypeCode != '187' AND @v_secuBizTypeCode != '188') --���봦��
        BEGIN
          SELECT @v_createPosiDate =  null, @v_posiQty =  null, @v_lastSettleDate =  NULL
   
            SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastSettleDate = lastestOperateDate 
              FROM #tt_prodCreatePosiDate
             WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCode = @v_prodCode AND currencyCode = @v_currencyCode 
                   AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode    

          IF @v_createPosiDate IS NULL 
            BEGIN
              INSERT INTO #tt_prodCreatePosiDateSum(exchangeCode, secuCode, prodCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                         VALUES(@v_exchangeCode, @v_secuCode, @v_prodCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate)
              SELECT @v_createPosiDate =   @v_settleDate   
    
            END
          ELSE IF(@v_posiQty <= 0 AND @v_lastSettleDate != @v_settleDate)
            BEGIN
            
              UPDATE #tt_prodCreatePosiDateSum SET createPosiDate = @v_settleDate,
                                                posiQty = @v_matchQty,
                                                costChgAmt = @v_costChgAmt,
                                                lastestOperateDate = @v_settleDate
                                            WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCode = @v_prodCode AND currencyCode = @v_currencyCode 
                                                  AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode    

            END
          ELSE 
            BEGIN
              UPDATE #tt_prodCreatePosiDateSum SET createPosiDate = @v_createPosiDate,
                                                posiQty = posiQty + @v_matchQty,
                                                costChgAmt = costChgAmt + @v_costChgAmt,
                                                lastestOperateDate = @v_settleDate
                                            WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCode = @v_prodCode AND currencyCode = @v_currencyCode 
                                                  AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
            END

            INSERT INTO #tt_prodCheckJrnlES (createPosiDate, settleDate, shareRecordDate, fundAcctCode, prodCode,
                                            exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                            buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                            matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                            costChgAmt, occupyCostChgAmt, rlzChgProfit, longShortFlagCode)
                                     VALUES(@v_createPosiDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode,@v_prodCode,
                                            @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                            @v_secuTradeTypeCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode, @v_currencyCode,
                                            @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                                            @v_costChgAmt,@v_costChgAmt, @v_rlzChgProfit,'1')

        END
      ELSE IF (@v_buySellFlagCode = '1' AND @v_openCloseFlagCode = 'A' AND @v_secuBizTypeCode != '183' AND @v_secuBizTypeCode != '187' AND @v_secuBizTypeCode != '188') --��������
        BEGIN

          SELECT @v_costChgAmt =  ROUND(@v_costChgAmt, 2),
                 @temp_mc_per_costChgAmt =  @v_costChgAmt / @v_matchQty,
                 @temp_mc_per_rlzChgProfit =  @v_rlzChgProfit / @v_matchQty,
                 @temp_mc_per_cashCurrSettleAmt =  @v_cashCurrentSettleAmt / @v_matchQty,
                 @temp_mc_per_matchTradeFeeAmt =  @v_matchTradeFeeAmt / @v_matchQty

          WHILE @v_matchQty > 0            
          BEGIN

            SELECT @temp_mr_prodCode =  NULL
            SELECT top 1 @temp_mr_prodCode = prodCode, @temp_mr_matchQty = posiQty, @temp_mr_costChgAmt = costChgAmt, @temp_mr_per_costChgAmt = costChgAmt / posiQty, 
                       @temp_mr_createPosiDate = createPosiDate
            FROM #tt_prodCreatePosiDateSum
            WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCode = @v_prodCode AND posiQty > 0  AND currencyCode = @v_currencyCode 
                  AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
            ORDER BY createPosiDate     
         
            IF (@temp_mr_prodCode IS NOT null) 
            BEGIN
              IF (@temp_mr_matchQty > @v_matchQty) 
                SELECT @temp_mc_matchQty =  @v_matchQty
              ELSE
                SELECT @temp_mc_matchQty =  @temp_mr_matchQty
         
              SELECT @v_matchQty =  @v_matchQty - @temp_mc_matchQty
              IF @v_matchQty != 0 
              BEGIN
                SELECT @temp_mc_costChgAmt =  ROUND(@temp_mc_matchQty * @temp_mc_per_costChgAmt, 2),
                       @temp_mc_cashCurrSettleAmt =  ROUND(@temp_mc_matchQty * @temp_mc_per_cashCurrSettleAmt, 2),
                       @temp_mc_matchTradeFeeAmt =  ROUND(@temp_mc_matchQty * @temp_mc_per_matchTradeFeeAmt, 2)
              	 
              END
              ELSE
              BEGIN
                SELECT @temp_mc_costChgAmt =  @v_costChgAmt,
                       @temp_mc_cashCurrSettleAmt =  @v_cashCurrentSettleAmt,
                       @temp_mc_matchTradeFeeAmt =  @v_matchTradeFeeAmt              
              END
         
              IF (@temp_mc_matchQty != @temp_mr_matchQty)
              BEGIN
               SELECT @temp_mr_costChgAmt =  ROUND(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)
              END
              
              SELECT @temp_mc_rlzChgProfit =  -@temp_mc_costChgAmt - @temp_mr_costChgAmt
              SELECT @v_costChgAmt =  @v_costChgAmt - @temp_mc_costChgAmt
              SELECT @v_cashCurrentSettleAmt =  @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt
              SELECT @v_matchTradeFeeAmt =  @v_matchTradeFeeAmt - @temp_mc_matchTradeFeeAmt
      
              UPDATE #tt_prodCreatePosiDateSum SET posiQty = posiQty - @temp_mc_matchQty,
                                            costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                            lastestOperateDate = @v_settleDate
                                        WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCode = @temp_mr_prodCode AND currencyCode = @v_currencyCode 
                                              AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 


                INSERT INTO #tt_prodCheckJrnlES(createPosiDate, settleDate, shareRecordDate, fundAcctCode, prodCode,
                                               exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, 
                                               buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                               matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                               costChgAmt, occupyCostChgAmt, rlzChgProfit,longShortFlagCode)
                                        VALUES(@temp_mr_createPosiDate, @v_settleDate,@v_shareRecordDate, @v_fundAcctCode, @temp_mr_prodCode,
                                               @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                               @v_secuTradeTypeCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                               -@temp_mc_matchQty, @v_matchNetPrice, @temp_mc_cashCurrSettleAmt, @temp_mc_matchTradeFeeAmt, @v_matchSettleAmt,
                                               @temp_mr_costChgAmt, @temp_mc_cashCurrSettleAmt, @temp_mc_rlzChgProfit,'')

            END
            ELSE 
            BEGIN
  
                  -- �Ҳ�����Ӧ�������¼
              DELETE #tt_prodCreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCode = @v_prodCode AND currencyCode = @v_currencyCode 
                                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                INSERT INTO #tt_prodCheckJrnlES(createPosiDate, settleDate, shareRecordDate, fundAcctCode, prodCode,
                                               exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, 
                                               buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                               matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                               costChgAmt, occupyCostChgAmt, rlzChgProfit,longShortFlagCode)
                                        VALUES(@v_settleDate, @v_settleDate,isnull(@v_shareRecordDate,''), @v_fundAcctCode, @v_prodCode,
                                               @v_exchangeCode, @v_secuCode, '', @v_originSecuCode, @v_secuTradeTypeCode, 
                                               @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                               -@v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                               0, -@v_cashCurrentSettleAmt, -@v_costChgAmt,'')  

              BREAK                                              
              END
          END
        END
      
      ELSE IF (@v_secuBizTypeCode = '183' OR @v_secuBizTypeCode = '187' OR @v_secuBizTypeCode = '188')
        BEGIN
           IF not exists (SELECT * FROM #tt_prodCreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND currencyCode = @v_currencyCode 
                        AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode)
            BEGIN
              INSERT INTO #tt_prodCreatePosiDateSum(exchangeCode, secuCode, prodCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                VALUES(@v_exchangeCode, @v_secuCode, @v_prodCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate)
                --SELECT @v_createPosiDate =   @v_settleDate    
            END
          ELSE  
            BEGIN
              UPDATE #tt_prodCreatePosiDateSum SET createPosiDate = @v_createPosiDate,
                                                posiQty = posiQty + @v_matchQty,
                                                costChgAmt = costChgAmt + CASE WHEN @v_secuBizTypeCode in ('187', '188') AND @v_divCode ='0' THEN 0 ELSE @v_costChgAmt end,
                                                lastestOperateDate = @v_settleDate
                                            WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCode = @v_prodCode AND currencyCode = @v_currencyCode 
                                                  AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
            END
        
          INSERT INTO #tt_prodCheckJrnlES(createPosiDate, settleDate, shareRecordDate, fundAcctCode, prodCode,
                                         exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, longShortFlagCode, 
                                         buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                         matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                         costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                  SELECT @v_createPosiDate, @v_settleDate,@v_shareRecordDate, @v_fundAcctCode, @v_prodCode,
                                         @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                         @v_secuTradeTypeCode, @v_longShortFlagCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                         @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                         CASE WHEN @v_secuBizTypeCode in ('187', '188') AND @v_divCode ='0' THEN 0 ELSE @v_costChgAmt end, 0, @v_rlzChgProfit
                                    --FROM #tt_cellPosiQtySum
        END
      
      FETCH NEXT FROM T_prodRawJrnl INTO @v_serialNO,  @v_orderID, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,
      @v_exchangeCode, @v_secuCode, @v_originSecuCode, @v_secuName, @v_secuTradeTypeCode, 
      @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_currencyCode, @v_hedgeFlagCode, @v_longShortFlagCode, 
      @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, @v_costChgAmt, @v_rlzChgProfit
    END
    CLOSE T_prodRawJrnl
    DEALLOCATE T_prodRawJrnl
    --�����������


    SELECT @v_findRow = COUNT(*) FROM #tt_prodCheckJrnlES


  IF @v_findRow > 0 
    BEGIN
      INSERT INTO sims2016TradeHist.dbo.prodCheckJrnlESHist(createPosiDate, settleDate,
                                      prodCode, fundAcctCode, currencyCode, exchangeCode, secuCode,
                                      originSecuCode, secuTradeTypeCode, marketLevelCode, buySellFlagCode,
                                      bizSubTypeCode, openCloseFlagCode, longShortFlagCode, hedgeFlagCode, secuBizTypeCode, matchQty,
                                      matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, costChgAmt, occupyCostChgAmt,
                                      rlzChgProfit, investCostChgAmt, investOccupyCostChgAmt, investRlzChgProfit)
                               SELECT createPosiDate, settleDate, 
                                      prodCode, fundAcctCode, currencyCode, exchangeCode, secuCode,
                                      originSecuCode, secuTradeTypeCode, marketLevelCode,
                                      buySellFlagCode, 'S1', openCloseFlagCode, '1', hedgeFlagCode, secuBizTypeCode, matchQty,
                                      matchNetPrice, matchSettleAmt, matchTradeFeeAmt, cashSettleAmt, costChgAmt, occupyCostChgAmt,
                                      rlzChgProfit, costChgAmt, occupyCostChgAmt, rlzChgProfit
                                 FROM #tt_prodCheckJrnlES
/*
      INSERT INTO sims2016TradeHist.dbo.prodRawJrnlESHist(settleDate, secuBizTypeCode,
                                    buySellFlagCode, bizSubTypeCode, openCloseFlagCode, hedgeFlagCode, originSecuBizTypeCode, brokerSecuBizTypeCode,
                                    brokerSecuBizTypeName, brokerJrnlSerialID, prodCode, fundAcctCode, currencyCode,
                                    cashSettleAmt, cashBalanceAmt, exchangeCode, secuAcctCode, secuCode, originSecuCode, secuName, secuTradeTypeCode,
                                    matchQty, posiBalanceQty, matchNetPrice, matchSettleAmt,
                                    matchTradeFeeAmt, matchDate, matchTime, matchID, brokerOrderID, brokerOriginOrderID,
                                    brokerErrorMsg, dataSourceFlagCode, assetLiabilityTypeCode, investInstrucNO,
                                    traderInstrucNO, orderNO, marketLevelCode, orderNetAmt, orderNetPrice, orderQty,
                                    orderSettleAmt, orderSettlePrice, orderTradeFeeAmt, directorCode, traderCode, operatorCode,
                                    operateDatetime, operateRemarkText, shareRecordDate
                                    )
                             SELECT settleDate, secuBizTypeCode,
                                    buySellFlagCode, ' ', openCloseFlagCode, hedgeFlagCode, ' ', ' ',
                                    ' ', ' ', prodCode, fundAcctCode, currencyCode,
                                    cashSettleAmt, 0, exchangeCode, ' ', secuCode, originSecuCode, ' ', secuTradeTypeCode, 
                                    matchQty, 0, matchNetPrice, matchSettleAmt,
                                    matchTradeFeeAmt, createPosiDate, ' ',
                                    ' ', ' ', ' ',
                                    ' ', '0', ' ', 0,
                                    0, 0, '2', 0, 0, 0,
                                    0, 0, 0, ' ', ' ', ' ',
                                    GETDATE(), ' ', shareRecordDate
                               FROM #tt_prodCheckJrnlES 
                              WHERE secuBizTypeCode IN('183', '187', '188')
 */
    END   
    
go


--set serveroutput on
--BEGIN
--  opCalcProdCheckJrnlES('9999', '', '', '', '9999-01', '', '', '2017-03-17')
--END
--exec opCalcProdCheckJrnlES '9999','','','','','','','2017-03-01'
--exec opCalcProdCheckJrnlES '9999','','','','','','','2017-03-16'
--exec opCalcProdCheckJrnlES '9999','','','','','','','2017-03-18'

