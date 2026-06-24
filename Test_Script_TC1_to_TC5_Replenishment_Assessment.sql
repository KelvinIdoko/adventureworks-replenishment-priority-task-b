USE AdventureWorks2022;
GO

--TC1
DECLARE @Message NVARCHAR(250);
DECLARE @ReturnCode INT;

EXEC @ReturnCode =
RetailAnalytics.usp_AssessProductReplenishmentPriority
     @ProductID = 707,
     @ProcessingMessage = @Message OUTPUT;

SELECT @ReturnCode, @Message;
GO

--TC2
DECLARE @Message NVARCHAR(250);
DECLARE @ReturnCode INT;

EXEC @ReturnCode =
RetailAnalytics.usp_AssessProductReplenishmentPriority
     @ProductID = NULL,
     @ProcessingMessage = @Message OUTPUT;

SELECT @ReturnCode, @Message;
GO

-- TC3
DECLARE @Message NVARCHAR(250);
DECLARE @ReturnCode INT;

EXEC @ReturnCode =
RetailAnalytics.usp_AssessProductReplenishmentPriority
     @ProductID = 999999,
     @ProcessingMessage = @Message OUTPUT;

SELECT @ReturnCode, @Message;
GO

--TC4
DECLARE @Message NVARCHAR(250);

EXEC RetailAnalytics.usp_AssessProductReplenishmentPriority
     @ProductID = 707,
     @ProcessingMessage = @Message OUTPUT;

SELECT @Message;
GO

-- TC5
DECLARE @Message NVARCHAR(250);
DECLARE @ReturnCode INT;

EXEC @ReturnCode =
RetailAnalytics.usp_AssessProductReplenishmentPriority
     @ProductID = 707,
     @ProcessingMessage = @Message OUTPUT;

SELECT @ReturnCode;
GO