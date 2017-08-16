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

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

--==========================================
-- Author:		cc
-- Create date: 2016-7-26
-- Description: 订单预览逻辑判断数据提取
-- =============================================
ALTER PROCEDURE [dbo].[proc_ProductOrder_PreviewData]
    @proIds VARCHAR(MAX) ,--产品订单多个 :  100056|2|77,100226|3|77,100142|4|0
    @systemUserId INT ,  --买家userId
    @userSN_R VARCHAR(20) ,--买家userSN
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
			 
			
			--商品信息
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
					--费率                                              
                    ISNULL(dbo.SupplierCategory.Rate, 0) AS Rate 
            FROM    dbo.v_Product
                    INNER JOIN @tbl a ON a.ProId = dbo.v_Product.ProId
                    LEFT JOIN dbo.SupplierCategory ON dbo.v_Product.CodeLevel1 = dbo.SupplierCategory.CategoryCode
                                                      AND dbo.v_Product.UserSN = dbo.SupplierCategory.SupplierUserSN;

			--------------------------------------------        
			--活动信息        
            SELECT  --今日销售多少台
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
					--总量多少台
                    ISNULL(dbo.PromotionActivity.OnLineAmount, 0) AS OnlineAmount ,
					--已销售多少台
                    ISNULL(dbo.PromotionProduct.SaledAmount, 0) AS SaledAmount ,
					--每天销售上限多少台
                    ISNULL(dbo.PromotionActivity.AmountPerDay, 0) AS AmountPerDay ,
					--最低购买数量
                    ISNULL(dbo.PromotionActivity.RetailerLimit_LeastBuyAmount,
                           0) AS MinBuyNum ,
					--最大购买数量
                    ISNULL(dbo.PromotionActivity.RetailerLimit_BuyAmount, 0) AS MaxBuyNum ,
                    --活动类型
                    dbo.PromotionActivity.ActivityType ,
                    dbo.PromotionActivity.SubsidyType ,
                    dbo.PromotionActivity.Factor4Subsidy,
                    --满减：总价达到多少
                    ISNULL(dbo.PromotionActivity.Discount_MinAmount, 0) AS Discount_TotalMoney ,
                    --满减：减多少
                    ISNULL(dbo.PromotionActivity.Discount_Money, 0) AS Discount_Money ,
                    --满减是否循环
                    ISNULL(dbo.PromotionActivity.Discount_Circle, 0) AS Discount_Circle ,
                    --满减的单位：0-按金额满减，1-按台满减
                    ISNULL(dbo.PromotionActivity.Discount_Type, 0) AS Discount_Type,
                    --每ID限购数量
                    dbo.PromotionActivity.RetailerLimit_BuyAmount
            FROM    dbo.PromotionProduct
                    INNER JOIN @tbl a ON a.ActivityId = dbo.PromotionProduct.ActivityID
                                         AND a.ProId = dbo.PromotionProduct.ProId
                    LEFT JOIN dbo.PromotionActivity ON dbo.PromotionProduct.ActivityID = dbo.PromotionActivity.Id 
							AND dbo.fn_getPromotionActivity_Status(dbo.PromotionActivity.Id,dbo.PromotionActivity.Status) = 5;

			-------------------------------------------------------
			--今日我的购买信息
            SELECT  a.ProId ,
					--活动id	
                    dbo.ProductOrder_Detail.Promotion AS ActivityID ,
					--今日我购买了多少
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
			--本id活动购买量
			--cc  2016-10-28  add
			SELECT  a.ProId ,
					--活动id	
                    dbo.ProductOrder_Detail.Promotion AS ActivityID ,
					--我总共购买了多少
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
