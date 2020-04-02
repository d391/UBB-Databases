CREATE TABLE Beverage(BID INT PRIMARY KEY, Name VARCHAR(20), Concentration INT)
CREATE TABLE BeverageSize(BSID INT PRIMARY KEY, Name VARCHAR(20))
CREATE TABLE CurrentOrder(BID INT, BSID INT, Price INT, PRIMARY KEY (BID, BSID))
CREATE TABLE Orders(OID INT PRIMARY KEY, Price DECIMAL(10,2))
CREATE TABLE OrderContent(OID INT FOREIGN KEY REFERENCES Orders(OID), BID INT FOREIGN KEY REFERENCES Beverage(BID), Quantity INT, PRIMARY KEY(OID, BID))
DROP TABLE CurrentOrder

GO

CREATE VIEW vBeverages
AS
	SELECT*
	FROM Beverage 

GO

CREATE VIEW vOrderDetails
AS
	SELECT B.Name AS 'Beverage Name', BS.Name AS 'Beverage Size', CO.Price
	FROM Beverage B INNER JOIN CurrentOrder CO ON B.BID = CO.BID INNER JOIN BeverageSize BS ON CO.BSID = BS.BSID

GO

CREATE VIEW vMostOrderedBeverages
AS
	SELECT*
	FROM Beverage B
	WHERE B.BID = ANY (SELECT OC.BID 
					FROM OrderContent OC
					GROUP BY OC.BID
					HAVING SUM(OC.Quantity) = (SELECT MAX(A.TotalQuantity)
												FROM (SELECT SUM(OC1.Quantity) AS 'TotalQuantity'
														FROM OrderContent OC1
														GROUP BY OC1.BID) A))
GO

SELECT*
FROM sys.all_views
WHERE type = 'U' AND name != 'sysdiagrams'

GO

CREATE OR ALTER PROCEDURE populateTables
AS
	INSERT Tables
	SELECT T.name
	FROM sys.objects T
	WHERE type = 'U' AND name != 'sysdiagrams'
GO

EXEC populateTables

SELECT*
FROM Tables

GO

CREATE OR ALTER PROCEDURE populateViews
AS
	INSERT Views
	SELECT T.name
	FROM sys.all_views T
	WHERE object_id > 0
GO

EXEC populateViews

SELECT*
FROM Views

GO

