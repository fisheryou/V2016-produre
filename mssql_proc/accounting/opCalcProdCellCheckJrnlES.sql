USE sims2016Proc
go
IF exists (SELECT 1 FROM sysobjects WHERE name = 'opCalcProdCellCheckJrnlES')
	DROP PROC opCalcProdCellCheckJrnlES
go

CREATE PROC opCalcProdCellCheckJrnlES
  @i_operatorCode        VARCHAR(255),               --����Ա����
  @i_operatorPassword    VARCHAR(255),               --����Ա����
  @i_operateStationText  VARCHAR(4096),              --������Ϣ
  @i_fundAcctCode        VARCHAR(4096),                --�ʽ��˻�
  @i_exchangeCode        VARCHAR(20),                --����������
  @i_secuCode            VARCHAR(20),                --֤ȯ����
  @i_beginDate           VARCHAR(10)                 --��ʼ����
AS
/***************************************************************************
-- Author : yugy
-- Version : 1.0
--    V1.0 �� ֧�ֹ�Ʊ�����ɽ����͹���Ϣ��ת��ת��ҵ��
-- Date : 2017-04-01
-- Description : ��Ʒ��Ԫ��Ʊ���������ɱ��ĺ��㡢�͹���Ϣ����ת�봫������,��Ӧ��ˮ����
-- Function List : opCalcProdCellCheckJrnlES
-- History : 

****************************************************************************/
 SET NOCOUNT ON
 
 CREATE TABLE #tt_prodCellRawJrnl(
    serialNO                  NUMERIC(20,0),                                   --��¼���
    orderID                   NUMERIC(5, 0)     DEFAULT 0      NOT NULL,          --����Id
    occurDate                 VARCHAR(10)                      NOT NULL,          --��������
    shareRecordDate           VARCHAR(10)       DEFAULT ' '    NULL,              --�Ǽ�����
  ----------------------------------------------------------------------------------------------------------------------
    fundAcctCode              VARCHAR(20)                      NOT NULL,        --�ʽ��˻�
    prodCode                  VARCHAR(20)                      NOT NULL,        --��Ʒ����
    prodCellCode              VARCHAR(20)       DEFAULT ' '    NOT NULL,        --��Ʒ��Ԫ����
    investPortfolioCode       VARCHAR(20)       DEFAULT ' '    NOT NULL,        --Ͷ����ϴ���
    transactionNO             NUMERIC(20, 0)    DEFAULT 1      NOT NULL,        --���ױ��
  ----------------------------------------------------------------------------------------------------------------------
    currencyCode              VARCHAR(6)                       NOT NULL,        --���Ҵ���
    marketLevelCode           VARCHAR(1)       DEFAULT '1'     NOT NULL,        --�г���Դ
    exchangeCode              VARCHAR(6)       NOT NULL,                         --����������
    secuCode                  VARCHAR(20)      NOT NULL,                         --֤ȯ����
    originSecuCode            VARCHAR(15)      NOT NULL,                         --ԭʼ֤ȯ����
    secuTradeTypeCode         VARCHAR(20)      NOT NULL,                         --֤ȯ���
  ----------------------------------------------------------------------------------------------------------------------
    secuBizTypeCode           VARCHAR(16)                    NOT NULL,          --ҵ������
    bizSubTypeCode            VARCHAR(16)     DEFAULT 'S1'   NOT NULL,          --ҵ������
    openCloseFlagCode         VARCHAR(16)                    NOT NULL,          --��ƽ��־
    longShortFlagCode         VARCHAR(16)     DEFAULT '1'    NOT NULL,          --��ձ�־
    hedgeFlagCode             VARCHAR(16)     DEFAULT ''     NOT NULL,          --Ͷ����־
    buySellFlagCode           VARCHAR(1)      DEFAULT '1'    NOT NULL,          --�������
------------------------------------------------------------------------------------------------------------------------
    matchQty                  NUMERIC(10,0)     DEFAULT 0      NOT NULL,        --�ɽ�����
    matchNetPrice             NUMERIC(10,2)     DEFAULT 0      NOT NULL,        --�ɽ��۸�
    matchSettleAmt            NUMERIC(19,2)     DEFAULT 0      NOT NULL,        --�ɽ�������
    matchTradeFeeAmt          NUMERIC(19,2)     DEFAULT 0      NOT NULL,        --������
    cashSettleAmt      NUMERIC(19,2)     DEFAULT 0      NOT NULL,        --�ʽ�����
------------------------------------------------------------------------------------------------------------------------
    costChgAmt                NUMERIC(19,2)     DEFAULT 0      NOT NULL,        --�ƶ�ƽ���ɱ��䶯
    rlzChgProfit              NUMERIC(19,2)     DEFAULT 0      NOT NULL         --ʵ��ӯ���䶯
)
 
 CREATE TABLE #tt_prodCellCheckJrnlES
(
  serialNO                  NUMERIC(20, 0),                                  --��¼���
  createPosiDate            VARCHAR(10)                    NOT NULL,         --��������
  occurDate                 VARCHAR(10)                    NOT NULL,         --��������
  shareRecordDate           VARCHAR(10)       DEFAULT ' '      NULL,         --�Ǽ�����
  fundAcctCode              VARCHAR(20)                    NOT NULL,         --�ʽ��˻�
  exchangeCode              VARCHAR(20)                    NOT NULL,        --����������
  secuCode                  VARCHAR(20)                    NOT NULL,        --֤ȯ����
  originSecuCode            VARCHAR(15)                    NOT NULL,         --ԭʼ֤ȯ����
  secuName                  VARCHAR(15)                    NOT NULL,         --֤ȯ����
  secuTradeTypeCode         VARCHAR(20)                    NOT NULL,        --֤ȯ���
  prodCellCode              VARCHAR(20)       DEFAULT ' '  NOT NULL,         --��Ʒ��Ԫ����
  prodCode                  VARCHAR(20)       DEFAULT ' '  NOT NULL,         --��Ʒ����
  investPortfolioCode       VARCHAR(20)       DEFAULT ' '  NOT NULL,         --Ͷ����ϴ���
  buySellFlagCode           VARCHAR(1)                     NOT NULL,         --�������
  openCloseFlagCode         VARCHAR(1)                     NOT NULL,         --��ƽ��־
  secuBizTypeCode           VARCHAR(16)                    NOT NULL,         --ҵ������
  currencyCode              VARCHAR(6)                     NOT NULL,         --���Ҵ���
  marketLevelCode           VARCHAR(1)        DEFAULT '2'  NOT NULL,         --�г���Դ
  hedgeFlagCode             VARCHAR(16)       DEFAULT ''   NOT NULL,         --Ͷ����־
  longShortFlagCode         VARCHAR(16)       DEFAULT '1'  NOT NULL,         --��ձ�־
  matchQty                  NUMERIC(10, 0)    DEFAULT 0    NOT NULL,         --�ɽ�����
  matchNetPrice             NUMERIC(10, 4)    DEFAULT 0    NOT NULL,         --�ɽ��۸�
  cashSettleAmt      NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --�ʽ�����
  matchSettleAmt            NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --�ɽ�������
  matchTradeFeeAmt          NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --������
  costChgAmt                NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --�ƶ�ƽ���ɱ��䶯
  occupyCostChgAmt          NUMERIC(19,2)     DEFAULT 0    NOT NULL,         --�ֲֳɱ��䶯
  rlzChgProfit              NUMERIC(19,2)     DEFAULT 0    NOT NULL          --ʵ��ӯ���䶯
)
 
 CREATE TABLE #tt_cellcreatePosiDate
(
  exchangeCode                  VARCHAR(4)               NOT NULL, --����������
  secuCode                      VARCHAR(30)              NOT NULL, --֤ȯ����
  prodCellCode                  VARCHAR(30)              NOT NULL, --��Ԫ����
  currencyCode                  VARCHAR(6)                     NOT NULL,         --���Ҵ���
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --�г���Դ
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --Ͷ����־
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --��ձ�־
  createPosiDate                VARCHAR(10)              NOT NULL, --��������
  posiQty                       NUMERIC(19,4)            NOT NULL, --�ֲ�����
  costChgAmt                    NUMERIC(19,4)            NOT NULL, --�ɱ��䶯���
  lastestOperateDate            VARCHAR(10)              NOT NULL  --����������
)

CREATE TABLE #tt_cellcreatePosiDateSum
(
  exchangeCode                  VARCHAR(4)               NOT NULL, --����������
  secuCode                      VARCHAR(30)              NOT NULL, --֤ȯ����
  prodCellCode                  VARCHAR(30)              NOT NULL, --��Ԫ����
  currencyCode                  VARCHAR(6)                     NOT NULL,         --���Ҵ���
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --�г���Դ
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --Ͷ����־
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --��ձ�־
  createPosiDate                VARCHAR(10)              NOT NULL, --��������
  posiQty                       NUMERIC(19,4)            NOT NULL, --�ֲ�����
  costChgAmt                    NUMERIC(19,4)                NULL, --�ɱ��䶯���
  lastestOperateDate            VARCHAR(10)              NOT NULL  --����������
)

/*
CREATE TABLE #tt_cellcreatePosiDateSum_rs
(
  exchangeCode                  VARCHAR(4)               NOT NULL, --����������
  secuCode                      VARCHAR(30)              NOT NULL, --֤ȯ����
  originSecuCode                VARCHAR(30)              NOT NULL, --֤ȯ����
  prodCellCode                  VARCHAR(30)              NOT NULL, --��Ԫ����
  currencyCode                  VARCHAR(6)                     NOT NULL,         --���Ҵ���
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --�г���Դ
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --Ͷ����־
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --��ձ�־
  createPosiDate                VARCHAR(10)              NOT NULL, --��������
  posiQty                       NUMERIC(19,4)            NOT NULL, --�ֲ�����
  costChgAmt                    NUMERIC(19,4)             NULL, --�ɱ��䶯���
  lastestOperateDate            VARCHAR(10)              NOT NULL  --����������
)
*/

CREATE TABLE #tt_cellCheckJrnl_old
(
  operateDate                   VARCHAR(10)              NOT NULL, -- ��������
  exchangeCode                  VARCHAR(4)               NOT NULL, -- ����������
  secuCode                      VARCHAR(30)              NOT NULL, -- ֤ȯ����
  prodCellCode                  VARCHAR(30)              NOT NULL, -- ��Ԫ����
  currencyCode                  VARCHAR(6)                     NOT NULL,         --���Ҵ���
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --�г���Դ
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --Ͷ����־
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --��ձ�־
  posiQty                       NUMERIC(19,4)            NOT NULL  -- �ֲ�����
)

CREATE TABLE #tt_cellPosiQtyDetial
(
  createPosiDate                VARCHAR(10)              NOT NULL, --��������
  prodCellCode                  VARCHAR(30)              NOT NULL, --��Ԫ����
  currencyCode                  VARCHAR(6)                     NOT NULL,         --���Ҵ���
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --�г���Դ
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --Ͷ����־
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --��ձ�־
  posiQty                       NUMERIC(19,4)              NOT NULL, --�ֲ�����
  matchQty                      NUMERIC(19,4)              NOT NULL, --�ɽ�����
  costChgAmt                    NUMERIC(19,4)              NOT NULL  --�ɱ��䶯���
)

