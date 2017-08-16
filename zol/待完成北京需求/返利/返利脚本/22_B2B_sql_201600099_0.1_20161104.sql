--1.脚本应该可以重复运行
--2.脚本运行失败,不应遗留任何运行过程中的执行结果,也就是,脚本运行失败,数据库应该是处于运行脚本前的正常状态
--3.脚本应该保持如下基本结构
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
GO
SET NUMERIC_ROUNDABORT OFF;
GO
SET XACT_ABORT ON;
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO
BEGIN TRANSACTION;
GO
PRINT N'我开始干活了!';
GO
----------------干活 开始-----------------------
--书写脚本区域----------------------------------

/****** Object:  StoredProcedure [dbo].[proc_MyFinance_Rebate_GetSumRebate]    Script Date: 11/04/2016 10:41:28 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[proc_MyFinance_Rebate_GetSumRebate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[proc_MyFinance_Rebate_GetSumRebate]
GO


/****** Object:  StoredProcedure [dbo].[proc_MyFinance_Rebate_GetSumRebate]    Script Date: 11/04/2016 10:41:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--cc  2016-11-3
--根据买家userSN和卖家的userSN，返回该买家可以使用的总返利金额
CREATE PROC [dbo].[proc_MyFinance_Rebate_GetSumRebate]
    @userSN_R VARCHAR(50) ,--买家UserSN
    @userSN_S VARCHAR(50) ,--卖家UserSN    
    @sumRebate DECIMAL(18,2) OUTPUT,  --返回可用的金额
    @msg VARCHAR(200) OUTPUT--返回消息
AS 
    BEGIN
		
        BEGIN TRY 
            --DECLARE @sumRebate DECIMAL(18, 2);
            SET @sumRebate = 0;
            
            DECLARE @sum1 DECIMAL(18,2);
            SET @sum1 = 0;
            
            DECLARE @sum2 DECIMAL(18,2);
            SET @sum2 = 0;
            
            SELECT @sum1 = ISNULL(SUM(Amount),0)
            FROM dbo.MyFinance_Rebate
            WHERE dbo.MyFinance_Rebate.UserSN_R = @userSN_R
				AND dbo.MyFinance_Rebate.UserSN_S = @userSN_S
				AND Status = 1;
				
			SELECT @sum2 = ISNULL(SUM(Amount),0)
			FROM dbo.MyFinance_Rebate_Details
			WHERE dbo.MyFinance_Rebate_Details.UserSN_R = @userSN_R
			AND dbo.MyFinance_Rebate_Details.UserSN_S = @userSN_S;
			
			SET @sumRebate = @sum1+@sum2;
                                                    
        END TRY 
        BEGIN CATCH 	
            SET @msg = ERROR_MESSAGE();
            SET @sumRebate = 0;
        END CATCH;	
    
    
        SET NOCOUNT OFF;
    END;



GO




----------------干活 结束----------------------- 
GO
IF ( @@ERROR <> 0 )
    AND ( @@TRANCOUNT > 0 )
    BEGIN
        PRINT '这个活儿有问题,没干成!';
        ROLLBACK TRANSACTION;
    END;	
GO
IF @@TRANCOUNT > 0
    BEGIN
        PRINT '干完收工!';
        COMMIT TRANSACTION;
    END;
GO

PRINT 'Script运行完成!';
GO
