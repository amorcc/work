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

/****** Object:  StoredProcedure [dbo].[proc_MyFinance_Rebate_GetSupplierRebateRate]    Script Date: 11/04/2016 10:40:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[proc_MyFinance_Rebate_GetSupplierRebateRate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[proc_MyFinance_Rebate_GetSupplierRebateRate]
GO


/****** Object:  StoredProcedure [dbo].[proc_MyFinance_Rebate_GetSupplierRebateRate]    Script Date: 11/04/2016 10:40:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--cc  2016-11-3
--卖家设置的订单返利使用比例
CREATE PROC [dbo].[proc_MyFinance_Rebate_GetSupplierRebateRate]
    @userSN_S VARCHAR(50) ,--卖家UserSN    
    @rebateRate INT OUTPUT ,  --返回比例
    @msg VARCHAR(200) OUTPUT--返回消息
AS 
    BEGIN
		
        BEGIN TRY 
            SET @rebateRate = 0;
            SELECT TOP 1
                    @rebateRate = ISNULL(dbo.MyFinance_Rebate_Config.Rate, 0)
            FROM    dbo.MyFinance_Rebate_Config
            WHERE   dbo.MyFinance_Rebate_Config.UserSN_S = @userSN_S
            ORDER BY DateAdded DESC;
           
           
                                                    
        END TRY 
        BEGIN CATCH 	
            SET @msg = ERROR_MESSAGE();
            SET @rebateRate = 0;
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
