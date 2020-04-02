CREATE OR ALTER PROCEDURE USP_ModifyBeverageColumnTypeChar
AS
	ALTER TABLE Beverage
	ALTER COLUMN Concentration VARCHAR(5)
GO

CREATE OR ALTER PROCEDURE USP_ModifyBeverageColumnTypeInt
AS
	ALTER TABLE Beverage
	ALTER COLUMN Concentration INT
GO

-----
EXEC USP_ModifyBeverageColumnTypeChar
EXEC USP_ModifyBeverageColumnTypeInt
----
GO

CREATE OR ALTER PROCEDURE USP_DeleteEmployeeHireDateColumn
AS
	ALTER TABLE Employee
	DROP COLUMN Date_of_hire
GO

CREATE OR ALTER PROCEDURE USP_AddEmployeeHireDateColumn
AS
	ALTER TABLE Employee
	ADD Date_of_hire DATE
GO

----
EXEC USP_DeleteEmployeeHireDateColumn
EXEC USP_AddEmployeeHireDateColumn
----

GO

CREATE OR ALTER PROCEDURE USP_AddDefaultClientFidPoints
AS
	ALTER TABLE Client
	ADD CONSTRAINT df_Fidelity_points DEFAULT 0 FOR Fidelity_points
GO

CREATE OR ALTER PROCEDURE USP_RemoveDefaultClientFidPoints
AS
	ALTER TABLE Client
	DROP CONSTRAINT df_Fidelity_points
GO

----
EXEC USP_AddDefaultClientFidPoints
EXEC USP_RemoveDefaultClientFidPoints
----

GO

CREATE OR ALTER PROCEDURE USP_RemovePKShift
AS
	ALTER TABLE Shift
	DROP CONSTRAINT PK_SID

	ALTER TABLE Shift
	ADD CONSTRAINT pk_type_time_day PRIMARY KEY (Type, Time_interval, Day);
GO

CREATE OR ALTER PROCEDURE USP_AddPKShift
AS
	ALTER TABLE Shift
	DROP CONSTRAINT pk_type_time_day

	ALTER TABLE Shift
	ADD CONSTRAINT PK_SID PRIMARY KEY (SID)
GO

----
EXEC USP_RemovePKShift
EXEC USP_AddPKShift
----

GO

CREATE OR ALTER PROCEDURE USP_RemoveCKIngredient
AS
	ALTER TABLE Ingredient
	DROP CONSTRAINT uk_Ingredient
GO

CREATE OR ALTER PROCEDURE USP_AddCKIngredient
AS
	ALTER TABLE Ingredient
	ADD CONSTRAINT uk_Ingredient UNIQUE(Name)
GO

----
EXEC USP_RemoveCKIngredient
EXEC USP_AddCKIngredient
----

GO

CREATE OR ALTER PROCEDURE USP_RemoveFKShift
AS
	ALTER TABLE Shift
	DROP CONSTRAINT FK_EID

	ALTER TABLE Shift
	DROP COLUMN EID
GO

CREATE OR ALTER PROCEDURE USP_AddFKShift
AS
	ALTER TABLE Shift
	ADD EID INT 

	ALTER TABLE Shift
	ADD CONSTRAINT FK_EID
	FOREIGN KEY (EID) REFERENCES Employee(EID);
GO

----
EXEC USP_RemoveFKShift
EXEC USP_AddFKShift
----

GO

CREATE OR ALTER PROCEDURE USP_RemoveSupplierOfferTable
AS
	DROP TABLE SupplierOffer
GO

CREATE OR ALTER PROCEDURE USP_AddSupplierOfferTable
AS
	CREATE TABLE SupplierOffer(SRID INT FOREIGN KEY REFERENCES Supplier(SRID), SUID INT FOREIGN KEY REFERENCES Ingredient(SUID), PRIMARY KEY (SRID, SUID) )
GO

----
EXEC USP_RemoveSupplierOfferTable
EXEC USP_AddSupplierOfferTable
----

CREATE TABLE DatabaseVersions(SP VARCHAR(45), RSP VARCHAR(45), V INT, PRIMARY KEY(SP, RSP, V))
DELETE FROM DatabaseVersions

INSERT INTO DatabaseVersions VALUES('USP_ModifyBeverageColumnTypeInt', 'USP_ModifyBeverageColumnTypeChar', 1)
INSERT INTO DatabaseVersions VALUES('USP_DeleteEmployeeHireDateColumn', 'USP_AddEmployeeHireDateColumn', 2)
INSERT INTO DatabaseVersions VALUES('USP_AddDefaultClientFidPoints', 'USP_RemoveDefaultClientFidPoints', 3)
INSERT INTO DatabaseVersions VALUES('USP_RemovePKShift', 'USP_AddPKShift', 4)
INSERT INTO DatabaseVersions VALUES('USP_RemoveCKIngredient', 'USP_AddCKIngredient', 5)
INSERT INTO DatabaseVersions VALUES('USP_RemoveFKShift', 'USP_AddFKShift', 6)
INSERT INTO DatabaseVersions VALUES('USP_RemoveSupplierOfferTable', 'USP_AddSupplierOfferTable', 7)

CREATE TABLE CurrentVersion(CrtVersion INT PRIMARY KEY)
INSERT INTO CurrentVersion VALUES(1)
DELETE FROM CurrentVersion

GO

CREATE OR ALTER PROCEDURE USP_BringDbToVersion @givenVersion INT
AS
	DECLARE @crtVersion INT 
	SET @crtVersion = (SELECT CV.CrtVersion FROM CurrentVersion CV)
	DECLARE @crtProc VARCHAR(45)

	WHILE @givenVersion > @crtVersion
	BEGIN
		SET @crtProc = (SELECT DV.SP FROM DatabaseVersions DV WHERE DV.V = @crtVersion +1)
		EXEC @crtProc
		SET @crtVersion = @crtVersion + 1
	END

	WHILE @givenVersion < @crtVersion
	BEGIN
		SET @crtProc = (SELECT DV.RSP FROM DatabaseVersions DV WHERE DV.V = @crtVersion)
		EXEC @crtProc
		SET @crtVersion = @crtVersion - 1
	END
	UPDATE CurrentVersion SET CrtVersion = @crtVersion

GO

EXEC USP_BringDbToVersion @givenVersion = 7

SELECT*
FROM CurrentVersion

SELECT*
FROM SupplierOffer
