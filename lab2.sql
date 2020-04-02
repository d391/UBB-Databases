 --a

--all employees that have the bartender and delivery shift
SELECT DISTINCT E.Name
FROM Employee E, Shift S
WHERE E.EID = S.EID AND S.Type = 'Bartender'
UNION 
SELECT DISTINCT E1.Name
FROM Employee E1, Shift S1
WHERE E1.EID = S1.EID AND S1.Type = 'Delivery'

--the arrival date of orders with supplies of urgency 4 and 5
SELECT I.Name, SC.ArrivalDate, I.Urgency
FROM Ingredient I, SupplyCommand SC
WHERE I.SUID = SC.SUID AND (I.Urgency = 4 OR I.Urgency = 5 )


--b

--all employees that have both the delivery and bartender shifts
SELECT E.Name, E.Salary
FROM Employee E, Shift S
WHERE E.EID = S.EID AND S.Type = 'Bartender'
INTERSECT 
SELECT E1.Name, E1.Salary
FROM Employee E1, Shift S1
WHERE E1.EID = S1.EID AND S1.Type = 'Delivery'

--all supplies who have the arrival date '2019-11-30' and the urgency less than 5 (--e)
SELECT I.Name, SC.ArrivalDate
FROM Ingredient I, SupplyCommand SC
WHERE I.SUID = SC.SUID AND SC.ArrivalDate = '2019-11-30' AND I.Urgency IN (SELECT I1.Urgency
																			FROM Ingredient I1
																			WHERE I1.Urgency < 5)

--c

--all employees that have the bartender shift but do not have the delivery shift
SELECT E.Name, E.Salary, S.Type
FROM Employee E, Shift S
WHERE E.EID = S.EID AND S.Type = 'Bartender'
EXCEPT 
SELECT E1.Name, E1.Salary, S1.Type
FROM Employee E1, Shift S1
WHERE E1.EID = S1.EID AND S1.Type = 'Delivery'

--all supplies that have the current quantity less than 20 but the delivered quantity at least 10 
SELECT I.Name, SC.ArrivalDate, I.Quantity AS 'CurrentQuantity', SC.Quantity AS 'DeliveredQuantity'
FROM Ingredient I, SupplyCommand SC
WHERE I.SUID = SC.SUID AND I.Quantity < 20 AND SC.Quantity > ALL (SELECT SC1.Quantity
									FROM SupplyCommand SC1
									WHERE SC1.Quantity < 10)

SELECT I.Name, SC.ArrivalDate, I.Quantity AS 'CurrentQuantity', SC.Quantity AS 'DeliveredQuantity'
FROM Ingredient I, SupplyCommand SC
WHERE I.SUID = SC.SUID AND I.Quantity < 20 AND SC.Quantity NOT IN (SELECT SC1.Quantity
									FROM SupplyCommand SC1
									WHERE SC1.Quantity < 10)


--h

--shows the number of beverages of each concentration different than 0
SELECT COUNT(*) AS NumberOfBeverages, B.Concentration
FROM Beverage B
GROUP BY B.Concentration
HAVING B.Concentration IN (SELECT B1.Concentration
							FROM Beverage B1
							WHERE B1.Concentration > 0)

--the average price of current orders of a certain drink which has been sold for more than 10.00 lei
SELECT CO.BID, AVG(CO.Price) AS AverageAmount
FROM CurrentOrder CO
GROUP BY CO.BID
HAVING SUM(CO.Price) > 10

--show the number of commands that arrive on the earliest 2 dates and whose delivered quantity is bigger than 20, ordered by date
SELECT TOP 2 SC.ArrivalDate, COUNT(*) AS 'NumberOfCommands', SUM(SC.Quantity) AS 'TotalAmountToDeliver'
FROM SupplyCommand SC
GROUP BY SC.ArrivalDate
HAVING SUM(SC.Quantity) > 20
ORDER BY SC.ArrivalDate

--g

--shows all the suppliers that deliver the maximum quantity (--)
SELECT SU.SRID, SU.Name, A.DeliveredQuantity
FROM Supplier SU, (SELECT SC.SRID, SUM(SC.Quantity) AS 'DeliveredQuantity'
					FROM SupplyCommand SC
					GROUP BY SC.SRID
					HAVING SUM(SC.Quantity) = (SELECT MAX(A1.DeliveredQuantity)
												FROM (SELECT SC1.SRID, SUM(SC1.Quantity) AS 'DeliveredQuantity'
														FROM SupplyCommand SC1
														GROUP BY SC1.SRID) A1)) A
WHERE SU.SRID = A.SRID

--d

