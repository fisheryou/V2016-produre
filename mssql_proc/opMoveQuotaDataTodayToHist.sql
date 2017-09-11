USE sims2016Proc
go
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'opMoveQuotaDataTodayToHist')
	DROP PROC opMoveQuotaDataTodayToHist
go

CREATE PROC opMoveQuotaDataTodayToHist
(
  @o_errorMsgCode          INT              OUT,
  @o_errorMsgText          VARCHAR(255)     OUT,
  @i_operatorCode          VARCHAR(255),       --����Ա����
  @i_operatorPassword      VARCHAR(255),       --����Ա����
  @i_operateStationText    VARCHAR(2048),      --����Ա������Ϣ
  @i_latestTradeDate       CHAR(10)            --���������
  )
AS
/*
����: opMoveQuotaDataTodayToHist
����: ������(�ڻ�/�ֻ�)������Ƶ���ʷ����(�ڻ�/�ֻ�)
==================================================================================================
Author:yugy
Version:1.0
Date��2017-04-10
Description�����ڻ�/�ֻ����ջ�������ֱ�Ǩ�Ƶ��ڻ�/�ֻ�������ʷ������ڻ�/�ֻ��ֲ���ʷ������
History��

==================================================================================================
NOTE��
*/
SET NOCOUNT ON
-- ɾ����ʷ���������������ڵ��ձ��д��ڵ�����(����ʷ�����е���һ�������յ�����[��������]ɾ��)
    DELETE FROM sims2016QuotaHist..primaryQuotaESHist WHERE quotaDate = @i_latestTradeDate
    -- ���������������ȫ�����뵽��ʷ�������
    INSERT INTO sims2016QuotaHist..primaryQuotaESHist(quotaDate       , -- ��������YYYY-MM-DD    
                                       quotaTime       , -- ����ʱ��HH:MM:SS.SSS  
                                       exchangeCode        , -- ����������             
                                       secuCode        , -- ֤ȯ����              
                                       secuStatusCode  , -- ֤ȯ״̬����            
                                       prevIOPVValue       , -- ����IOPV            
                                       prevDeltaValue      , -- ������ʵ��             
                                       prevClosePrice      , -- �������̼�             
                                       prevTotalLongPosiQty, -- ���ճֲ���             
                                       openPrice           , -- ���̼�               
                                       highestPrice        , -- ��߼�               
                                       lowestPrice         , -- ��ͼ�               
                                       lastestPrice        , -- ���¼�               
                                       iopvValue           , -- IOPV              
                                       deltaValue          , -- ��ʵ��               
                                       closePrice          , -- ���̼�               
                                       totalLongPosiQty    , -- �ֲ���               
                                       totalMatchQty       , -- �ɽ�����              
                                       totalTickCount      , -- �ɽ�����              
                                       totalMatchAmt       , -- �ɽ����              
                                       callOnePrice        , -- ��1�۸�              
                                       callOneQty          , -- ��1����              
                                       putOnePrice         , -- ��1�۸�              
                                       putOneQty)            -- ��1���� 
                                SELECT quotaDate       , -- ��������YYYY-MM-DD
                                       quotaTime       , -- ����ʱ��HH:MM:SS.SSS
                                       exchangeCode        , -- ����������
                                       secuCode        , -- ֤ȯ����
                                       secuStatusCode  , -- ֤ȯ״̬����
                                       prevIOPVValue       , -- ����IOPV
                                       prevDeltaValue      , -- ������ʵ��
                                       prevClosePrice      , -- �������̼�
                                       prevTotalLongPosiQty, -- ���ճֲ���
                                       openPrice           , -- ���̼�
                                       highestPrice        , -- ��߼�
                                       lowestPrice         , -- ��ͼ�
                                       lastestPrice        , -- ���¼�
                                       iopvValue           , -- IOPV
                                       deltaValue          , -- ��ʵ��
                                       closePrice          , -- ���̼�
                                       totalLongPosiQty    , -- �ֲ���
                                       totalMatchQty       , -- �ɽ�����
                                       totalTickCount      , -- �ɽ�����
                                       totalMatchAmt       , -- �ɽ����
                                       callOnePrice        , -- ��1�۸�
                                       callOneQty          , -- ��1����
                                       putOnePrice         , -- ��1�۸�
                                       putOneQty             -- ��1����     
                                  FROM sims2016QuotaToday..primaryQuotaESToday
                                 WHERE quotaDate = @i_latestTradeDate;  --����������з���һ�����յ����ݣ���������
                                 
                                 
    -- ɾ����ʷ���������������ڵ��ձ��д��ڵ�����(����ʷ�����е���һ�������յ�����[��������]ɾ��)
    DELETE FROM sims2016QuotaHist..primaryQuotaFHist WHERE quotaDate = @i_latestTradeDate
    -- ���������������ȫ�����뵽��ʷ�������
    INSERT INTO sims2016QuotaHist..primaryQuotaFHist(quotaDate       , -- ��������YYYY-MM-DD   
                                      quotaTime       , -- ����ʱ��HH:MM:SS.SSS 
                                      exchangeCode        , -- ����������            
                                      secuCode        , -- ֤ȯ����             
                                      secuStatusCode  , -- ֤ȯ״̬����           
                                      prevIOPVValue       , -- ����IOPV           
                                      prevDeltaValue      , -- ������ʵ��            
                                      prevClosePrice      , -- �������̼�            
                                      prevSettlePrice     , -- ���ս����            
                                      prevTotalLongPosiQty, -- ���ճֲ���            
                                      lowerLimitPrice     , -- �����ͣ�۸�           
                                      upperLimitPrice     , -- ������ͣ�۸�           
                                      openPrice           , -- ���̼�              
                                      highestPrice        , -- ��߼�              
                                      lowestPrice         , -- ��ͼ�              
                                      lastestPrice        , -- ���¼�              
                                      iopvValue           , -- IOPV             
                                      deltaValue          , -- ��ʵ��              
                                      closePrice          , -- ���̼�              
                                      settlePrice         , -- �����              
                                      totalLongPosiQty    , -- �ֲ���              
                                      totalMatchQty       , -- �ɽ�����             
                                      totalTickCount      , -- �ɽ�����             
                                      totalMatchAmt       , -- �ɽ����             
                                      callOnePrice        , -- ��1�۸�             
                                      callOneQty          , -- ��1����             
                                      putOnePrice         , -- ��1�۸�             
                                      putOneQty)            -- ��1����    
                               SELECT quotaDate       , -- ��������YYYY-MM-DD   
                                      quotaTime       , -- ����ʱ��HH:MM:SS.SSS 
                                      exchangeCode        , -- ����������            
                                      secuCode        , -- ֤ȯ����             
                                      secuStatusCode  , -- ֤ȯ״̬����           
                                      prevIOPVValue       , -- ����IOPV           
                                      prevDeltaValue      , -- ������ʵ��            
                                      prevClosePrice      , -- �������̼�            
                                      prevSettlePrice     , -- ���ս����            
                                      prevTotalLongPosiQty, -- ���ճֲ���            
                                      lowerLimitPrice     , -- �����ͣ�۸�           
                                      upperLimitPrice     , -- ������ͣ�۸�           
                                      openPrice           , -- ���̼�              
                                      highestPrice        , -- ��߼�              
                                      lowestPrice         , -- ��ͼ�              
                                      lastestPrice        , -- ���¼�              
                                      iopvValue           , -- IOPV             
                                      deltaValue          , -- ��ʵ��              
                                      closePrice          , -- ���̼�              
                                      settlePrice         , -- �����              
                                      totalLongPosiQty    , -- �ֲ���              
                                      totalMatchQty       , -- �ɽ�����             
                                      totalTickCount      , -- �ɽ�����             
                                      totalMatchAmt       , -- �ɽ����             
                                      callOnePrice        , -- ��1�۸�             
                                      callOneQty          , -- ��1����             
                                      putOnePrice         , -- ��1�۸�             
                                      putOneQty             -- ��1����   
                                 FROM sims2016QuotaToday..primaryQuotaFToday
                                WHERE quotaDate = @i_latestTradeDate; --����������з���һ�����յ����ݣ���������
                                
          --����ʷ�����е���һ�������յ�����[��������]ɾ��
    DELETE FROM sims2016QuotaHist..posiQuotaESHist WHERE quotaDate = @i_latestTradeDate
   --����������������ݲ��뵽�ֲ���ʷ�������
    INSERT INTO sims2016QuotaHist..posiQuotaESHist(quotaDate       , -- ��������YYYY-MM-DD
                                    exchangeCode        , -- ����������
                                    secuCode        , -- ֤ȯ����
                                    prevClosePrice      , -- �������̼�
                                    openPrice           , -- ���̼�
                                    highestPrice        , -- ��߼�
                                    lowestPrice         , -- ��ͼ�
                                    lastestPrice        , -- ���¼�
                                    closePrice)           -- ���̼�
                             SELECT quotaDate       , -- ��������YYYY-MM-DD                                   
                                    p.exchangeCode      , -- ����������
                                    p.secuCode      , -- ֤ȯ����  
                                    prevClosePrice      , -- �������̼�
                                    openPrice           , -- ���̼�
                                    highestPrice        , -- ��߼�
                                    lowestPrice         , -- ��ͼ�
                                    lastestPrice        , -- ���¼�
                                    closePrice            -- ���̼�    
                               FROM sims2016QuotaToday..primaryQuotaESToday p
                               INNER JOIN(SELECT DISTINCT exchangeCode,secuCode FROM sims2016TradeToday..prodCellPosiES) b
                                  ON quotaDate = @i_latestTradeDate AND p.exchangeCode = b.exchangeCode AND p.secuCode = b.secuCode;  --1.����������з���һ�����յ����ݣ��������� 2.���ڲ�Ʒ��Ԫ�ֱֲ��֤ȯ��������
                                  
                                  --����ʷ�����е���һ�������յ�����[��������]ɾ��
    DELETE FROM sims2016QuotaHist..posiQuotaFHist WHERE quotaDate = @i_latestTradeDate;
  --����������������ݲ��뵽�ֲ���ʷ�������
    INSERT INTO sims2016QuotaHist..posiQuotaFHist(quotaDate       , -- ��������YYYY-MM-DD                                     
                                   exchangeCode        , -- ����������            
                                   secuCode        , -- ֤ȯ����                                                         
                                   prevClosePrice      , -- �������̼�            
                                   prevSettlePrice     , -- ���ս����                
                                   openPrice           , -- ���̼�              
                                   highestPrice        , -- ��߼�              
                                   lowestPrice         , -- ��ͼ�              
                                   lastestPrice        , -- ���¼�                                              
                                   closePrice          , -- ���̼�              
                                   settlePrice)          -- �����              
                            SELECT quotaDate       , -- ��������YYYY-MM-DD                                       
                                   p.exchangeCode      , -- ����������            
                                   p.secuCode      , -- ֤ȯ����                                                         
                                   prevClosePrice      , -- �������̼�            
                                   prevSettlePrice     , -- ���ս����                      
                                   openPrice           , -- ���̼�              
                                   highestPrice        , -- ��߼�              
                                   lowestPrice         , -- ��ͼ�              
                                   lastestPrice        , -- ���¼�                       
                                   closePrice          , -- ���̼�              
                                   settlePrice           -- �����                                    
                              FROM sims2016QuotaToday..primaryQuotaFToday p
                              INNER JOIN(SELECT DISTINCT exchangeCode,secuCode FROM sims2016TradeToday..prodCellPosiF) b
                              ON quotaDate = @i_latestTradeDate AND p.exchangeCode = b.exchangeCode AND p.secuCode = b.secuCode;  ----1.����������з���һ�����յ����ݣ��������� 2.���ڲ�Ʒ��Ԫ�ֱֲ��֤ȯ��������
  select @o_errorMsgCode = 0, @o_errorMsgText = '�����ʼ���ɹ�'
  RETURN 0
go