CREATE TABLE #tt_cellPosiQtySum
(
  createPosiDate                VARCHAR(10)              NOT NULL, --��������
  prodCellCode                  VARCHAR(30)              NOT NULL, --��Ԫ����
  currencyCode                  VARCHAR(6)                     NOT NULL,         --���Ҵ���
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --�г���Դ
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --Ͷ����־
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --��ձ�־
  posiQty                       NUMERIC(19,4)              NOT NULL, --�ֲ�����
  matchQty                      NUMERIC(19,4)              NOT NULL, --�ɽ�����
  costChgAmt                    NUMERIC(19,4)              NOT NULL, --�ɱ��䶯���
  rlzChgProfit                  NUMERIC(19,4)              NOT NULL  --ӯ���䶯���
)

CREATE TABLE #tt_purchaseEntr
(
  occurDate              VARCHAR(10)         not null,
  occurDatetime          DATETIME        not null, 
  exchangeCode           VARCHAR(10)         not null, -- ����������
  secuCode               VARCHAR(20)      not null, --

  fundAcctCode           VARCHAR(30)     not null,
  prodCellCode           VARCHAR(30)     not null,
  currencyCode                  VARCHAR(6)                     NOT NULL,         --���Ҵ���
  marketLevelCode               VARCHAR(1)        DEFAULT '2'  NOT NULL,         --�г���Դ
  hedgeFlagCode                 VARCHAR(16)       DEFAULT ''   NOT NULL,         --Ͷ����־
  longShortFlagCode             VARCHAR(16)       DEFAULT '1'  NOT NULL,         --��ձ�־

  matchQty               DECIMAL(19, 2)  not null,
)

--
DECLARE 
@v_createPosiDate                 VARCHAR(10),           --��������
@v_posiQty                        NUMERIC(19,4),         --�ֲ�����
@v_lastsettleDate                 VARCHAR(10),           --��󽨲�����

@temp_prodCellCode                VARCHAR(20),           --��Ʒ��Ԫ����
@temp_shareRecordDate             VARCHAR(10),           --�Ǽ�����(��ʱ����)
@temp_mc_matchQty                 NUMERIC(10,0),         --�����ɽ�����(��ʱ����)
@temp_mc_per_costChgAmt           NUMERIC(19,8),         --�����ƶ�ƽ���ɱ��䶯(��ʱ����)
@temp_mc_costChgAmt               NUMERIC(19,2),         --�����ƶ�ƽ���ɱ��䶯(��ʱ����)
@temp_mc_per_rlzChgProfit         NUMERIC(19,8),         --����ʵ��ӯ���䶯(��ʱ����)
@temp_mc_rlzChgProfit             NUMERIC(19,2),         --����ʵ��ӯ���䶯(��ʱ����)
@temp_mc_per_cashCurrSettleAmt    NUMERIC(19,8),         --�����ʽ�����(��ʱ����)
@temp_mc_cashCurrSettleAmt        NUMERIC(19,2),         --�����ʽ�����(��ʱ����)
@temp_mc_per_matchTradeFeeAmt     NUMERIC(19,8),         --�������׷���(��ʱ����)
@temp_mc_matchTradeFeeAmt         NUMERIC(19,2),         --�������׷���(��ʱ����)
@temp_mr_prodCellCode             VARCHAR(20),           --�����Ʒ��Ԫ����(��ʱ����)
@temp_mr_secuCode                 VARCHAR(20),           --����֤ȯ����(��ʱ����)
@temp_mr_matchQty                 NUMERIC(10,0),         --����ɽ�����(��ʱ����)
@temp_mr_per_costChgAmt           NUMERIC(19,8),         --�����ƶ�ƽ���ɱ��䶯1(��ʱ����)
@temp_mr_costChgAmt               NUMERIC(19,2),         --�����ƶ�ƽ���ɱ��䶯(��ʱ����)
@temp_mr_createPosiDate           VARCHAR(10),           --���뽨������(��ʱ����)

@v_tempCellCode                  VARCHAR(30),
@v_openQtyUnitValue              NUMERIC(19,4),           --�깺��С��λ
@v_purchaseComAmo                NUMERIC(19,4)           --�깺ί��������
 
--ȡ��ǰ����
 DECLARE @v_today VARCHAR(10), @v_prevArchiveDate VARCHAR(10), --�ϴι鵵����
         @v_lastestOperateDate VARCHAR(10),  @v_divCode  VARCHAR(1)--��Ϣ�Ƿ����ɱ�
 SELECT @v_today = CONVERT(VARCHAR(10), getdate(), 21),@temp_mc_cashCurrSettleAmt =0--Դ���������⣬��ʱ��Ĭ��ֵ

 SELECT @v_prevArchiveDate = CONVERT(VARCHAR(10), prevArchiveDate, 21) FROM sims2016TradeToday..systemCfg
 SELECT @v_divCode = itemValueText FROM sims2016TradeToday..commonCfg WHERE itemCode = '2009' --0 ����ʵ��ӯ���� 1 ����ƶ�ƽ���ɱ�  
 --��ʱ
  IF ISNULL(@v_divCode, '') ='' 
  SELECT @v_divCode = '1'
--����ɱ����㿪ʼ����
 --todo
 DECLARE @v_realBeginDate VARCHAR(10) = @i_beginDate
--�ж��ʽ��˻��Ƿ������� @i_beginDate
 --todo
   BEGIN--ɾ����Ʒ��Ԫ��Ʊ������ˮ
    DELETE sims2016TradeHist..prodCellCheckJrnlESHist
     WHERE settleDate >= @v_realBeginDate
       AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
       AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0);
  END
/*
  BEGIN--ɾ���ǽ�������ˮ
    DELETE sims2016TradeHist..prodCellRawJrnlESHist
     WHERE settleDate >= @v_realBeginDate
       AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
       AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
       AND secuBizTypeCode  IN('183', '187', '188', '122', '123', '124');
  END
 
  BEGIN--ɾ���ǽ�������ˮ
    DELETE sims2016TradeHist..prodCellRawJrnlHist
     WHERE settleDate >= @v_realBeginDate
       AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
       AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
       AND secuBizTypeCode  IN('183', '187', '188', '122', '123', '124');
  END
 */ 
   --ȡ��Ԫ��Ʊ��ʷ�ʽ�֤ȯ��ˮ
    INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,  
                                   fundAcctCode, prodCode, prodCellCode, investPortfolioCode, transactionNO,
                                   currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, longShortFlagCode, hedgeFlagCode, buySellFlagCode, 
                                   matchQty, matchNetPrice, matchSettleAmt, matchTradeFeeAmt,cashSettleAmt, costChgAmt, rlzChgProfit
                                  )
                            SELECT MAX(serialNO), 0, settleDate,       
                                   fundAcctCode, prodCode, prodCellCode, MAX(investPortfolioCode), MAX(transactionNO),
                                   currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode, secuTradeTypeCode,  
                                   secuBizTypeCode, MAX(bizSubTypeCode), openCloseFlagCode, '1', hedgeFlagCode, buySellFlagCode,
                                   SUM(abs(matchQty)), CASE WHEN SUM(matchQty) = 0 THEN 0 ELSE SUM(matchQty*matchNetPrice) / SUM(matchQty) END, SUM(matchSettleAmt), SUM(matchTradeFeeAmt), SUM(cashSettleAmt), SUM(-cashSettleAmt), 0
                              FROM sims2016TradeHist..prodCellRawJrnlESHist a                              
                             WHERE settleDate >= @v_realBeginDate
                               AND settleDate <= @v_today  
                               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                               AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)           
                          GROUP BY settleDate, prodCode, fundAcctCode, prodCellCode, currencyCode, marketLevelCode, exchangeCode, secuCode, originSecuCode,
                                   secuTradeTypeCode, secuBizTypeCode, openCloseFlagCode, hedgeFlagCode, buySellFlagCode
                          ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, a.originSecuCode, prodCellCode, secuBizTypeCode, openCloseFlagCode, MAX(serialNO)

