

USE sims2016Proc
go
  IF exists(SELECT * FROM sysobjects WHERE name = 'ipInitRepoCalender')
    DROP PROC ipInitRepoCalender
go
CREATE PROC	ipInitRepoCalender
@i_beginDate VARCHAR(10),
@i_endDate VARCHAR(10)
AS

	CREATE TABLE #temp(
	code                      INT IDENTITY(1, 1),
  tradeDate                 VARCHAR(10), -- �״�������
  exchangeCode              VARCHAR(4),  -- ����������
  secuCode                  VARCHAR(10), -- ֤ȯ����
  expireClearDate           VARCHAR(10), -- ����������
  expireSettleDate          VARCHAR(10), -- �״��ʽ�����
  actualExpireSettleDate    VARCHAR(10), -- �����ʽ�����
  repoMaturityValue         NUMERIC(10,0), -- ��������
  actualRepoMaturityValue   NUMERIC(10,0), -- ʵ��ռ������
	)
BEGIN

 --�α����begin
  DECLARE
    @exchangeCode                         VARCHAR(10)       ,--����������
    @secuCode                             VARCHAR(10)       ,--֤ȯ����
    @repoMaturityValue                          INT                --��������
    
  SELECT a.exchangeCode,a.tradeDate, 
  --ȡ��һ��������
  (SELECT MIN(b.tradeDate) FROM sims2016TradeToday..tradeCalender b WHERE a.exchangeCode = b.exchangeCode and b.tradeDate >= CONVERT(VARCHAR(10), DATEADD(DAY,1, a.tradeDate), 120)) AS nextTradeDate
  INTO #tradeCalender FROM sims2016TradeToday..tradeCalender a
    WHERE a.exchangeCode IN ('XSHG','XSHE') and a.tradeDate between @i_beginDate and @i_endDate
    ORDER BY a.tradeDate, a.exchangeCode
    
  DELETE  sims2016TradeToday..repoCalender
      
  DEClARE db_secucfgb CURSOR FOR SELECT exchangeCode, secuCode, repoMaturityValue
                              FROM sims2016TradeToday..secuDetailCfgP WHERE exchangeCode IN ('XSHG','XSHE')                             
  OPEN db_secucfgb
  FETCH db_secucfgb INTO @exchangeCode, @secuCode, @repoMaturityValue
  
  WHILE 1 = 1
  
	BEGIN 
		INSERT INTO #temp(tradeDate, exchangeCode, secuCode, expireClearDate, expireSettleDate, actualExpireSettleDate, repoMaturityValue, actualRepoMaturityValue) 
		SELECT a.tradeDate, @exchangeCode, @secuCode,
		       (SELECT MIN(b.tradeDate) FROM #tradeCalender b WHERE a.exchangeCode = b.exchangeCode and b.tradeDate >= CONVERT(VARCHAR(10), DATEADD(DAY,@repoMaturityValue, a.tradeDate), 120)) AS expireClearDate,
		       a.nextTradeDate AS expireSettleDate, '' AS actualExpireSettleDate, @repoMaturityValue, 0
		FROM #tradeCalender a WHERE exchangeCode =@exchangeCode 
		  
		--ȡ�����ʽ�����
		UPDATE a SET actualExpireSettleDate = ISNULL(b.nextTradeDate,'') FROM #temp a, #tradeCalender b WHERE a.exchangeCode = b.exchangeCode AND a.expireClearDate = b.tradeDate 
		--����ʵ��ռ������
		UPDATE a SET actualRepoMaturityValue = DATEDIFF(DAY, ISNULL(a.expireSettleDate,''), ISNULL(a.actualExpireSettleDate,'')) FROM #temp a 

		INSERT INTO sims2016TradeToday..repoCalender(
                                                 tradeDate,                        -- �״�������
                                                 exchangeCode,                     -- ����������
                                                 secuCode,                         -- ֤ȯ����
                                                 expireClearDate,                  -- ����������
                                                 expireSettleDate,                 -- �״��ʽ�����
                                                 actualExpireSettleDate,           -- �����ʽ�����
                                                 repoMaturityValue,                -- ��������
                                                 actualRepoMaturityValue,          -- ʵ��ռ������
                                                 operatorCode,                     -- ����Ա����
                                                 operateDatetime                   -- ��������ʱ��
		                                             ) 
		 SELECT tradeDate, exchangeCode, secuCode, expireClearDate, expireSettleDate,actualExpireSettleDate,repoMaturityValue,actualRepoMaturityValue, 'admin', GETDATE() 
		   FROM #temp WHERE actualRepoMaturityValue > 0  

		TRUNCATE TABLE #temp 

		FETCH db_secucfgb INTO @exchangeCode, @secuCode, @repoMaturityValue
		
		 IF @@FETCH_STATUS != 0
       BREAK 
  END 
  
  CLOSE db_secucfgb  
  DEALLOCATE db_secucfgb                            
             
	RETURN 0
END
go

--EXEC sims2016PROC..ipInitRepoCalender

		
