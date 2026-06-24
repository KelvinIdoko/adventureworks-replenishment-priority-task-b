USE AdventureWorks2022;
GO

-- Schema

IF NOT EXISTS
(
    SELECT *
    FROM sys.schemas
    WHERE name = 'RetailAnalytics'
)
BEGIN
    EXEC('CREATE SCHEMA RetailAnalytics');
    PRINT 'Schema RetailAnalytics created successfully.';
END
ELSE
BEGIN
    PRINT 'Schema RetailAnalytics already exists.';
END;
GO

-- Function

IF OBJECT_ID
(
    'RetailAnalytics.ufn_CalculateReplenishmentPriorityScore',
    'FN'
) IS NOT NULL
DROP FUNCTION RetailAnalytics.ufn_CalculateReplenishmentPriorityScore;
GO


CREATE FUNCTION RetailAnalytics.ufn_CalculateReplenishmentPriorityScore
(
      @SafetyStockLevel SMALLINT
    , @ReorderPoint SMALLINT
    , @DaysToManufacture INT
    , @FinishedGoodsFlag BIT
    , @MakeFlag BIT
)
RETURNS INT
AS
BEGIN
    DECLARE @StockBuffer INT;
    DECLARE @StockBufferScore INT;
    DECLARE @LeadScore INT;
    DECLARE @ProductTypeScore INT;
    DECLARE @TotalScore INT;

    SET @StockBuffer = @SafetyStockLevel - @ReorderPoint;

    SET @StockBufferScore =
        CASE
            WHEN @StockBuffer <= 0 THEN 45
            WHEN @StockBuffer BETWEEN 1 AND 100 THEN 30
            ELSE 10
        END;

    SET @LeadScore =
        CASE
            WHEN @DaysToManufacture >= 4 THEN 30
            WHEN @DaysToManufacture BETWEEN 2 AND 3 THEN 20
            ELSE 10
        END;

    SET @ProductTypeScore =
        CASE
            WHEN @FinishedGoodsFlag = 1
                 AND @MakeFlag = 1
                 THEN 25
            WHEN @FinishedGoodsFlag = 1
                 AND @MakeFlag = 0
                 THEN 15
            ELSE 5
        END;

    SET @TotalScore =
          @StockBufferScore
        + @LeadScore
        + @ProductTypeScore;

    RETURN @TotalScore;
END;
GO

-- Stored Procedure

IF OBJECT_ID('RetailAnalytics.usp_AssessProductReplenishmentPriority', 'P') IS NOT NULL
DROP PROCEDURE RetailAnalytics.usp_AssessProductReplenishmentPriority;
GO

CREATE PROCEDURE RetailAnalytics.usp_AssessProductReplenishmentPriority
(
      @ProductID INT
    , @ProcessingMessage NVARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @ProductID IS NULL
        BEGIN
            SET @ProcessingMessage =
                'ProductID cannot be NULL.';
            RETURN -1;
        END

        IF NOT EXISTS
        (
            SELECT 1
            FROM Production.Product
            WHERE ProductID = @ProductID
        )
        BEGIN
            SET @ProcessingMessage =
                'Product does not exist.';
            RETURN -2;
        END

        DECLARE
              @ProductName NVARCHAR(100)
            , @SafetyStockLevel SMALLINT
            , @ReorderPoint SMALLINT
            , @DaysToManufacture INT
            , @SellStartDate DATETIME
            , @SellEndDate DATETIME
            , @FinishedGoodsFlag BIT
            , @MakeFlag BIT;

        SELECT
              @ProductName = Name
            , @SafetyStockLevel = SafetyStockLevel
            , @ReorderPoint = ReorderPoint
            , @DaysToManufacture = DaysToManufacture
            , @SellStartDate = SellStartDate
            , @SellEndDate = SellEndDate
            , @FinishedGoodsFlag = FinishedGoodsFlag
            , @MakeFlag = MakeFlag
        FROM Production.Product
        WHERE ProductID = @ProductID;

        IF @SafetyStockLevel IS NULL
           OR @ReorderPoint IS NULL
           OR @SafetyStockLevel < 0
           OR @ReorderPoint < 0
        BEGIN
            SET @ProcessingMessage =
                'Invalid inventory limits.';
            RETURN -3;
        END

        IF @SellStartDate IS NULL
        BEGIN
            SET @ProcessingMessage =
                'Product is not currently sellable.';
            RETURN -4;
        END

        DECLARE @PriorityScore INT;

        SET @PriorityScore =
        RetailAnalytics.ufn_CalculateReplenishmentPriorityScore
        (
              @SafetyStockLevel
            , @ReorderPoint
            , @DaysToManufacture
            , @FinishedGoodsFlag
            , @MakeFlag
        );

        DECLARE @Priority NVARCHAR(50);

        IF @SellEndDate IS NOT NULL
           AND @SellEndDate < GETDATE()
        BEGIN
            SET @Priority = 'No Immediate Action';

            SET @ProcessingMessage =
                'Product is no longer available for sale.';
        END
        ELSE IF @PriorityScore >= 80
        BEGIN
            SET @Priority = 'Urgent Replenishment';

            SET @ProcessingMessage =
                'Urgent replenishment required.';
        END
        ELSE IF @PriorityScore BETWEEN 50 AND 79
        BEGIN
            SET @Priority = 'Monitor Closely';

            SET @ProcessingMessage =
                'Monitor inventory levels closely.';
        END
        ELSE
        BEGIN
            SET @Priority = 'No Immediate Action';

            SET @ProcessingMessage =
                'No action required at this time.';
        END

        -- Result Set
        SELECT
              @ProductID AS ProductID
            , @ProductName AS ProductName
            , @SafetyStockLevel AS SafetyStockLevel
            , @ReorderPoint AS ReorderPoint
            , @DaysToManufacture AS DaysToManufacture
            , @SellStartDate AS SellStartDate
            , @SellEndDate AS SellEndDate
            , @FinishedGoodsFlag AS FinishedGoodsFlag
            , @MakeFlag AS MakeFlag
            , @PriorityScore AS ReplenishmentPriorityScore
            , @Priority AS ReplenishmentPriority
            , 'Success' AS ProcessingStatus
            , @ProcessingMessage AS ProcessingMessage;
        RETURN 0;

    END TRY

    BEGIN CATCH
        SET @ProcessingMessage =
            ERROR_MESSAGE();

        RETURN -99;
    END CATCH
END;
GO

-- Output
DECLARE @Message NVARCHAR(250);
DECLARE @ReturnCode INT;

EXEC @ReturnCode =
RetailAnalytics.usp_AssessProductReplenishmentPriority
     @ProductID = 707,
     @ProcessingMessage = @Message OUTPUT;

SELECT @ReturnCode AS ReturnCode, @Message AS Message;