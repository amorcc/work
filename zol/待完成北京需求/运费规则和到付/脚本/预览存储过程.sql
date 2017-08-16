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

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

--==========================================
-- Author:		cc
-- Create date: 2016-7-26
-- Description: ����Ԥ���߼��ж�������ȡ
-- =============================================
ALTER PROCEDURE [dbo].[proc_ProductOrder_PreviewData]
    @proIds VARCHAR(MAX) ,--��Ʒ������� :  100056|2|77,100226|3|77,100142|4|0
    @systemUserId INT ,  --���userId
    @userSN_R VARCHAR(20) ,--���userSN
    @msg VARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;
        
        BEGIN TRY
            DECLARE @tbl TABLE
                (
                  ProId INT ,
                  ProCount INT ,
                  ActivityId INT
                );
    
            INSERT  INTO @tbl
                    ( ProId ,
                      ProCount ,
                      ActivityId
                    )
                    SELECT  dbo.fn_getItemInArray(F1, '|', 1) ,
                            dbo.fn_getItemInArray(F1, '|', 2) ,
                            dbo.fn_getItemInArray(F1, '|', 3)
                    FROM    dbo.f_splitstr(@proIds, ',');   
			 
			
			--��Ʒ��Ϣ
            SELECT  dbo.v_Product.ProId ,
                    dbo.v_Product.Name ,
                    dbo.v_Product.Image ,
                    ISNULL(dbo.v_Product.Price, 0) AS Price ,
                    a.ActivityId ,
                    dbo.v_Product.UserSN AS UserSN_S ,
                    dbo.v_Product.CompanyName AS SupplierName ,
                    ISNULL(dbo.v_Product.MaxPerCount, 0) AS MaxPerCount ,
                    ISNULL(dbo.v_Product.MinPerCount, 0) AS MinPerCount ,
                    ISNULL(dbo.v_Product.Amount, 0) AS Amount ,
                    a.ProCount ,
                    dbo.v_Product.TemplateCode ,
                    dbo.v_Product.BillNeeded ,
					--����                                              
                    ISNULL(dbo.SupplierCategory.Rate, 0) AS Rate 
            FROM    dbo.v_Product
                    INNER JOIN @tbl a ON a.ProId = dbo.v_Product.ProId
                    LEFT JOIN dbo.SupplierCategory ON dbo.v_Product.CodeLevel1 = dbo.SupplierCategory.CategoryCode
                                                      AND dbo.v_Product.UserSN = dbo.SupplierCategory.SupplierUserSN;

			--------------------------------------------        
			--���Ϣ        
            SELECT  --�������۶���̨
                    ( SELECT    ISNULL(SUM(ProCount), 0)
                      FROM      dbo.ProductOrder
                                INNER JOIN dbo.ProductOrder_Detail ON dbo.ProductOrder.OrderCode = dbo.ProductOrder_Detail.OrderCode
                      WHERE     OrderStatus > 1
                                AND ProId = a.ProId
                                AND Promotion = a.ActivityID
                                AND DATEDIFF(DAY, dbo.ProductOrder.DateAdded,
                                             GETDATE()) = 0
                    ) TodaySaleNum ,
                    dbo.PromotionProduct.ActivityID ,
                    dbo.PromotionProduct.ProId ,
					--��������̨
                    ISNULL(dbo.PromotionActivity.OnLineAmount, 0) AS OnlineAmount ,
					--�����۶���̨
                    ISNULL(dbo.PromotionProduct.SaledAmount, 0) AS SaledAmount ,
					--ÿ���������޶���̨
                    ISNULL(dbo.PromotionActivity.AmountPerDay, 0) AS AmountPerDay ,
					--��͹�������
                    ISNULL(dbo.PromotionActivity.RetailerLimit_LeastBuyAmount,
                           0) AS MinBuyNum ,
					--���������
                    ISNULL(dbo.PromotionActivity.RetailerLimit_BuyAmount, 0) AS MaxBuyNum ,
                    --�����
                    dbo.PromotionActivity.ActivityType ,
                    dbo.PromotionActivity.SubsidyType ,
                    dbo.PromotionActivity.Factor4Subsidy,
                    --�������ܼ۴ﵽ����
                    ISNULL(dbo.PromotionActivity.Discount_MinAmount, 0) AS Discount_TotalMoney ,
                    --������������
                    ISNULL(dbo.PromotionActivity.Discount_Money, 0) AS Discount_Money ,
                    --�����Ƿ�ѭ��
                    ISNULL(dbo.PromotionActivity.Discount_Circle, 0) AS Discount_Circle ,
                    --�����ĵ�λ��0-�����������1-��̨����
                    ISNULL(dbo.PromotionActivity.Discount_Type, 0) AS Discount_Type,
                    --ÿID�޹�����
                    dbo.PromotionActivity.RetailerLimit_BuyAmount
            FROM    dbo.PromotionProduct
                    INNER JOIN @tbl a ON a.ActivityId = dbo.PromotionProduct.ActivityID
                                         AND a.ProId = dbo.PromotionProduct.ProId
                    LEFT JOIN dbo.PromotionActivity ON dbo.PromotionProduct.ActivityID = dbo.PromotionActivity.Id 
							AND dbo.fn_getPromotionActivity_Status(dbo.PromotionActivity.Id,dbo.PromotionActivity.Status) = 5;

			-------------------------------------------------------
			--�����ҵĹ�����Ϣ
            SELECT  a.ProId ,
					--�id	
                    dbo.ProductOrder_Detail.Promotion AS ActivityID ,
					--�����ҹ����˶���
                    ISNULL(SUM(ProductOrder_Detail.ProCount), 0) AS MyBuyNum
            FROM    dbo.ProductOrder
                    INNER JOIN dbo.ProductOrder_Detail ON dbo.ProductOrder.OrderCode = dbo.ProductOrder_Detail.OrderCode
                    INNER JOIN @tbl a ON a.ProId = ProductOrder_Detail.ProId
            WHERE   OrderStatus > 1
                    AND ProductOrder_Detail.ProId = a.ProId
                    AND ProductOrder.UserSN_R = @userSN_R
                    AND DATEDIFF(DAY, dbo.ProductOrder.DateAdded, GETDATE()) = 0
            GROUP BY a.ProId ,
                    dbo.ProductOrder_Detail.Promotion;
              
			-------------------------------------------------------
			--��id�������
			--cc  2016-10-28  add
			SELECT  a.ProId ,
					--�id	
                    dbo.ProductOrder_Detail.Promotion AS ActivityID ,
					--���ܹ������˶���
                    ISNULL(SUM(ProductOrder_Detail.ProCount), 0) AS MyBuyNumSum
            FROM    dbo.ProductOrder
                    INNER JOIN dbo.ProductOrder_Detail ON dbo.ProductOrder.OrderCode = dbo.ProductOrder_Detail.OrderCode
                    INNER JOIN @tbl a ON a.ProId = ProductOrder_Detail.ProId
            WHERE   OrderStatus > 0
                    AND ProductOrder_Detail.ProId = a.ProId
                    AND ProductOrder.UserSN_R = @userSN_R                  
            GROUP BY a.ProId ,
                    dbo.ProductOrder_Detail.Promotion;
                    
        END TRY 
        BEGIN CATCH 	
            SET @msg = dbo.fn_sys_error(ERROR_MESSAGE());
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
