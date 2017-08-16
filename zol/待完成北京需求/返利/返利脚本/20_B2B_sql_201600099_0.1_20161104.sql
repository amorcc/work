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
--订单改价时根据主订单号获取订单信息
CREATE PROC [dbo].[proc_ProductOrder_ChangePrice_GetOrderInfo]
    @orderCode VARCHAR(100) ,--订单号,从代码里传过来    
    @sysUserID VARCHAR(50) = '' ,--卖家编号
    @msg VARCHAR(200) OUTPUT--返回消息
AS
    BEGIN
    
        BEGIN TRY
    
			-- table0 ：主订单信息
            SELECT  dbo.ProductOrder.OrderCode ,
                    dbo.ProductOrder.OrderStatus ,  --订单状态：1-未支付状态，此时才能改价
                    dbo.ProductOrder.TotalPrice ,
                    ISNULL(dbo.ProductOrder.ActivityID, 0) AS ActivityID ,
                    dbo.ProductOrder.FinalPrice ,
                    ISNULL(proof.Code, '') AS ProofCode ,      --是否上传支付凭证
                    dbo.ProductOrder.PrimaryPayType ,        --支付方式  ：  6-线下支付,
                    ISNULL(( SELECT TOP 1--updated by ldf 11032016  输出返利使用金额
                                    PayType3
                             FROM   dbo.ProductOrder_BeforePay_Cache
                             WHERE  OrderCode = @orderCode
                           ), 0.00) AS RebateAmount
            FROM    dbo.ProductOrder
                    LEFT JOIN ( SELECT  *--凭证已经上传
                                FROM    dbo.Proof
                                WHERE   ProofUse = 2
                              ) proof ON proof.Code = ProductOrder.OrderCode
            WHERE   OrderCode = @orderCode;
            
			-- table1 ：子订单信息
            SELECT  dbo.ProductOrder_Detail.OrderCode ,
                    dbo.ProductOrder_Detail.SubOrderCode ,
                    dbo.ProductOrder_Detail.ProCount ,
                    dbo.ProductOrder_Detail.TransFee ,
                    dbo.ProductOrder_Detail.ProPrice , --订单下单时的单价
                    dbo.ProductOrder_Detail.ProPrice1 ,--改价后的单价
                    dbo.ProductOrder_Detail.SubTotal ,
                    dbo.ProductOrder_Detail.Promotion ,--活动id					
                    dbo.ProductOrder_Detail.ProId
            FROM    dbo.ProductOrder_Detail
            WHERE   OrderCode = @orderCode;
            
            -- table2: 活动信息
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