--�¹�
/*
    INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,                         --��¼���, ����������, ҵ��������                                    
                                   shareRecordDate, fundAcctCode, prodCode,              --�ͺ���Ϣ�Ǽ�����, �ʽ��˻�����, ��Ʒ����
                                   prodCellCode, investPortfolioCode, transactionNO,     --��Ʒ��Ԫ����, Ͷ����ϴ���, ���ױ��
                                   currencyCode, marketLevelCode, exchangeCode,          --���Ҵ���, �г���Դ����, ����������
                                   secuCode, originSecuCode, secuTradeTypeCode,          --֤ȯ����, ԭʼ֤ȯ����,֤ȯ�������ʹ��� 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,   --֤ȯҵ��������, ҵ������, ��ƽ��־
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,    --��ձ�־, Ͷ����־, ������־
                                   matchQty, matchNetPrice, matchSettleAmt,              --�ɽ�����, �ɽ��۸�, �ɽ����
                                   matchTradeFeeAmt,cashSettleAmt,               --�ɽ�����, �ʽ�����
                                   costChgAmt, rlzChgProfit                              --�ֲֳɱ����䶯, �ֲ�ʵ��ӯ���䶯
                                  )
                           SELECT serialNO, 0, settleDate,    
                                  shareRecordDate, fundAcctCode, prodCode, 
                                  prodCellCode, investPortfolioCode, transactionNO,
                                  currencyCode, marketLevelCode, exchangeCode, 
                                  secuCode, originSecuCode, secuTradeTypeCode,  
                                  secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, 
                                  '1', hedgeFlagCode, buySellFlagCode,
                                  abs(matchQty), matchNetPrice, matchSettleAmt, 
                                  matchTradeFeeAmt, cashSettleAmt, 
                                  0, 0
                             FROM sims2016TradeHist..prodRawJrnlESHist a
                            WHERE settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today 
                              AND secuBizTypeCode IN ('103', '105', '106', '107') 
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                         ORDER BY fundAcctCode, settleDate
  */ 
  /*                     
                                                    
   --ȡ��Ʒ��Ʊ�͹���Ϣ��ˮ
    INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,                         --��¼���, ����������, ҵ��������                                    
                                   shareRecordDate, fundAcctCode, prodCode,              --�ͺ���Ϣ�Ǽ�����, �ʽ��˻�����, ��Ʒ����
                                   prodCellCode, investPortfolioCode, transactionNO,     --��Ʒ��Ԫ����, Ͷ����ϴ���, ���ױ��
                                   currencyCode, marketLevelCode, exchangeCode,          --���Ҵ���, �г���Դ����, ����������
                                   secuCode, originSecuCode, secuTradeTypeCode,          --֤ȯ����, ԭʼ֤ȯ����,֤ȯ�������ʹ��� 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,   --֤ȯҵ��������, ҵ������, ��ƽ��־
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,    --��ձ�־, Ͷ����־, ������־
                                   matchQty, matchNetPrice, matchSettleAmt,              --�ɽ�����, �ɽ��۸�, �ɽ����
                                   matchTradeFeeAmt,cashSettleAmt,               --�ɽ�����, �ʽ�����
                                   costChgAmt, rlzChgProfit                              --�ֲֳɱ����䶯, �ֲ�ʵ��ӯ���䶯
                                  )
                           SELECT serialNO, 0, settleDate,    
                                  shareRecordDate, fundAcctCode, prodCode, 
                                  prodCellCode, investPortfolioCode, transactionNO,
                                  currencyCode, marketLevelCode, exchangeCode, 
                                  secuCode, originSecuCode, secuTradeTypeCode,  
                                  secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, 
                                  '1', hedgeFlagCode, buySellFlagCode,
                                  abs(matchQty), matchNetPrice, matchSettleAmt, 
                                  matchTradeFeeAmt, cashSettleAmt, 
                                  0, 0
                             FROM sims2016TradeHist..prodRawJrnlESHist a
                            WHERE settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today 
                              AND shareRecordDate != ' '
                              AND secuBizTypeCode IN ('183', '187', '188', '122') 
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                         ORDER BY fundAcctCode, settleDate
                          
   --ȡ��ɽɿ��Ϊ��Ҫ��ֳ�2����
    INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,                         --��¼���, ����������, ҵ��������                                    
                                   shareRecordDate, fundAcctCode, prodCode,              --�ͺ���Ϣ�Ǽ�����, �ʽ��˻�����, ��Ʒ����
                                   prodCellCode, investPortfolioCode, transactionNO,     --��Ʒ��Ԫ����, Ͷ����ϴ���, ���ױ��
                                   currencyCode, marketLevelCode, exchangeCode,          --���Ҵ���, �г���Դ����, ����������
                                   secuCode, originSecuCode, secuTradeTypeCode,          --֤ȯ����, ԭʼ֤ȯ����,֤ȯ�������ʹ��� 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,   --֤ȯҵ��������, ҵ������, ��ƽ��־
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,    --��ձ�־, Ͷ����־, ������־
                                   matchQty, matchNetPrice, matchSettleAmt,              --�ɽ�����, �ɽ��۸�, �ɽ����
                                   matchTradeFeeAmt,cashSettleAmt,               --�ɽ�����, �ʽ�����
                                   costChgAmt, rlzChgProfit                              --�ֲֳɱ����䶯, �ֲ�ʵ��ӯ���䶯
                                  )
                           SELECT MAX(a.serialNO), 0, settleDate,    
                                  MAX(shareRecordDate), fundAcctCode, prodCode, 
                                  prodCellCode, '' AS investPortfolioCode, MAX(transactionNO),
                                  currencyCode, MAX(marketLevelCode), exchangeCode, 
                                  secuCode, originSecuCode, secuTradeTypeCode,  
                                  secuBizTypeCode, MAX(bizSubTypeCode), MAX(openCloseFlagCode), 
                                  '1', MAX(hedgeFlagCode), buySellFlagCode,
                                  SUM(abs(matchQty)),  case when SUM(matchQty) = 0 THEN 0 ELSE SUM(matchQty*matchNetPrice) / SUM(matchQty) END AS matchNetPrice, SUM(-matchSettleAmt), 
                                  0 AS matchTradeFeeAmt, SUM(cashSettleAmt), 
                                  0, 0
                             FROM sims2016TradeHist..prodRawJrnlESHist a
                            WHERE settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today 
                              AND secuBizTypeCode IN ('123') 
                              AND matchQty > 0
                              AND secuCode != ''
                              AND exchangeCode != ''
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
				                 GROUP BY settleDate, prodCellCode, currencyCode, a.fundAcctCode, a.prodCode, secuTradeTypeCode, buySellFlagCode, exchangeCode, secuCode, originSecuCode, secuBizTypeCode
                         ORDER BY a.fundAcctCode, a.prodCode, settleDate, exchangeCode, a.secuCode, a.originSecuCode, prodCellCode, secuTradeTypeCode, buySellFlagCode, MAX(a.serialNO)
 
     ---------------------------------- �ǽ��׹������������
         INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,                         --��¼���, ����������, ҵ��������                                    
                                   shareRecordDate, fundAcctCode, prodCode,              --�ͺ���Ϣ�Ǽ�����, �ʽ��˻�����, ��Ʒ����
                                   prodCellCode, investPortfolioCode, transactionNO,     --��Ʒ��Ԫ����, Ͷ����ϴ���, ���ױ��
                                   currencyCode, marketLevelCode, exchangeCode,          --���Ҵ���, �г���Դ����, ����������
                                   secuCode, originSecuCode, secuTradeTypeCode,          --֤ȯ����, ԭʼ֤ȯ����,֤ȯ�������ʹ��� 
                                   secuBizTypeCode, bizSubTypeCode, openCloseFlagCode,   --֤ȯҵ��������, ҵ������, ��ƽ��־
                                   longShortFlagCode, hedgeFlagCode, buySellFlagCode,    --��ձ�־, Ͷ����־, ������־
                                   matchQty, matchNetPrice, matchSettleAmt,              --�ɽ�����, �ɽ��۸�, �ɽ����
                                   matchTradeFeeAmt,cashSettleAmt,               --�ɽ�����, �ʽ�����
                                   costChgAmt, rlzChgProfit                              --�ֲֳɱ����䶯, �ֲ�ʵ��ӯ���䶯
                                  )
                           SELECT serialNO, 0, settleDate,    
                                  '' AS shareRecordDate, fundAcctCode, prodCode, 
                                  prodCellCode, investPortfolioCode, transactionNO,
                                  currencyCode, marketLevelCode, exchangeCode, 
                                  secuCode, originSecuCode, secuTradeTypeCode,  
                                  secuBizTypeCode, bizSubTypeCode, openCloseFlagCode, 
                                  '1', hedgeFlagCode, buySellFlagCode,
                                  matchQty, matchNetPrice, matchSettleAmt, 
                                  matchTradeFeeAmt, cashSettleAmt, 
                                  0, 0
                             FROM sims2016TradeHist..prodRawJrnlESHist a
                            WHERE settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today 
                              AND secuBizTypeCode IN ('124') 
                              AND matchQty > 0
									           -- AND (cashSettleAmt != 0 or cjje != 0 or sjly != '0')
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                         ORDER BY fundAcctCode, settleDate
        */             
   --ȡ��Ԫ֤ȯ�ֲ�ת����ˮ(8101)
                             INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,  
                                   fundAcctCode, prodCode, prodCellCode, 
                                   investPortfolioCode, transactionNO, currencyCode, 
                                   marketLevelCode, exchangeCode, secuCode, 
                                   originSecuCode, secuTradeTypeCode, secuBizTypeCode, 
                                   bizSubTypeCode, openCloseFlagCode, longShortFlagCode,
                                   hedgeFlagCode, buySellFlagCode, matchQty, 
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, costChgAmt, rlzChgProfit
                                  )      
                            SELECT serialNO, 0, settleDate,       
                                   fundAcctCode, prodCode, prodCellCode, 
                                   investPortfolioCode, transactionNO, currencyCode, 
                                   marketLevelCode, exchangeCode, secuCode, 
                                   ' ', secuTradeTypeCode, secuBizTypeCode, 
                                   'S1', '1', '1', 
                                   hedgeFlagCode, '1', abs(matchQty), 
                                   CASE WHEN matchQty = 0 THEN 0 ELSE investCostAmt / matchQty END, 0, 0, 
                                   0, investCostAmt, 0
                              FROM sims2016TradeHist..prodCellInOutESHist a
                             WHERE secuBizTypeCode = '8101'
                               AND settleDate >= @v_realBeginDate
                               AND settleDate <= @v_today                   
                               AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                               AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                               AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                          ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, secuBizTypeCode
                          
                          
       --ȡ��Ԫ֤ȯ�ֲ�ת����ˮ(8103)                   
        INSERT INTO #tt_prodCellRawJrnl(serialNO, orderID, occurDate,  
                                   fundAcctCode, prodCode, prodCellCode, 
                                   investPortfolioCode, transactionNO, currencyCode, 
                                   marketLevelCode, exchangeCode, secuCode, 
                                   originSecuCode, secuTradeTypeCode, secuBizTypeCode, 
                                   bizSubTypeCode, openCloseFlagCode, longShortFlagCode, 
                                   hedgeFlagCode, buySellFlagCode, matchQty, 
                                   matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                   cashSettleAmt, costChgAmt, rlzChgProfit
                                  )   
                           SELECT serialNO, 0, settleDate,       
                                  fundAcctCode, prodCode, prodCellCode,
                                  investPortfolioCode, transactionNO, currencyCode, 
                                  marketLevelCode, exchangeCode, secuCode, 
                                  ' ', secuTradeTypeCode, secuBizTypeCode,
                                  'S1', 'A', '1', 
                                  hedgeFlagCode, '1', abs(matchQty), 
                                  CASE WHEN matchQty = 0 THEN 0 ELSE investCostAmt / matchQty END, 0, 0,
                                  0, investCostAmt, 0
                             FROM sims2016TradeHist..prodCellInOutESHist a
                            WHERE secuBizTypeCode = '8103'
                              AND settleDate >= @v_realBeginDate
                              AND settleDate <= @v_today                   
                              AND (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+a.originSecuCode+',', @i_secuCode) > 0)
                         ORDER BY fundAcctCode, settleDate, exchangeCode, a.secuCode, prodCellCode, secuBizTypeCode                                   
 
  --�¹��깺ί��ͳ��
  --insert #tt_purchaseEntr(occurDate, occurDatetime, exchangeCode, secuCode, fundAcctCode, prodCellCode, matchQty) 
		--		   select tradeDate, tradeTime, exchangeCode, secuCode fundAcctCode, prodCellCode, orderQty
  --       from utrm30drsj..prev_wtb_dr_jyzh a inner join #nbzjzh d on a.nbzjzh = d.nbzjzh
  --       where (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
  --       AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
  --       AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
         --AND secuBizTypeCode IN ('103', '105', '106', '107')
  --       --AND jylx = 'SG' 
  --      ORDER BY fundAcctCode, tradeDate, exchangeCode, a.secuCode, prodCellCode,
  
  /*     
  insert #tt_purchaseEntr(occurDate, occurDatetime, exchangeCode, secuCode, fundAcctCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, matchQty) 
				   select tradeDate, tradeTime, exchangeCode, secuCode, fundAcctCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, orderQty
         from sims2016TradeHist..prodCellOrderESHist a 
         where (@i_fundAcctCode = '' OR CHARINDEX(fundAcctCode, @i_fundAcctCode) > 0)
         AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
         AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
         AND secuBizTypeCode IN ('103', '105', '106', '107')
        ORDER BY fundAcctCode, tradeDate, exchangeCode, a.secuCode, prodCellCode
  */     
 --��������
  DECLARE @o_fundAcctCode VARCHAR(20)
  SELECT @o_fundAcctCode = null
 
--�α����BEGIN
DECLARE
@v_serialNO                 NUMERIC(20,0),                   --��¼���
@v_orderID                  NUMERIC(5, 0),                   --����Id
@v_settleDate               VARCHAR(10),                     --��������
@v_shareRecordDate          VARCHAR(10),                     --�Ǽ�����
@v_fundAcctCode             VARCHAR(20),                     --�ʽ��˻�
@v_exchangeCode             VARCHAR(6),                      --����������
@v_secuCode                 VARCHAR(6),                      --֤ȯ����
@v_originSecuCode           VARCHAR(15),                     --ԭʼ֤ȯ����
@v_secuName                 VARCHAR(64),                     --֤ȯ����
@v_secuTradeTypeCode        VARCHAR(5),                      --֤ȯ���
@v_prodCellCode             VARCHAR(20),                     --��Ʒ��Ԫ����
@v_prodCode                 VARCHAR(20),                     --��Ʒ����
@v_investPortfolioCode      VARCHAR(20),                     --Ͷ����ϴ���
@v_buySellFlagCode          VARCHAR(1),                      --�������
@v_openCloseFlagCode        VARCHAR(16),                     --��ƽ��־
@v_marketLevelCode          VARCHAR(1),                      --�г���Դ
@v_currencyCode             VARCHAR(6),                      --���Ҵ���
@v_hedgeFlagCode            VARCHAR(16),                     --Ͷ����־
@v_longShortFlagCode        VARCHAR(16),                     --��ձ�־
@v_secuBizTypeCode          VARCHAR(16),                     --ҵ������
@v_matchQty                 NUMERIC(10,0),                   --�ɽ�����
@v_matchNetPrice            NUMERIC(10,2),                   --�ɽ��۸�
@v_cashCurrentSettleAmt     NUMERIC(19,2),                   --�ʽ�����
@v_matchTradeFeeAmt         NUMERIC(19,2),                   --������
@v_matchSettleAmt           NUMERIC(19,2),                   --�ɽ�������
@v_costChgAmt               NUMERIC(19,2),                   --�ƶ�ƽ���ɱ��䶯
@v_rlzChgProfit             NUMERIC(19,2)                    --ʵ��ӯ���䶯
--�α����END

 DECLARE for_mccjb CURSOR FOR SELECT serialNO, orderID, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                          exchangeCode, secuCode, originSecuCode, '', secuTradeTypeCode, longShortFlagCode,
                          prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, currencyCode, hedgeFlagCode, 
                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                          costChgAmt, rlzChgProfit
                     FROM #tt_prodCellRawJrnl 
                 ORDER BY fundAcctCode, exchangeCode, secuCode, occurDate, orderID, buySellFlagCode DESC, serialNO
  OPEN for_mccjb
  FETCH for_mccjb INTO @v_serialNO, @v_orderID, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode, 
                       @v_exchangeCode, @v_secuCode, @v_originSecuCode,@v_secuName, @v_secuTradeTypeCode, @v_longShortFlagCode,
                       @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_currencyCode, @v_hedgeFlagCode, 
                       @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                       @v_costChgAmt, @v_rlzChgProfit
                       
   WHILE 1 = 1
    BEGIN
    IF @o_fundAcctCode IS NOT NULL AND (@o_fundAcctCode != @v_fundAcctCode or @@FETCH_STATUS != 0)  
       BEGIN
          INSERT INTO sims2016TradeHist..prodCellCheckJrnlESHist( createPosiDate, settleDate,
                                              prodCode, prodCellCode, fundAcctCode,
                                              currencyCode, exchangeCode, secuCode,
                                              originSecuCode, secuTradeTypeCode, marketLevelCode,
                                              transactionNO, investPortfolioCode, buySellFlagCode,
                                              bizSubTypeCode, openCloseFlagCode, longShortFlagCode,
                                              hedgeFlagCode, secuBizTypeCode, matchQty,
                                              matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                              cashSettleAmt, costChgAmt, occupyCostChgAmt,
                                              rlzChgProfit, investCostChgAmt,
                                              investOccupyCostChgAmt, investRlzChgProfit   
                                             )
                                       SELECT createPosiDate, occurDate, 
                                              prodCode, prodCellCode, fundAcctCode, 
                                              currencyCode, exchangeCode, secuCode,
                                              originSecuCode, secuTradeTypeCode, marketLevelCode,
                                              1, investPortfolioCode, buySellFlagCode,
                                              'S1', openCloseFlagCode, longShortFlagCode,
                                              hedgeFlagCode, secuBizTypeCode, matchQty,
                                              matchNetPrice, matchSettleAmt, matchTradeFeeAmt,
                                              cashSettleAmt, costChgAmt, occupyCostChgAmt,
                                              rlzChgProfit, costChgAmt,
                                              occupyCostChgAmt, rlzChgProfit                                                
                                         FROM #tt_prodCellCheckJrnlES
                                         
     /*                                    
          INSERT INTO sims2016TradeHist..prodCellRawJrnlHist( 
																															originSerialNO,
																															settleDate,
																															secuBizTypeCode,
																															buySellFlagCode,
																															bizSubTypeCode,
																															openCloseFlagCode,
																															hedgeFlagCode,
																															coveredFlagCode,
																															originSecuBizTypeCode,
																															brokerSecuBizTypeCode,
																															brokerSecuBizTypeName,
																															brokerJrnlSerialID,
																															prodCode,
																															prodCellCode,
																															fundAcctCode,
																															currencyCode,
																															cashSettleAmt,
																															cashBalanceAmt,
																															exchangeCode,
																															secuAcctCode,
																															secuCode,
																															originSecuCode,
																															secuName,
																															secuTradeTypeCode,
																															matchQty,
																															posiBalanceQty,
																															matchNetPrice,
																															dataSourceFlagCode,
																															marketLevelCode,
																															operatorCode,
																															operateDatetime,
																															operateRemarkText   )
																						           SELECT 
																															0,
																															occurDate,
																															secuBizTypeCode,
																															buySellFlagCode,
																															'S1',
																															openCloseFlagCode,
																															hedgeFlagCode,
																															' ',
																															' ',
																															' ',
																															' ',
																															' ',
																															prodCode,
																															prodCellCode,
																															fundAcctCode,
																															currencyCode,
																															cashSettleAmt,
																															0,
																															exchangeCode,
																															' ',
																															secuCode,
																															originSecuCode,
																															secuName,
																															secuTradeTypeCode,
																															matchQty,
																															0,
																															matchNetPrice,
																															0,
																															marketLevelCode,
																															' ',
																															GETDATE(),
																															' ' 
                                       FROM #tt_prodCellCheckJrnlES 
                                      WHERE secuBizTypeCode IN('183', '187', '188', '122', '123', '124')                                
                                    
                                         
          INSERT INTO sims2016TradeHist..prodCellRawJrnlESHist(serialNO,  settleDate, secuBizTypeCode,
                                            buySellFlagCode, bizSubTypeCode, openCloseFlagCode,
                                            hedgeFlagCode, originSecuBizTypeCode, brokerSecuBizTypeCode,
                                            brokerSecuBizTypeName, brokerJrnlSerialID, prodCode,
                                            prodCellCode, fundAcctCode, currencyCode,
                                            cashSettleAmt, cashBalanceAmt, exchangeCode,
                                            secuAcctCode, secuCode, originSecuCode,
                                            secuName, secuTradeTypeCode, matchQty,
                                            posiBalanceQty, matchNetPrice, matchSettleAmt,
                                            matchTradeFeeAmt, matchDate, matchTime,
                                            matchID, brokerOrderID, brokerOriginOrderID,
                                            brokerErrorMsg, dataSourceFlagCode, transactionNO,
                                            investPortfolioCode, assetLiabilityTypeCode, investInstrucNO,
                                            traderInstrucNO, orderNO, marketLevelCode,
                                            orderNetAmt, orderNetPrice, orderQty,
                                            orderSettleAmt, orderSettlePrice, orderTradeFeeAmt,
                                            directorCode, traderCode, operatorCode,
                                            operateDatetime, operateRemarkText, shareRecordDate
                                           )
                                     SELECT bb.serialNO, occurDate, aa.secuBizTypeCode,
                                            aa.buySellFlagCode, ' ', aa.openCloseFlagCode,
                                            aa.hedgeFlagCode, ' ', ' ',
                                            ' ', ' ', aa.prodCode,
                                            aa.prodCellCode, aa.fundAcctCode, aa.currencyCode,
                                            aa.cashSettleAmt, 0, aa.exchangeCode,
                                            ' ', aa.secuCode, aa.originSecuCode,
                                            ' ', aa.secuTradeTypeCode, aa.matchQty,
                                            0, aa.matchNetPrice, matchSettleAmt,
                                            matchTradeFeeAmt, createPosiDate, ' ',
                                            ' ', ' ', ' ',
                                            ' ', '0', 1,
                                            investPortfolioCode, ' ', 0,
                                            0, 0, '2',
                                            0, 0, 0,
                                            0, 0, 0,
                                            ' ', ' ', ' ',
                                            GETDATE(), ' ', shareRecordDate
                                       FROM #tt_prodCellCheckJrnlES aa inner join sims2016TradeHist..prodCellRawJrnlHist bb
																				    ON (aa.occurDate = bb.settleDate AND  aa.prodCellCode =  bb.prodCellCode AND aa.exchangeCode = bb.exchangeCode AND aa.secuCode = bb.secuCode
																				        AND aa.secuBizTypeCode = bb.secuBizTypeCode)                                       
                                      WHERE aa.secuBizTypeCode IN('183', '187', '188', '122', '123', '124');
                    */                  
          TRUNCATE TABLE #tt_prodCellCheckJrnlES
        END
        
     IF @@FETCH_STATUS != 0
        BREAK
    --beign ��ʼ�˻������˻��л�
    IF @o_fundAcctCode IS NULL OR @o_fundAcctCode != @v_fundAcctCode
    BEGIN
     SELECT @o_fundAcctCode = @v_fundAcctCode
     
     TRUNCATE TABLE #tt_cellcreatePosiDate
     TRUNCATE TABLE #tt_cellcreatePosiDateSum
     
     --ȡ���ձ�(TODO)
     --ȡ��ʷ������ˮ��

     
            INSERT INTO #tt_cellcreatePosiDate(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                        SELECT exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode,MAX(createPosiDate), SUM(matchQty), SUM(costChgAmt), MAX(settleDate)
                                          FROM sims2016TradeHist..prodCellCheckJrnlESHist
                                          WHERE fundAcctCode = @v_fundAcctCode  
                                                AND settleDate < @v_realBeginDate -- AND settleDate > �������� (���������ձ���ƺú���ϴ�����) 
                                                AND (@i_exchangeCode = '' or CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                                AND (@i_secuCode = '' OR CHARINDEX(secuCode, @i_secuCode) > 0)
                                          GROUP BY prodCellCode, exchangeCode, secuCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode
                                                                    
             INSERT INTO #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                          SELECT exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode,MAX(createPosiDate),SUM(posiQty), SUM(costChgAmt), MAX(lastestOperateDate)
                                            FROM #tt_cellcreatePosiDate
                                            GROUP BY exchangeCode, secuCode, prodCellCode, createPosiDate, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode
                                            HAVING SUM(posiQty) > 0;                                          
                          
            TRUNCATE TABLE #tt_cellCheckJrnl_old
            
            SELECT @temp_shareRecordDate = shareRecordDate FROM #tt_prodCellRawJrnl WHERE fundAcctCode = @v_fundAcctCode AND shareRecordDate != ''
            
            SELECT @temp_shareRecordDate = ISNULL(@temp_shareRecordDate, '')
            
            INSERT INTO #tt_cellCheckJrnl_old(operateDate, exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty)
                                      SELECT settleDate, exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(matchQty)
                                        FROM sims2016TradeHist..prodCellCheckJrnlESHist
                                        WHERE settleDate < @v_realBeginDate -- AND settleDate > �������� (���������ձ���ƺú���ϴ�����)
                                              AND fundAcctCode = @v_fundAcctCode
                                              AND (@i_exchangeCode = '' OR CHARINDEX(exchangeCode, @i_exchangeCode) > 0)
                                              AND (@i_secuCode  = '' OR CHARINDEX(secuCode, @i_secuCode) > 0 OR CHARINDEX(','+originSecuCode+',', @i_secuCode) > 0)
                                        GROUP BY settleDate, exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode
                                        HAVING SUM(matchQty) != 0;
  
    END
    --END ��ʼ�˻������˻��л�
    
    IF @v_exchangeCode = '' AND @v_secuCode = ''
    BEGIN
			TRUNCATE TABLE #tt_cellcreatePosiDateSum
		END
		ELSE IF @v_secuBizTypeCode in ('122','123', '1231', '1232', '124', '1241', '1242', '103', '106', '105', '107', '1071', '1072')
		BEGIN
      INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                  exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                  prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                  matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                  costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                    SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,@v_investPortfolioCode,
                           @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                           @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                           @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                           @v_costChgAmt, 0, @v_rlzChgProfit
                           
       IF  @v_secuBizTypeCode IN ('122', '1242', '103','106', '1072') 
       BEGIN                  
         IF not exists (SELECT * FROM #tt_cellcreatePosiDateSum 
                        WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                        AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode)
           INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                           SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
         ELSE
           BEGIN
            UPDATE #tt_cellcreatePosiDateSum 
              SET createPosiDate = CASE WHEN @v_secuBizTypeCode != '122' THEN @v_createPosiDate ELSE createPosiDate END,
                  posiQty = posiQty + @v_posiQty , 
                  costChgAmt = costChgAmt + CASE WHEN @v_secuBizTypeCode != '122' THEN @v_costChgAmt ELSE 0 END, 
                  lastestOperateDate = CASE WHEN @v_secuBizTypeCode != '122' THEN @v_lastestOperateDate ELSE lastestOperateDate END
            WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                  AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  
           END  
        END
       ELSE IF @v_secuBizTypeCode IN ('1241', '105', '1071') 
       BEGIN
         UPDATE #tt_cellcreatePosiDateSum 
           SET posiQty = posiQty - @v_posiQty, 
               costChgAmt = costChgAmt - @v_costChgAmt, 
               lastestOperateDate = @v_lastestOperateDate
         WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
               AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
       END                                               
		END
        /*		
		ELSE IF @v_secuBizTypeCode = '122'  --SPGDJ  ����ɵǼ�
			BEGIN
				--TRUNCATE TABLE #tt_cellPosiQtyDetial
    --    TRUNCATE TABLE #tt_cellPosiQtySum
        
        IF @v_shareRecordDate < @v_prevArchiveDate
          SELECT @v_shareRecordDate = @v_prevArchiveDate

          INSERT #tt_cellPosiQtyDetial (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
                          SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(posiQty), 0, 0
                                 FROM #tt_cellCheckJrnl_old
                                 WHERE operateDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_originSecuCode 
                                 GROUP BY prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode                                
                                 HAVING SUM(posiQty) > 0

          INSERT #tt_cellPosiQtyDetial (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
                          SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(matchQty), 0, 0
                                 FROM #tt_prodCellCheckJrnlES
                                 WHERE occurDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_originSecuCode 
                                 GROUP BY prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode                                 
                                 HAVING SUM(matchQty) != 0

          INSERT #tt_cellPosiQtySum (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                          SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(posiQty), 0, 0, 0
                                 FROM #tt_cellPosiQtyDetial
                                 GROUP BY prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode                                 
                                 HAVING SUM(posiQty) > 0

          IF exists (SELECT * FROM #tt_cellPosiQtySum)
            BEGIN
              SELECT @v_openQtyUnitValue = openQtyUnitValue FROM sims2016TradeToday..secuTable WHERE secuCode = @v_secuCode
              SELECT @v_openQtyUnitValue = ISNULL(@v_openQtyUnitValue, 1)

              SELECT @v_posiQty = SUM(posiQty) FROM #tt_cellPosiQtySum    

              UPDATE #tt_cellPosiQtySum SET matchQty = FLOOR(ROUND(posiQty * @v_matchQty / CONVERT(FLOAT, @v_posiQty), 4) / @v_openQtyUnitValue) * @v_openQtyUnitValue

              SELECT @v_matchQty = @v_matchQty - SUM(matchQty) FROM #tt_cellPosiQtySum

              IF @v_matchQty != 0 or @v_costChgAmt != 0 or @v_rlzChgProfit != 0 -- β��
                BEGIN
                  SET rowcount 1
                  SELECT @temp_prodCellCode = prodCellCode FROM #tt_cellPosiQtySum ORDER BY posiQty desc
                  UPDATE #tt_cellPosiQtySum SET matchQty = matchQty + @v_matchQty WHERE prodCellCode = @temp_prodCellCode
                  SET rowcount 0
                END

              IF not exists (SELECT * FROM #tt_cellcreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode)
                INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                 SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
              ELSE
                BEGIN
                  UPDATE #tt_cellcreatePosiDateSum SET posiQty = posiQty + @v_matchQty
                                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                END
            END
          ELSE-- δ�ҵ����ɳֲ�
            BEGIN
              IF not exists (SELECT * FROM #tt_cellcreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode)
                BEGIN
                  INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                 SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
                END
              ELSE
                BEGIN
                  UPDATE #tt_cellcreatePosiDateSum SET posiQty = posiQty + @v_matchQty
                                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode
                END
  
              INSERT #tt_cellPosiQtySum (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                              SELECT @v_settleDate, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, 0, @v_matchQty, 0, 0
            END

          INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                          exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                          prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                          costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                            SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                                   @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                                   prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                                   matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                   0, 0, 0     
                                   --FROM #tt_cellPosiQtySum      

          -- ���»������ӳֲ�
          UPDATE a SET posiQty = a.posiQty + b.matchQty
                   FROM #tt_cellcreatePosiDateSum_rs a 
                   inner join #tt_cellPosiQtySum b ON a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode AND a.originSecuCode = @v_originSecuCode AND a.prodCellCode = b.prodCellCode          
 
          INSERT #tt_cellcreatePosiDateSum_rs (exchangeCode, secuCode, originSecuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                               SELECT exchangeCode, secuCode, originSecuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate
                                       FROM (SELECT @v_exchangeCode AS exchangeCode, @v_secuCode AS secuCode, @v_originSecuCode AS originSecuCode, a.prodCellCode, @v_currencyCode AS currencyCode, 
                                                    @v_marketLevelCode AS marketLevelCode,@v_hedgeFlagCode AS hedgeFlagCode,@v_longShortFlagCode AS longShortFlagCode, @v_settleDate AS createPosiDate, a.matchQty AS posiQty, 0 AS costChgAmt, 
                                                    @v_settleDate AS lastestOperateDate, b.createPosiDate AS createPosiDate_y
                                                    FROM #tt_cellPosiQtySum a 
                                                    left join #tt_cellcreatePosiDateSum_rs b ON a.prodCellCode = b.prodCellCode AND b.exchangeCode = @v_exchangeCode AND b.secuCode = @v_secuCode AND b.originSecuCode = @v_originSecuCode 
                                                    AND b.currencyCode = @v_currencyCode AND b.marketLevelCode = @v_marketLevelCode AND b.hedgeFlagCode = @v_hedgeFlagCode AND b.longShortFlagCode = @v_longShortFlagCode
                                           )x
                                            WHERE x.createPosiDate_y is null				

			END	
		ELSE IF @v_secuBizTypeCode in ('123') --PGJK ��ɽɿ�
      BEGIN
          -- ���Ȩ֤�ֲּ��� PGJKQZJS   1231
          SELECT @v_createPosiDate = null
          SELECT @v_createPosiDate = createPosiDate 
          FROM #tt_cellcreatePosiDateSum_rs 
          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND originSecuCode = @v_originSecuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode          

          IF @v_createPosiDate is not null
            BEGIN              
              UPDATE #tt_cellcreatePosiDateSum_rs SET posiQty = posiQty - @v_matchQty
                     WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND originSecuCode = @v_originSecuCode AND prodCellCode = @v_prodCellCode 
                           AND currencyCode = @v_currencyCode AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  

          INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                          exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                          prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                          costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                            SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                                   @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                                   @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, '1231' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                                    -1 * @v_matchQty, 0, 0, 0, 0,
                                   0, 0, 0     
            END

          --��ɣ�����δ���У��ֲ�����
          SELECT @v_createPosiDate = null
          SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate FROM #tt_cellcreatePosiDateSum_rs
                 WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_originSecuCode AND originSecuCode = @v_originSecuCode AND prodCellCode = @v_prodCellCode
          IF @v_createPosiDate is null
            BEGIN
              INSERT #tt_cellcreatePosiDateSum_rs (exchangeCode, secuCode, originSecuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                  SELECT @v_exchangeCode, @v_originSecuCode, @v_originSecuCode, @v_prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate
              SELECT @v_createPosiDate = @v_settleDate
            END
          ELSE
            BEGIN
              UPDATE #tt_cellcreatePosiDateSum_rs SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + @v_costChgAmt, lastestOperateDate = @v_settleDate
                     WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_originSecuCode AND originSecuCode = @v_originSecuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
            END
            -- ���Ȩ֤�ֲ����� PGJKQZZJ   1232

          INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                          exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                          prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                          matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                          costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                            SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                                   @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                                   @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, '1232' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                                   @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                  ROUND(@v_costChgAmt, 2), 0, ROUND(@v_rlzChgProfit, 2) 
        END   

    ELSE IF(@v_secuBizTypeCode = '124')      --PGSS ������С�
      BEGIN
          --�ҵ���ɽɿ�ĳֲ� �Լ����е�Ԫ��Ȼ�󰴽ɿ�ֲֽ��в�֡�            
          WHILE @v_matchQty > 0
            BEGIN
              SELECT @temp_mr_prodCellCode = null
              SELECT TOP 1 
                     @temp_mr_prodCellCode = prodCellCode,
                     @temp_mr_secuCode = secuCode,
                     @temp_mr_matchQty = abs(posiQty),                                
                     @temp_mr_costChgAmt = costChgAmt,
                     @temp_mr_per_costChgAmt = costChgAmt / abs(posiQty), 
                     @temp_mr_createPosiDate = createPosiDate 
                     FROM #tt_cellcreatePosiDateSum_rs
                     WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND originSecuCode = @v_secuCode AND abs(posiQty) > 0 AND currencyCode = @v_currencyCode 
                           AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                     ORDER BY createPosiDate, prodCellCode

              IF @temp_mr_prodCellCode is not null
                BEGIN

                  IF @v_matchQty < @temp_mr_matchQty
                    SELECT @temp_mc_matchQty = @v_matchQty
                  ELSE
                    SELECT @temp_mc_matchQty = @temp_mr_matchQty

                  SELECT @v_matchQty = @v_matchQty - @temp_mc_matchQty

                  IF @temp_mc_matchQty < @temp_mr_matchQty
                    BEGIN
                      SELECT @temp_mc_costChgAmt = ROUND(@temp_mc_matchQty * @temp_mr_per_costChgAmt, 2)                                    
                    END
                  ELSE
                    BEGIN
                      SELECT @temp_mc_costChgAmt = @temp_mr_costChgAmt             
                    END

                  IF @temp_mc_matchQty != @temp_mr_matchQty
                    SELECT @temp_mr_costChgAmt = ROUND(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)

                  SELECT @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt

                  SELECT @v_costChgAmt = ISNULL(@v_costChgAmt,0) - ISNULL(@temp_mc_costChgAmt,0)

                  SELECT @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt

                  UPDATE #tt_cellcreatePosiDateSum_rs SET posiQty = posiQty - @temp_mc_matchQty, 
                                              costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestOperateDate = @v_settleDate
                                              WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND originSecuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode
                                                    AND currencyCode = @v_currencyCode AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                   --�������ת����¼ '1241','��Ʊ�������ת��' PGSSZC
                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @temp_mr_createPosiDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'S' AS buySellFlagCode, @v_openCloseFlagCode, '1241' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          -1 * @temp_mc_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          -1 * @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
            
                   SELECT @v_createPosiDate = null
                   SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate FROM #tt_cellcreatePosiDateSum
                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   IF @v_createPosiDate is null
                      BEGIN
                        INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                          SELECT @v_exchangeCode, @v_secuCode, @v_prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @temp_mc_matchQty, @temp_mr_costChgAmt, @v_settleDate
                        SELECT @v_createPosiDate = @v_settleDate
                      END                 
                    ELSE
                      BEGIN
                        UPDATE #tt_cellcreatePosiDateSum SET createPosiDate = @v_createPosiDate, posiQty = posiQty + @temp_mc_matchQty, costChgAmt = costChgAmt + @temp_mr_costChgAmt, lastestOperateDate = @v_settleDate
                               WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      END
                --'1242','��Ʊ�������ת��'   PGSSZR    
                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, '1242' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @temp_mc_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
                END
              ELSE -- �Ҳ�����Ӧ����ɼ�¼
                BEGIN
                   SELECT @v_createPosiDate = null
                   SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate FROM #tt_cellcreatePosiDateSum
                          WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   IF @v_createPosiDate is null
                      BEGIN
                        INSERT #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                          SELECT @v_exchangeCode, @v_secuCode, @v_fundAcctCode AS prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate
                        SELECT @v_createPosiDate = @v_settleDate
                      END                 
                    ELSE
                      BEGIN
                        UPDATE #tt_cellcreatePosiDateSum SET createPosiDate = @v_createPosiDate, 
                                                    posiQty = posiQty + @v_matchQty, 
                                                    costChgAmt = costChgAmt + 0, 
                                                    lastestOperateDate = @v_settleDate
                                                WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                      AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  
                      END
                   
                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @v_fundAcctCode AS prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, '1242' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          0, 0 AS matchNetPrice, 0, 0, 0,
                          0, 0, 0 AS rlzChgProfit 
                  BREAK
                END
            END
          SET rowcount 0
        END
       
    ELSE IF @v_secuBizTypeCode in ('103','106')   -- 103 SGMR �¹��깺, 106 SGZQ �¹���ǩ
      begin
        truncate TABLE #tt_cellPosiQtyDetial

        insert #tt_cellPosiQtyDetial (createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
                        select @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, sum(matchQty), 0, 0
                          from #tt_purchaseEntr
                         --where exchangeCode = @v_exchangeCode AND dbo.fnGetOriginSecuCode(exchangeCode, secuCode) = @v_originSecuCode AND fundAcctCode = @v_fundAcctCode
                         WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND fundAcctCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                               AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      group by occurDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode

        IF exists (select * from #tt_cellPosiQtyDetial)
          begin
            select @v_purchaseComAmo = sum(posiQty) from #tt_cellPosiQtyDetial
            --��ʱ�������ֶβ�ȫ
            --select @v_openQtyUnitValue = case when value = '1' AND @v_exchangeCode = '0' then 500
            --                      when value = '1' AND @v_exchangeCode = '1' then 1000
            --                      ELSE 1 end from sims2016TradeToday..systemCfg where item_bs = 'XGZQZXFPDW'
            select @v_openQtyUnitValue = case when @v_exchangeCode = 'XSHE' then 1  when @v_exchangeCode = 'XSHG' then 1 ELSE 1 end

            select @v_openQtyUnitValue = isnull(@v_openQtyUnitValue, 1)
            update #tt_cellPosiQtyDetial set matchQty = floor(round((posiQty  * @v_matchQty / convert(money, @v_purchaseComAmo)), 4) / @v_openQtyUnitValue) * @v_openQtyUnitValue,
                                      costChgAmt = floor(round((posiQty  * @v_matchQty / convert(money, @v_purchaseComAmo)), 4) / @v_openQtyUnitValue) * @v_openQtyUnitValue * round(@v_matchNetPrice, 2)

            select @v_matchQty = @v_matchQty - sum(matchQty), @v_costChgAmt = ISNULL(@v_costChgAmt,0) - ISNULL(sum(costChgAmt),0) from #tt_cellPosiQtyDetial

            IF exists(select * from tempdb..sysobjects where id=object_id('tempdb..#tt_purchaseEntr1'))
            DROP TABLE #tt_purchaseEntr1
            SELECT * INTO #tt_purchaseEntr1 FROM #tt_purchaseEntr

            IF @v_matchQty != 0 or @v_costChgAmt != 0 or @v_rlzChgProfit != 0 -- β��
              begin 
				      while(@v_matchQty >= @v_openQtyUnitValue)
				        begin
					      declare @tempCjkhdm VARCHAR(20)
					      select top 1 @tempCjkhdm = prodCellCode from  #tt_purchaseEntr1 
								       where exchangeCode = @v_exchangeCode AND dbo.fnGetOriginSecuCode(exchangeCode, secuCode) = @v_originSecuCode AND fundAcctCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                             AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
								       order by matchQty desc, occurDatetime asc
				          update #tt_cellPosiQtyDetial set matchQty = matchQty + @v_openQtyUnitValue, costChgAmt = costChgAmt + @v_openQtyUnitValue * @v_matchNetPrice 
						         where prodCellCode = @tempCjkhdm
      	                
	                  delete #tt_purchaseEntr1 where prodCellCode = @tempCjkhdm
      	                  
					      select @v_matchQty = @v_matchQty - @v_openQtyUnitValue                  
				  end	

              delete #tt_cellPosiQtyDetial where matchQty = 0   --ɾ���깺����������ǩ����Ϊ0����ˮ
              end
          end
        -- δ�ҵ���Ӧί��
        ELSE
          begin
            IF not exists (select * from #tt_cellcreatePosiDateSum where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode)
			  insert #tt_cellcreatePosiDateSum(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                               select @v_exchangeCode, @v_secuCode, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate
            ELSE
              begin
                update #tt_cellcreatePosiDateSum set posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + @v_costChgAmt
                       where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
              end

            insert #tt_cellPosiQtyDetial(createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
						   select @v_settleDate, @v_fundAcctCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, 0, @v_matchQty, round(@v_costChgAmt, 2)
          END
          
         INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                      exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                      prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                      matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                      costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
         SELECT DISTINCT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                matchQty, 0 AS matchNetPrice, -round(costChgAmt, 2), @v_matchTradeFeeAmt, @v_matchSettleAmt,
                round(costChgAmt, 2), 0, 0 AS rlzChgProfit 
                from #tt_cellPosiQtyDetial

        -- ���»������ӳֲ�
        --DELETE #tt_cellcreatePosiDateSum
        
        update a set posiQty = a.posiQty + b.matchQty
               from #tt_cellcreatePosiDateSum a 
					join #tt_cellPosiQtyDetial b
                    on a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode AND a.prodCellCode = b.prodCellCode AND a.currencyCode = b.currencyCode 
                                                AND a.marketLevelCode = b.marketLevelCode AND a.hedgeFlagCode = b.hedgeFlagCode AND a.longShortFlagCode = b.longShortFlagCode 

        insert #tt_cellcreatePosiDateSum(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                         select exchangeCode, secuCode, prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate
                                from (select @v_exchangeCode as exchangeCode, @v_secuCode as secuCode, a.prodCellCode, @v_settleDate as createPosiDate, a.matchQty as posiQty, a.costChgAmt as costChgAmt, @v_settleDate as lastestOperateDate, b.createPosiDate as jcrq_y
                                             from #tt_cellPosiQtyDetial a 
                                                  left join #tt_cellcreatePosiDateSum b on a.prodCellCode = b.prodCellCode AND b.exchangeCode = @v_exchangeCode AND b.secuCode = @v_secuCode AND b.currencyCode = @v_currencyCode 
                                                AND b.marketLevelCode = @v_marketLevelCode AND b.hedgeFlagCode = @v_hedgeFlagCode AND b.longShortFlagCode = @v_longShortFlagCode)x
                                where x.jcrq_y is NULL

      end
      --�깺����
    ELSE IF @v_secuBizTypeCode in ('105')
      begin
          while @v_matchQty > 0
            begin
              select @temp_mr_prodCellCode = null
              select top 1 @temp_mr_prodCellCode = prodCellCode, @temp_mr_secuCode = secuCode, @temp_mr_matchQty = abs(posiQty), @temp_mr_costChgAmt = costChgAmt,
						   @temp_mr_per_costChgAmt = costChgAmt / abs(posiQty), @temp_mr_createPosiDate = createPosiDate
					 from #tt_cellcreatePosiDateSum
					 where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode  AND currencyCode = @v_currencyCode AND marketLevelCode = @v_marketLevelCode 
					 AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode AND abs(posiQty) > 0
					 order by createPosiDate, prodCellCode

              IF @temp_mr_prodCellCode is not null
                begin
                  IF @v_matchQty < @temp_mr_matchQty
                    select @temp_mc_matchQty = @v_matchQty
                  ELSE
                    select @temp_mc_matchQty = @temp_mr_matchQty

                  select @v_matchQty = @v_matchQty - @temp_mc_matchQty

                  IF @temp_mc_matchQty < @temp_mr_matchQty
                    begin
                      select @temp_mc_costChgAmt = round(@temp_mc_matchQty * @temp_mr_per_costChgAmt, 2)
                    end
                  ELSE
                    begin
                      select @temp_mc_costChgAmt = @temp_mr_costChgAmt
                    end

                  IF @temp_mc_matchQty != @temp_mr_matchQty
                    select @temp_mr_costChgAmt = round(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)

                  select @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt

                  select @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt

                  select @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt

                  update #tt_cellcreatePosiDateSum set posiQty = posiQty - @temp_mc_matchQty,
                                              costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestOperateDate = @v_settleDate
                                        where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode AND currencyCode = @v_currencyCode 
                                              AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          -1 * @temp_mc_matchQty, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @temp_mc_matchQty, 0 AS matchNetPrice, @temp_mr_costChgAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          -1 * @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
                  end
              ELSE -- �Ҳ�����Ӧ�ļ�¼
                begin
                   select @v_createPosiDate = null
                   select @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate from #tt_cellcreatePosiDateSum
					      where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                      AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   IF @v_createPosiDate is null
                      begin
                        insert #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                          select @v_exchangeCode, @v_secuCode, @v_fundAcctCode as prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate

                        select @v_createPosiDate = @v_settleDate
                      end
                    ELSE
                      begin
                        update #tt_cellcreatePosiDateSum set createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + 0, lastestOperateDate = @v_settleDate
                               where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      end

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @v_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
                    break
                end
            end

        end
      -- �¹����С�
    ELSE IF(@v_secuBizTypeCode = '107')
      begin
          while @v_matchQty > 0
            begin
              select @temp_mr_prodCellCode = null
              select top 1 @temp_mr_prodCellCode = prodCellCode,
						   @temp_mr_secuCode = secuCode,
						   @temp_mr_matchQty = abs(posiQty),
               @temp_mr_costChgAmt = costChgAmt,
               @temp_mr_per_costChgAmt = costChgAmt / abs(posiQty),
               @temp_mr_createPosiDate = createPosiDate
               from #tt_cellcreatePosiDateSum
               where exchangeCode = @v_exchangeCode AND dbo.fnGetOriginSecuCode(exchangeCode, secuCode) = @v_secuCode AND currencyCode = @v_currencyCode 
                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode AND abs(posiQty) > 0
						   order by createPosiDate, prodCellCode

              IF @temp_mr_prodCellCode is not null
                begin
                  IF @v_matchQty < @temp_mr_matchQty
                    select @temp_mc_matchQty = @v_matchQty
                  ELSE
                    select @temp_mc_matchQty = @temp_mr_matchQty

                  select @v_matchQty = @v_matchQty - @temp_mc_matchQty

                  IF @temp_mc_matchQty < @temp_mr_matchQty
                    begin
                      select @temp_mc_costChgAmt = round(@temp_mc_matchQty * @temp_mr_per_costChgAmt, 2)
                    end
                  ELSE
                    begin
                      select @temp_mc_costChgAmt = @temp_mr_costChgAmt
                    end

                  IF @temp_mc_matchQty != @temp_mr_matchQty
                    select @temp_mr_costChgAmt = round(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2)

                  select @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt

                  select @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt

                  select @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt


                  update #tt_cellcreatePosiDateSum set posiQty = posiQty - @temp_mc_matchQty, costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestOperateDate = @v_settleDate
                         where exchangeCode = @v_exchangeCode AND dbo.fnGetOriginSecuCode(exchangeCode, secuCode) = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode 
                               AND currencyCode = @v_currencyCode AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit) 
                   --�깺��ǩת����¼ '1071','�¹�����ת��'
                   --'����ͨ��'                                               
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, '1071' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          -1 * @temp_mc_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit                           

                   --�¹�����
                   select @v_createPosiDate = null

                   select @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate 
                     from #tt_cellcreatePosiDateSum
						         where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 

                   IF @v_createPosiDate is null
                     begin
                       insert #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                         select @v_exchangeCode, @v_secuCode, @temp_mr_prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @temp_mc_matchQty, @temp_mr_costChgAmt, @v_settleDate

                        select @v_createPosiDate = @v_settleDate
                      end
                    ELSE
                      begin
                        update #tt_cellcreatePosiDateSum set createPosiDate = @v_createPosiDate, posiQty = posiQty + @temp_mc_matchQty, costChgAmt = costChgAmt + @temp_mr_costChgAmt, lastestOperateDate = @v_settleDate
                               where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      end

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)            
                   --'��ͨ��'                                                   
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, 'B' AS buySellFlagCode, @v_openCloseFlagCode, '1072' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @temp_mc_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          @temp_mr_costChgAmt, 0, 0 AS rlzChgProfit 
                  end
              ELSE -- �Ҳ�����Ӧ�ļ�¼
                begin
                  select @v_createPosiDate = null
                  select @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastestOperateDate = lastestOperateDate from #tt_cellcreatePosiDateSum
                         where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_fundAcctCode
                   IF @v_createPosiDate is null
                     begin
                       insert #tt_cellcreatePosiDateSum (exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                         select @v_exchangeCode, @v_secuCode, @v_fundAcctCode as prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate

                       select @v_createPosiDate = @v_settleDate
                      end
                    ELSE
                      begin
                        update #tt_cellcreatePosiDateSum set createPosiDate = @v_createPosiDate, posiQty = posiQty + @v_matchQty, costChgAmt = costChgAmt + 0, lastestOperateDate = @v_settleDate
                               where exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                      end

                   INSERT #tt_prodCellCheckJrnlES (createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                costChgAmt, occupyCostChgAmt, rlzChgProfit)                                                
                   SELECT @v_settleDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode,0,
                          @v_exchangeCode, @v_secuCode, @v_secuName, @v_originSecuCode, @v_secuTradeTypeCode, 
                          @temp_mr_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, '1071' AS secuBizTypeCode, @v_marketLevelCode, @v_hedgeFlagCode, @v_currencyCode,
                          @v_matchQty, 0 AS matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                          0 AS costChgAmt, 0, 0 AS rlzChgProfit 
                    break
                end
            end
          set rowcount 0
        end  
    */
    --���봦��
    
    ELSE IF @v_buySellFlagCode = '1' AND @v_openCloseFlagCode = '1' AND @v_secuBizTypeCode != '183' AND @v_secuBizTypeCode != '187' AND @v_secuBizTypeCode != '188'     
    BEGIN
    SELECT  @v_createPosiDate  = null                        --��������
    SELECT @v_posiQty = null                                 --�ֲ�����
    SELECT @v_lastsettleDate = null                          --��󽨲�����

    SELECT @v_createPosiDate = createPosiDate, @v_posiQty = posiQty, @v_lastsettleDate = lastestOperateDate FROM #tt_cellcreatePosiDateSum
           WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode; 
      
     IF @v_createPosiDate is null
     BEGIN     
				  INSERT INTO #tt_cellcreatePosiDateSum(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                 VALUES(@v_exchangeCode, @v_secuCode, @v_prodCellCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, @v_costChgAmt, @v_settleDate);
          SELECT @v_createPosiDate = @v_settleDate   
     END
     ELSE IF @v_posiQty <= 0 AND @v_lastsettleDate != @v_settleDate
     BEGIN
			  UPDATE #tt_cellcreatePosiDateSum SET createPosiDate = @v_settleDate,
                                                      posiQty = @v_matchQty,
                                                   costChgAmt = @v_costChgAmt,
                                           lastestOperateDate = @v_settleDate
                                         WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                               AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
     END
     ELSE
			BEGIN
			UPDATE #tt_cellcreatePosiDateSum SET createPosiDate = @v_createPosiDate,
                                                      posiQty = posiQty + @v_matchQty,
                                                   costChgAmt = costChgAmt + @v_costChgAmt,
                                                 lastestOperateDate = @v_settleDate
                                               WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND currencyCode = @v_currencyCode 
                                                     AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
			END
			
			   INSERT INTO #tt_prodCellCheckJrnlES (serialNO, createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                                exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode,  
                                                prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                                matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                                costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                         VALUES(@v_serialNO, @v_createPosiDate, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode,@v_prodCode, @v_investPortfolioCode,
                                                @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                                @v_secuTradeTypeCode, @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode, @v_currencyCode,
                                                @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                                                @v_costChgAmt,@v_costChgAmt, @v_rlzChgProfit);
			END			
--���봦��END

--��������BEGIN
ELSE IF @v_buySellFlagCode = '1' AND @v_openCloseFlagCode = 'A' AND @v_secuBizTypeCode != '183' AND @v_secuBizTypeCode != '187' AND @v_secuBizTypeCode != '188'
BEGIN
  SELECT @v_costChgAmt = ISNULL(ROUND(@v_costChgAmt, 2),0)
	SELECT @temp_mc_per_costChgAmt = @v_costChgAmt / @v_matchQty
  SELECT @temp_mc_per_rlzChgProfit = @v_rlzChgProfit / @v_matchQty
  SELECT @temp_mc_per_cashCurrSettleAmt = @v_cashCurrentSettleAmt / @v_matchQty
  SELECT @temp_mc_per_matchTradeFeeAmt = @v_matchTradeFeeAmt / @v_matchQty
  WHILE @v_matchQty > 0  
  BEGIN
    SELECT @temp_mr_prodCellCode = NULL

			SELECT TOP 1
			  @temp_mr_prodCellCode = prodCellCode, @temp_mr_matchQty = posiQty, @temp_mr_costChgAmt = costChgAmt, @temp_mr_per_costChgAmt = costChgAmt / posiQty, @temp_mr_createPosiDate = createPosiDate
				FROM #tt_cellcreatePosiDateSum
				WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode AND posiQty > 0
				ORDER BY createPosiDate
			--�ҵ���Ӧ�����봦��ʼ	
			IF @temp_mr_prodCellCode IS NOT NULL
				BEGIN	

			        IF @temp_mr_matchQty > @v_matchQty 
                  SELECT @temp_mc_matchQty = @v_matchQty;
                ELSE
                  SELECT @temp_mc_matchQty = @temp_mr_matchQty;         
               SELECT @v_matchQty = @v_matchQty - @temp_mc_matchQty

                IF @v_matchQty != 0 
									BEGIN
                    SELECT @temp_mc_costChgAmt = ROUND(@temp_mc_matchQty * @temp_mc_per_costChgAmt, 2)
                    SELECT @temp_mc_cashCurrSettleAmt = ROUND(@temp_mc_matchQty * @temp_mc_per_cashCurrSettleAmt, 2)
                    SELECT @temp_mc_matchTradeFeeAmt = ROUND(@temp_mc_matchQty * @temp_mc_per_matchTradeFeeAmt, 2)
									END
                ELSE
									BEGIN
                  SELECT @temp_mc_costChgAmt = @v_costChgAmt;
                  SELECT @temp_mc_cashCurrSettleAmt = @v_cashCurrentSettleAmt
                  SELECT @temp_mc_matchTradeFeeAmt = @v_matchTradeFeeAmt 
                  END
                  
               IF @temp_mc_matchQty != @temp_mr_matchQty 
                  SELECT @temp_mr_costChgAmt = ROUND(@temp_mr_per_costChgAmt * @temp_mc_matchQty, 2);
                
                SELECT @temp_mc_rlzChgProfit = -@temp_mc_costChgAmt - @temp_mr_costChgAmt
                SELECT @v_costChgAmt = @v_costChgAmt - @temp_mc_costChgAmt
                SELECT @v_cashCurrentSettleAmt = @v_cashCurrentSettleAmt - @temp_mc_cashCurrSettleAmt
                SELECT @v_matchTradeFeeAmt = @v_matchTradeFeeAmt - @temp_mc_matchTradeFeeAmt
 
               
                UPDATE #tt_cellcreatePosiDateSum SET posiQty = posiQty - @temp_mc_matchQty,
                                              costChgAmt = costChgAmt - @temp_mr_costChgAmt,
                                              lastestOperateDate = @v_settleDate
                                        WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @temp_mr_prodCellCode AND currencyCode = @v_currencyCode 
                                                AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                                                
                INSERT INTO #tt_prodCellCheckJrnlES(serialNO, createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                                     exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, 
                                                     prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                                     matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                                     costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                              VALUES(@v_serialNO, @temp_mr_createPosiDate, @v_settleDate,@v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode,
                                                     @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                                     @v_secuTradeTypeCode, @temp_mr_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                                     -@temp_mc_matchQty, @v_matchNetPrice, @temp_mc_cashCurrSettleAmt, @temp_mc_matchTradeFeeAmt, @v_matchSettleAmt,
                                                     @temp_mr_costChgAmt, @temp_mc_cashCurrSettleAmt, @temp_mc_rlzChgProfit)                                           
          END --�ҵ���Ӧ�����봦�����
         ELSE --�Ҳ�����Ӧ�������¼
                BEGIN
                DELETE #tt_cellcreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCellCode
                INSERT INTO #tt_prodCellCheckJrnlES(serialNO, createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                                     exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, 
                                                     prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                                     matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                                     costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                              VALUES(@v_serialNO, @v_settleDate, @v_settleDate,@v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode,
                                                     @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                                     @v_secuTradeTypeCode, @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                                     -@v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                                     0, -@v_cashCurrentSettleAmt, -@v_costChgAmt)
                BREAK                                     
                END
  END
END
--��������END

 ELSE IF @v_secuBizTypeCode = '183' OR @v_secuBizTypeCode = '187' OR @v_secuBizTypeCode = '188'
	BEGIN
		
		TRUNCATE TABLE #tt_cellPosiQtyDetial
    TRUNCATE TABLE #tt_cellPosiQtySum
    
     INSERT INTO #tt_cellPosiQtyDetial(createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
                                      SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(posiQty), 0, 0
                                        FROM #tt_cellCheckJrnl_old
                                       WHERE operateDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND currencyCode = @v_currencyCode 
                                             AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
                                       GROUP BY prodCellCode
                                       HAVING SUM(posiQty) > 0
                                       
		INSERT INTO #tt_cellPosiQtyDetial(createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt)
														SELECT @v_settleDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, SUM(matchQty), 0, 0
															FROM #tt_prodCellCheckJrnlES
														 WHERE occurDate <= @v_shareRecordDate AND exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND currencyCode = @v_currencyCode 
                                   AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode 
														 GROUP BY prodCellCode
														 HAVING SUM(matchQty) != 0
    
    INSERT INTO #tt_cellPosiQtySum(createPosiDate, prodCellCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                                   SELECT @v_settleDate, prodCellCode, SUM(posiQty), 0, 0, 0
                                     FROM #tt_cellPosiQtyDetial
                                     GROUP BY prodCellCode
                                     HAVING SUM(posiQty) > 0                                     
                             
   IF exists(SELECT 1 FROM #tt_cellPosiQtySum)
		BEGIN
			 SELECT @v_posiQty = SUM(posiQty) FROM #tt_cellPosiQtySum;
              UPDATE #tt_cellPosiQtySum SET matchQty = FLOOR(ROUND(posiQty / @v_posiQty * @v_matchQty, 4)),
                                           costChgAmt = ROUND(ROUND(posiQty / @v_posiQty * @v_costChgAmt, 4), 2),
                                           rlzChgProfit = ROUND(ROUND(posiQty / @v_posiQty * @v_rlzChgProfit, 4), 2)
              
              SELECT @v_matchQty = @v_matchQty - SUM(matchQty), @v_costChgAmt =  @v_costChgAmt - SUM(costChgAmt), @v_rlzChgProfit = @v_rlzChgProfit - SUM(rlzChgProfit)
                FROM #tt_cellPosiQtySum
                
                
    IF @v_matchQty != 0 OR @v_costChgAmt != 0 OR @v_rlzChgProfit != 0 
    BEGIN
                SELECT  TOP 1
                  @v_tempCellCode = prodCellCode
                
                
                 FROM #tt_cellPosiQtySum  ORDER BY matchQty DESC;
                UPDATE #tt_cellPosiQtySum SET matchQty = matchQty + @v_matchQty,
                                           costChgAmt = costChgAmt + @v_costChgAmt,
                                         rlzChgProfit = rlzChgProfit + @v_rlzChgProfit
                                   WHERE prodCellCode = @v_tempCellCode
      END
      
      MERGE INTO #tt_cellPosiQtySum a 
                     USING #tt_cellcreatePosiDateSum b ON (a.prodCellCode = b.prodCellCode AND b.exchangeCode = @v_exchangeCode AND b.secuCode = @v_secuCode 
                                                           AND a.currencyCode = b.currencyCode AND a.marketLevelCode = b.marketLevelCode AND a.hedgeFlagCode = b.hedgeFlagCode 
                                                           AND a.longShortFlagCode = b.longShortFlagCode)
                      WHEN MATCHED THEN UPDATE SET a.createPosiDate = b.createPosiDate;
                      
      MERGE INTO #tt_cellcreatePosiDateSum a
                     USING #tt_cellPosiQtySum b ON (a.prodCellCode = b.prodCellCode AND a.exchangeCode = @v_exchangeCode AND a.secuCode = @v_secuCode 
                                                    AND a.currencyCode = @v_currencyCode AND a.marketLevelCode = @v_marketLevelCode AND a.hedgeFlagCode = @v_hedgeFlagCode 
                                                    AND a.longShortFlagCode = @v_longShortFlagCode)
                      WHEN MATCHED THEN UPDATE SET a.posiQty = a.posiQty + b.matchQty,
                                                   a.costChgAmt = a.costChgAmt + b.costChgAmt,
                                                   a.createPosiDate = CASE WHEN a.posiQty <= 0 THEN b.createPosiDate ELSE a.createPosiDate END;		
		END
			ELSE 
		   BEGIN
				IF exists(SELECT 1 FROM #tt_cellcreatePosiDateSum WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCode)
				UPDATE #tt_cellcreatePosiDateSum SET posiQty = posiQty + @v_matchQty 
				WHERE exchangeCode = @v_exchangeCode AND secuCode = @v_secuCode AND prodCellCode = @v_prodCode AND currencyCode = @v_currencyCode 
              AND marketLevelCode = @v_marketLevelCode AND hedgeFlagCode = @v_hedgeFlagCode AND longShortFlagCode = @v_longShortFlagCode  
				
				ELSE

			  INSERT INTO #tt_cellcreatePosiDateSum(exchangeCode, secuCode, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, createPosiDate, posiQty, costChgAmt, lastestOperateDate)
                                              VALUES(@v_exchangeCode, @v_secuCode, @v_prodCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, @v_settleDate, @v_matchQty, 0, @v_settleDate)
                                              		   
		    INSERT INTO #tt_cellPosiQtySum(createPosiDate, prodCellCode, currencyCode, marketLevelCode,hedgeFlagCode,longShortFlagCode, posiQty, matchQty, costChgAmt, rlzChgProfit)
                                              VALUES(@v_settleDate, @v_prodCode, @v_currencyCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_longShortFlagCode, 0, @v_matchQty, 0, -@v_costChgAmt + @v_rlzChgProfit)
		   END
		   
		   INSERT INTO #tt_prodCellCheckJrnlES(serialNO, createPosiDate, occurDate, shareRecordDate, fundAcctCode, prodCode, investPortfolioCode,
                                               exchangeCode, secuCode, secuName, originSecuCode, secuTradeTypeCode, 
                                               prodCellCode, buySellFlagCode, openCloseFlagCode, secuBizTypeCode, marketLevelCode, hedgeFlagCode, currencyCode,
                                               matchQty, matchNetPrice, cashSettleAmt, matchTradeFeeAmt, matchSettleAmt,
                                               costChgAmt, occupyCostChgAmt, rlzChgProfit)
                                        SELECT @v_serialNO, @v_createPosiDate, @v_settleDate,@v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode,
                                               @v_exchangeCode, @v_secuCode, ' ', @v_originSecuCode,
                                               @v_secuTradeTypeCode, prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode,@v_hedgeFlagCode,@v_currencyCode,
                                               matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt,
                                               costChgAmt, -(costChgAmt - rlzChgProfit), rlzChgProfit
                                          FROM #tt_cellPosiQtySum
	END

  FETCH for_mccjb INTO @v_serialNO, @v_orderID, @v_settleDate, @v_shareRecordDate, @v_fundAcctCode, @v_prodCode, @v_investPortfolioCode, 
                       @v_exchangeCode, @v_secuCode, @v_originSecuCode,@v_secuName, @v_secuTradeTypeCode, @v_longShortFlagCode,
                       @v_prodCellCode, @v_buySellFlagCode, @v_openCloseFlagCode, @v_secuBizTypeCode, @v_marketLevelCode, @v_currencyCode, @v_hedgeFlagCode, 
                       @v_matchQty, @v_matchNetPrice, @v_cashCurrentSettleAmt, @v_matchTradeFeeAmt, @v_matchSettleAmt, 
                       @v_costChgAmt, @v_rlzChgProfit

    END
        
  CLOSE for_mccjb
  DEALLOCATE for_mccjb
 
 RETURN 0
go

--exec opCalcProdCellCheckJrnlES '','','','','','','2017-03-17'
--exec opCalcProdCellCheckJrnlES '','','','','','','2017-03-15' ����
--SELECT * FROM secuBizType WHERE secuBizTypeName LIKE '���%'

