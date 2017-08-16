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
 

/****** Object:  StoredProcedure [dbo].[proc_ProductOrder_ChangePrice_GetOrderInfo]    Script Date: 11/04/2016 10:40:30 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[proc_ProductOrder_ChangePrice_GetOrderInfo]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[proc_ProductOrder_ChangePrice_GetOrderInfo]
GO


/****** Object:  StoredProcedure [dbo].[proc_ProductOrder_ChangePrice_GetOrderInfo]    Script Date: 11/04/2016 10:40:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--cc 2016-8-3 
--�����ļ�ʱ�����������Ż�ȡ������Ϣ
CREATE PROC [dbo].[proc_ProductOrder_ChangePrice_GetOrderInfo]
    @orderCode VARCHAR(100) ,--������,�Ӵ����ﴫ����    
    @sysUserID VARCHAR(50) = '' ,--���ұ��
    @msg VARCHAR(200) OUTPUT--������Ϣ
AS
    BEGIN
    
        BEGIN TRY
    
			-- table0 ����������Ϣ
            SELECT  dbo.ProductOrder.OrderCode ,
                    dbo.ProductOrder.OrderStatus ,  --����״̬��1-δ֧��״̬����ʱ���ܸļ�
                    dbo.ProductOrder.TotalPrice ,
                    ISNULL(dbo.ProductOrder.ActivityID, 0) AS ActivityID ,
                    dbo.ProductOrder.FinalPrice ,
                    ISNULL(proof.Code, '') AS ProofCode ,      --�Ƿ��ϴ�֧��ƾ֤
                    dbo.ProductOrder.PrimaryPayType ,        --֧����ʽ  ��  6-����֧��,
                    ISNULL(( SELECT TOP 1--updated by ldf 11032016  �������ʹ�ý��
                                    PayType3
                             FROM   dbo.ProductOrder_BeforePay_Cache
                             WHERE  OrderCode = @orderCode
                           ), 0.00) AS RebateAmount
            FROM    dbo.ProductOrder
                    LEFT JOIN ( SELECT  *--ƾ֤�Ѿ��ϴ�
                                FROM    dbo.Proof
                                WHERE   ProofUse = 2
                              ) proof ON proof.Code = ProductOrder.OrderCode
            WHERE   OrderCode = @orderCode;
            
			-- table1 ���Ӷ�����Ϣ
            SELECT  dbo.ProductOrder_Detail.OrderCode ,
                    dbo.ProductOrder_Detail.SubOrderCode ,
                    dbo.ProductOrder_Detail.ProCount ,
                    dbo.ProductOrder_Detail.TransFee ,
                    dbo.ProductOrder_Detail.ProPrice , --�����µ�ʱ�ĵ���
                    dbo.ProductOrder_Detail.ProPrice1 ,--�ļۺ�ĵ���
                    dbo.ProductOrder_Detail.SubTotal ,
                    dbo.ProductOrder_Detail.Promotion ,--�id					
                    dbo.ProductOrder_Detail.ProId
            FROM    dbo.ProductOrder_Detail
            WHERE   OrderCode = @orderCode;
            
            -- table2: ���Ϣ
            SELECT  dbo.ProductOrder_Detail.OrderCode ,
                    dbo.ProductOrder_Detail.SubOrderCode ,
                    dbo.ProductOrder_Detail.ProId ,
                    dbo.PromotionProduct.ActivityID ,
                    dbo.PromotionActivity.Discount_Circle ,
                    dbo.PromotionProduct.Discount_Money ,
                    dbo.PromotionActivity.Discount_MinAmount AS Discount_TotalMoney
            FROM    dbo.ProductOrder_Detail
                    INNER JOIN dbo.PromotionProduct ON dbo.ProductOrder_Detail.Promotion = dbo.PromotionProduct.ActivityID
                    INNER JOIN dbo.PromotionActivity ON dbo.PromotionProduct.ActivityID = dbo.PromotionActivity.Id
            WHERE   dbo.ProductOrder_Detail.OrderCode = @orderCode
                    AND dbo.fn_getPromotionActivityStatus(dbo.PromotionProduct.ActivityID) = 1
                    AND dbo.PromotionActivity.ActivityType = 102;

        END TRY 
        BEGIN CATCH 	
            SET @msg = ERROR_MESSAGE();
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