CREATE OR ALTER PROCEDURE createTest @table1 VARCHAR(30), @noRows1 INT, @table2 VARCHAR(30), @noRows2 INT, @table3 VARCHAR(30), @noRows3 INT, @View VARCHAR(30)
AS 
	DECLARE @testId INT
	DECLARE @testName VARCHAR(20)
	SET @testName = CONCAT('Test', @testId)

	INSERT INTO Tests VALUES(@testName)
	SET @testId = (SELECT MAX(T.TestID) FROM Tests T)

	DECLARE @id INT
	SET @id = (SELECT T.TableID FROM Tables T WHERE T.Name = @table1)
	INSERT INTO TestTables VALUES(@testId, @id, @noRows1, 1)
	SET @id = (SELECT T.TableID FROM Tables T WHERE T.Name = @table2)
	INSERT INTO TestTables VALUES(@testId, @id, @noRows2, 2)
	SET @id = (SELECT T.TableID FROM Tables T WHERE T.Name = @table3)
	INSERT INTO TestTables VALUES(@testId, @id, @noRows3, 3)

	SET @id = (SELECT W.ViewID FROM Views W WHERE W.Name = @View)
	INSERT INTO TestViews VALUES(@testId, @id)

	DECLARE @deleteTable VARCHAR(40)
	DECLARE @currentTable INT
	DECLARE @tableName VARCHAR(20)

	SET @currentTable = 1

	WHILE @currentTable <= 3
	BEGIN
		SET @tableName = (SELECT T.Name FROM Tables T WHERE T.TableID = (SELECT TT.TableID FROM TestTables TT WHERE TT.Position = @currentTable AND TT.TestID = @testId))
		SELECT @tableName
		SET @deleteTable = 'DELETE FROM ' + @tableName
		SELECT @deleteTable
		EXEC (@deleteTable)
		SET @currentTable = @currentTable +1
	END

	DECLARE @startDate DATETIME
	DECLARE @endDate DATETIME
	DECLARE @startDateTest DATETIME
	DECLARE @endDateTest DATETIME
	SET @startDateTest = GETDATE()
	SET @currentTable = 3

	INSERT INTO TestRuns VALUES('INSERT', @startDateTest, @endDateTest)
	WHILE @currentTable >= 1
	BEGIN
		
		SET @tableName = (SELECT T.Name FROM Tables T WHERE T.TableID = (SELECT TT.TableID FROM TestTables TT WHERE TT.Position = @currentTable AND TT.TestID = @testId))
		PRINT @tableName
		DECLARE @noRows INT
		SET @noRows = (SELECT TT.NoOfRows FROM TestTables TT WHERE TT.Position = @currentTable AND TT.TestID = @testId)

		DECLARE @currentRow INT
		SET @currentRow = 1

		SET @startDate = GETDATE()

		WHILE @currentRow <= @noRows
		BEGIN

			DECLARE @insertValue VARCHAR(100)
			SET @insertValue = CONCAT('INSERT INTO ', @tableName, ' VALUES(')

			DECLARE @currentCol INT
			SET @currentCol = 1
			DECLARE @noCols INT
			SET @noCols = (SELECT COUNT(*)
				FROM sys.objects O INNER JOIN sys.columns C on O.object_id = C.object_id
				INNER JOIN sys.types T ON C.system_type_id = T.system_type_id
				WHERE O.name = @tableName)

			DECLARE @type VARCHAR(10)
			DECLARE insertCursor CURSOR FOR
				SELECT T.name
				FROM sys.objects O INNER JOIN sys.columns C on O.object_id = C.object_id
				INNER JOIN sys.types T ON C.system_type_id = T.system_type_id
				WHERE O.name = @tableName
				ORDER BY C.column_id
			OPEN insertCursor
			FETCH NEXT FROM insertCursor INTO @type
			WHILE @@FETCH_STATUS = 0
			BEGIN
				DECLARE @generatedInt INT
				DECLARE @generatedChar VARCHAR(10)

				SET @generatedInt = rand()*100000
				SET @generatedChar = (SELECT REPLICATE('a', 10))

				IF @type = 'int'
					SET @insertValue = @insertValue + CAST(@generatedInt AS VARCHAR(5))
				ELSE
					SET @insertValue = @insertValue + '''' + @generatedChar + ''''
					print '@insertvalue = ' + @insertvalue
				IF @currentCol = @noCols
					SET @insertValue = @insertValue + ')'
				ELSE
					SET @insertValue = @insertValue + ', '

				SET @currentCol = @currentCol +1

				FETCH NEXT FROM insertCursor INTO @type
				
			END
			CLOSE insertCursor
			DEALLOCATE insertCursor
			print '@insertvalue = ' + @insertvalue

			EXEC (@insertValue)
			SET @currentRow = @currentRow + 1
		END

		SET @endDate = GETDATE()

		SET @id = (SELECT MAX(T.TestRunID) FROM TestRuns T)
		DECLARE @tableId INT
		SET @tableId = (SELECT T.TableID FROM Tables T WHERE T.Name = @tableName)
		INSERT INTO TestRunTables VALUES(@id, @tableId, @startDate, @endDate)

		SET @currentTable = @currentTable-1
	END

	SET @endDateTest = GETDATE()
	SET @id = (SELECT MAX(T.TestRunID) FROM TestRuns T)
	UPDATE TestRuns SET EndAt = @endDateTest WHERE TestRunID = @id

	DECLARE @runView VARCHAR(50)
	SET @runView = 'SELECT* FROM ' + @View

	SET @startDate = GETDATE()
	EXEC (@runView)

	SET @endDate = GETDATE()

	INSERT INTO TestRuns VALUES('VIEW', @startDate, @endDate)
	SET @id = (SELECT MAX(T.TestRunID) FROM TestRuns T)
	DECLARE @viewId INT
	SET @viewId = (SELECT W.ViewID FROM Views W WHERE w.Name = @View)
	INSERT INTO TestRunViews VALUES(@id, @viewId, @startDate, @endDate)

GO

EXEC createTest 'CurrentOrder', 50, 'BeverageSize', 50, 'Beverage', 50, 'vMostOrderedBeverages'

SELECT COUNT(*)
FROM Beverage B

SELECT COUNT(*)
FROM BeverageSize

SELECT COUNT(*)
FROM CurrentOrder

SELECT* FROM TestTables
SELECT* FROM Tests
SELECT* FROM TestViews

SELECT* FROM TestRuns
SELECT* FROM TestRunTables
SELECT* FROM TestRunViews

DELETE FROM TestTables
DELETE FROM Tests
DELETE FROM TestRuns
DELETE FROM TestRunTables
DELETE FROM TestViews
DELETE FROM TestRunViews
