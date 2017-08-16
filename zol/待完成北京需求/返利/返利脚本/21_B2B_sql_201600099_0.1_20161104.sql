--1.�ű�Ӧ�ÿ����ظ�����
--2.�ű�����ʧ��,��Ӧ�����κ����й����е�ִ�н��,Ҳ����,�ű�����ʧ��,���ݿ�Ӧ���Ǵ������нű�ǰ������״̬
--3.�ű�Ӧ�ñ������»����ṹ
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
PRINT N'�ҿ�ʼ�ɻ���!';
GO
----------------�ɻ� ��ʼ-----------------------
--��д�ű�����----------------------------------

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
--�������õĶ�������ʹ�ñ���
CREATE PROC [dbo].[proc_MyFinance_Rebate_GetSupplierRebateRate]
    @userSN_S VARCHAR(50) ,--����UserSN    
    @rebateRate INT OUTPUT ,  --���ر���
    @msg VARCHAR(200) OUTPUT--������Ϣ
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




----------------�ɻ� ����----------------------- 
GO
IF ( @@ERROR <> 0 )
    AND ( @@TRANCOUNT > 0 )
    BEGIN
        PRINT '������������,û�ɳ�!';
        ROLLBACK TRANSACTION;
    END;	
GO
IF @@TRANCOUNT > 0
    BEGIN
        PRINT '�����չ�!';
        COMMIT TRANSACTION;
    END;
GO

PRINT 'Script�������!';
GO
