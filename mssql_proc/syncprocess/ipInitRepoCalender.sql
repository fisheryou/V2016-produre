

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
  tradeDate                 VARCHAR(10), -- 首次清算日
  exchangeCode              VARCHAR(4),  -- 交易所代码
  secuCode                  VARCHAR(10), -- 证券代码
  expireClearDate           VARCHAR(10), -- 到期清算日
  expireSettleDate          VARCHAR(10), -- 首次资金交收日
  actualExpireSettleDate    VARCHAR(10), -- 到期资金交收日
  repoMaturityValue         NUMERIC(10,0), -- 购回天数
  actualRepoMaturityValue   NUMERIC(10,0), -- 实际占款天数
	)
BEGIN

 --游标变量begin
  DECLARE
    @exchangeCode                         VARCHAR(10)       ,--交易所代码
    @secuCode                             VARCHAR(10)       ,--证券代码
    @repoMaturityValue                          INT                --购回天数
    
  SELECT a.exchangeCode,a.tradeDate, 
  --取下一个交易日
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
		  
		--取到期资金交收日
		UPDATE a SET actualExpireSettleDate = ISNULL(b.nextTradeDate,'') FROM #temp a, #tradeCalender b WHERE a.exchangeCode = b.exchangeCode AND a.expireClearDate = b.tradeDate 
		--计算实际占款天数
		UPDATE a SET actualRepoMaturityValue = DATEDIFF(DAY, ISNULL(a.expireSettleDate,''), ISNULL(a.actualExpireSettleDate,'')) FROM #temp a 

		INSERT INTO sims2016TradeToday..repoCalender(
                                                 tradeDate,                        -- 首次清算日
                                                 exchangeCode,                     -- 交易所代码
                                                 secuCode,                         -- 证券代码
                                                 expireClearDate,                  -- 到期清算日
                                                 expireSettleDate,                 -- 首次资金交收日
                                                 actualExpireSettleDate,           -- 到期资金交收日
                                                 repoMaturityValue,                -- 购回天数
                                                 actualRepoMaturityValue,          -- 实际占款天数
                                                 operatorCode,                     -- 操作员代码
                                                 operateDatetime                   -- 操作日期时间
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

		