--shows all the details of the current orders with a 'happy monday discount'
SELECT B.Name, B.Concentration, CO.Price - CO.Price*0.15 AS 'HappyMondayDiscountPrice', BS.Name AS 'Size'
FROM Beverage B INNER JOIN CurrentOrder CO ON B.BID = CO.BID INNER JOIN BeverageSize BS ON CO.BSID = BS.BSID


--shows for each supply that has a command its command details and the total quantity (current + delivered one)
SELECT I.Name, I.Quantity AS 'CurrentQuantity', I.Urgency, SC.ArrivalDate, SC.Quantity AS 'DeliveredQuantity', SU.Name, I.Quantity + SC.Quantity AS 'TotalQuantityAfterDelivery'
FROM Ingredient I LEFT JOIN SupplyCommand SC ON I.SUID = SC.SUID LEFT JOIN Supplier SU ON SC.SRID = SU.SRID
WHERE EXISTS (SELECT I.SUID
				FROM SupplyCommand SC
				WHERE SC.SUID = I.SUID)
ORDER BY I.Urgency DESC


--shows the details of the clients and their subscriptions with the most fidelity points
SELECT C.Name, C.Delivery_address, C.Fidelity_points, S.Deadline AS 'DeadlineOfSubscription'
FROM Client C FULL JOIN Subscription S ON C.CID = S.CID
WHERE C.Fidelity_points = (SELECT MAX(C1.Fidelity_points)
							FROM Client C1)

--shows the details of each shift and of its employee
SELECT E.Name, E.Salary, E.Date_of_hire, S.Time_Interval, S.Type
FROM Employee E RIGHT JOIN Shift S ON E.EID = S.EID

--show the beverages ordered by client with id 907(--e,--i)
SELECT*
FROM Beverage B
WHERE B.BID IN (SELECT OC.BID
				FROM OrderContent OC
				WHERE OC.OID = ANY (SELECT O.OID
								FROM Orders O
								WHERE O.CID = 907))

SELECT*
FROM Beverage B
WHERE B.BID IN (SELECT OC.BID
				FROM OrderContent OC
				WHERE OC.OID IN (SELECT O.OID
								FROM Orders O
								WHERE O.CID = 907))
								
--show the first 3 orders of the clients with at least 10 fidelity points and most expensive orders
SELECT TOP 3 *
FROM Orders O
WHERE EXISTS (SELECT O.CID
				FROM Client C
				WHERE O.CID = C.CID AND C.Fidelity_points>=10)
ORDER BY O.Price DESC

--the most ordered beverage(s) from the clients with a subscription
SELECT*
FROM Beverage B
WHERE B.BID = ANY (SELECT OC.BID 
					FROM OrderContent OC
					GROUP BY OC.BID
					HAVING SUM(OC.Quantity) = (SELECT MAX(A.TotalQuantity)
												FROM (SELECT SUM(OC1.Quantity) AS 'TotalQuantity'
														FROM OrderContent OC1
														GROUP BY OC1.BID) A))

SELECT*
FROM Beverage B
WHERE B.BID = ANY (SELECT OC.BID 
					FROM OrderContent OC
					GROUP BY OC.BID
					HAVING SUM(OC.Quantity) >= ALL (SELECT A.TotalQuantity
												FROM (SELECT SUM(OC1.Quantity) AS 'TotalQuantity'
														FROM OrderContent OC1
														GROUP BY OC1.BID) A))

--shows all the clients that have an extra item in their command
SELECT*
FROM Client C
WHERE C.CID = ANY (SELECT O.CID
					FROM Orders O
					WHERE O.OID = ANY (SELECT OC.OID
									FROM OrderContent OC
									WHERE OC.EIID IS NOT NULL))

--show the orders of each client with a discount based on their fidelity points
SELECT A.OID, (A.Price - A.Fidelity_points) AS 'FidelityDiscountPrice', A.Name
FROM (SELECT O.OID, O.Price, C.Fidelity_points, C.Name 
		FROM Orders O INNER JOIN Client C ON O.CID = C.CID) A

--shows the suppliers' ids that have current orders
SELECT DISTINCT SC.SRID
FROM SupplyCommand SC

--shows the ids of the employees that already have shifts
SELECT DISTINCT S.EID
FROM Shift S



--update
UPDATE Employee SET Salary = Salary-200

SELECT *
FROM Employee

UPDATE Client SET Fidelity_points = Fidelity_points + 1

SELECT *
FROM Client

UPDATE Beverage SET Concentration = 4 WHERE BID = 1

SELECT *
FROM Beverage

--delete
DELETE FROM Client WHERE Fidelity_points < 1 OR Name IS NULL

SELECT*
FROM Client

DELETE FROM Beverage WHERE BID > 4 AND Concentration < 1

SELECT*
FROM Beverage


