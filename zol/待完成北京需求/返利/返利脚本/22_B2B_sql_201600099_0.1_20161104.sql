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
--�������userSN�����ҵ�userSN�����ظ���ҿ���ʹ�õ��ܷ������
CREATE PROC [dbo].[proc_MyFinance_Rebate_GetSumRebate]
    @userSN_R VARCHAR(50) ,--���UserSN
    @userSN_S VARCHAR(50) ,--����UserSN    
    @sumRebate DECIMAL(18,2) OUTPUT,  --���ؿ��õĽ��
    @msg VARCHAR(200) OUTPUT--������Ϣ
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
