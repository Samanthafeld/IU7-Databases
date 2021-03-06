USE MetroDB
GO

-- 1. ���������� ������� ������ ����� �����, ������� ���� �������
-- ���������� �� ������ 8:00:00.
SELECT DISTINCT Workers.Name, Workers.Job, Stations.Name
FROM Workers JOIN Stations on Stations.ID = Workers.Station_ID
WHERE Stations.Line_ID = 2 AND Workers.Start_Time >= '08:00:00'
ORDER BY Workers.Name, Workers.Job
GO

-- 2. �������, �������� � ������ ����������� 21 ����
SELECT Name, Line_ID, Open_Date
FROM Stations
WHERE Open_Date BETWEEN '2001-01-01' AND '2010-12-31'
ORDER BY Open_Date
GO

-- 3. ���������� �����, ����������� �� ����� ����������
SELECT DISTINCT Name, Phone_Number, Job, Address
FROM Workers
WHERE Address LIKE '��. ����������,%'
GO

-- 4. ���������� �������, ���������� ������ � 5:00
SELECT Workers.Name, Phone_Number, Job, Address, Stations.Open_Time
FROM Workers JOIN Stations on Workers.Station_ID = Stations.ID
WHERE Station_ID IN
	(
	SELECT ID
	FROM Stations
	WHERE Open_Time = '05:00:00'
	)
GO

-- 5. ����, � ������� ���� ������� � ������ �������, ������� 6
SELECT Depots.Name AS Depot_Name, Stations.Name AS Station_Name
FROM Depots JOIN Stations on Depots.Nearest_Station_ID = Stations.ID
WHERE EXISTS
	(
	SELECT Depot_ID
	FROM Stocks JOIN Trains on Stocks.Model_Code = Trains.Model
	WHERE Trains.Wagons_Qty > 6
	)
GO

-- 6. �������, ������� ������� ������, ��� � ���� �������, ��������
-- ������ 1980 ����
SELECT Name, Line_ID, Open_Date
FROM Stations
WHERE Depth > ALL
	(
	SELECT Depth
	FROM Stations
	WHERE Open_Date < '1980-01-01'
	)
GO

-- 7. ����� ����� ������� � ����, ������� ����� ���� � �������, ����� ������� ������� � ���� (���� �8)
SELECT SUM(TotStock.Wagons_Qty) AS 'WagonsOverall',
		AVG(TotStock.Seats_Qty) AS 'AvgSeats',
		COUNT(TotStock.Model) AS 'TrainsQty'
FROM (
	SELECT Trains.Seats_Qty, Trains.Wagons_Qty, Trains.Model
	FROM Trains JOIN (Stocks JOIN Depots ON Stocks.Depot_ID = Depots.ID)
	ON Trains.Model = Stocks.Model_Code WHERE Depot_ID = 8
	GROUP BY Trains.Wagons_Qty, Trains.Seats_Qty, Trains.Model
) AS TotStock
GO

-- 8. ������� ������� ������� ����� � ����� �������� ������ �������
SELECT Lines.Code,
	(
		SELECT AVG(Stations.Depth)
		FROM Stations
		WHERE Stations.Line_ID = Lines.Code
	) AS AvgDepth,
	(
		SELECT MIN(Stations.Open_Time)
		FROM Stations
		WHERE Stations.Line_ID = Lines.Code
	) AS FirstStationOpenTime
FROM Lines
GO

-- 9. ������� ��� ����� ��������� �������
SELECT Name, Line_ID,
	CASE YEAR(Open_Date)
		WHEN YEAR(Getdate()) THEN 'This Year'
		WHEN YEAR(GetDate()) - 1 THEN 'Last year'
		ELSE CAST(DATEDIFF(year, Open_Date, Getdate()) AS varchar(5)) + ' years ago'
	END AS 'When opened'
FROM Stations
GO

-- 10. �������� ���������
SELECT S1Name, S2Name, TransferTime,
	CASE
		WHEN TransferTime <= 1 THEN 'Crossplatforming'
		WHEN TransferTime < 3 THEN 'Short'
		WHEN TransferTime < 6 THEN 'Average'
		ELSE 'Long'
	END AS TransferS
FROM
(
	SELECT S1Name, Stations.Name AS S2Name, TransferTime FROM
			Stations JOIN (SELECT Stations.Name AS S1Name,
							Transfers.ID_Station_2 AS ID2,
							Transfers.Time AS TransferTime FROM
							Stations JOIN Transfers on Stations.ID = Transfers.ID_Station_1)
							AS T1 ON Stations.ID = T1.ID2
) AS T
GO

-- 11. ���������� � ������� �������, ������� ������� �� ������ 10:
--		����� ����� ����, ������� ��� ���������������
SELECT Model,
	(CAST(Wagons_Qty AS int) * CAST(Seats_Qty AS int)) AS SeatsOverall,
	YEAR(Getdate()) - Exploit_Since_y AS Exploiting
INTO #ModelExploition
FROM Trains
WHERE EXISTS
(
	SELECT Trains.Model
	FROM Trains JOIN Stocks on Trains.Model = Stocks.Model_Code
	WHERE Stocks.Qty > 10
)
GROUP BY Model, Wagons_Qty, Seats_Qty, Exploit_Since_y
GO

SELECT * FROM #ModelExploition
GO

-- 12. ���������� ������� ����� 1 � 2
SELECT Workers.Name, Workers.Job
FROM Workers JOIN
(
	SELECT ID
	FROM Stations
	WHERE Line_ID = 1
	GROUP BY Open_Time, ID
) AS Station_L1 ON Workers.Station_ID = Station_L1.ID
UNION
SELECT Workers.Name, Workers.Job
FROM Workers JOIN
(
	SELECT ID
	FROM Stations
	WHERE Line_ID = 2
	GROUP BY Open_Time, ID
) AS Station_L2 ON Workers.Station_ID = Station_L2.ID
GO

-- 13. ������ �������, ������������� ����� 5 � 6
SELECT Model, Exploit_Since_y
FROM Trains
WHERE EXISTS
(
	SELECT Model_Code
	FROM Stocks
	WHERE EXISTS
	(
		SELECT Depots.ID
		FROM Depots
		WHERE EXISTS
		(
			SELECT ID
			FROM Stations
			WHERE Line_ID = 5
		) AND Stocks.Depot_ID = Depots.ID
	) AND Trains.Model = Stocks.Model_Code
)
UNION
SELECT Model, Exploit_Since_y
FROM Trains
WHERE EXISTS
(
	SELECT Model_Code
	FROM Stocks
	WHERE EXISTS
	(
		SELECT ID
		FROM Depots
		WHERE EXISTS
		(
			SELECT ID
			FROM Stations
			WHERE Line_ID = 6
		) AND Stocks.Depot_ID = Depots.ID
	) AND Trains.Model = Stocks.Model_Code
)
GO

-- 14. �������� �� ������� ����������������� ������� �����
SELECT Lines.Code,
		AVG(Stations.Depth) AS AvgDepth,
		MIN(Stations.Depth) AS MinDepth,
		MAX(Stations.Depth) AS MaxDepth
FROM Lines JOIN Stations ON Stations.Line_ID = Lines.Code
WHERE Stations.Platforms_Qty = 1
GROUP BY Lines.Code, Stations.Depth
GO

-- 15. ������� ����� 5, ������� ������� ������ �������
SELECT Stations.Name, Stations.Depth, Stations.Open_Date
FROM Stations
GROUP BY Stations.Name, Stations.Depth, Stations.Open_Date
HAVING Stations.Depth <
(
	SELECT AVG(Stations.Depth) AS AvgDepth
	FROM Stations
	WHERE Stations.Line_ID = 5
)
ORDER BY Stations.Depth
GO

-- 16. ���������� ������ ����������
INSERT Workers(ID,Name,Sex,Birth_Date,Phone_Number,Address,Job,Station_ID,Line_Code,Start_Time,End_Time)
VALUES ((SELECT COUNT(*) FROM Workers) + 1,'�������� ��������� ��������','�','1980-05-20','+79150885541',
		'��. ����������, �. 3','��������� ������',14,null,'05:00:10','15:00:00')

-- 17. ���������� ����� �������� � �������� � ���� �4
INSERT Stocks(Depot_ID, Model_Code, Qty)
SELECT 4, Model, 10
FROM Trains
WHERE Seats_Qty > 40
GO

-- 18. ��������� ��������� ������ ������� � ����
UPDATE Stocks
SET Qty = Qty + 10
WHERE Qty < 20
GO

-- 19. ��� ������ ��� ���� ��������� ��������� ������ �������� ������������� �����
UPDATE Stocks
SET Qty = 
(
	SELECT MAX(Stocks.Qty)
	FROM Stocks JOIN Trains on Stocks.Model_Code = Trains.Model
	WHERE Trains.Seats_Qty > 50
)
WHERE Depot_ID < 4
GO

-- 20. ������ �� ���� ������, ����� �������� ������� ������ 15
DELETE Stocks
WHERE Qty < 15
GO

-- 21. ������ �� ���� ������, ��� ��������� ������� �� 1980 � ����� ������� ������ 20
DELETE FROM Stocks
WHERE Model_Code IN
(
	SELECT Model
	FROM Trains JOIN Stocks ON Trains.Model = Stocks.Model_Code
	WHERE Stocks.Qty < 20 AND Trains.Produce_End_y <= 1980
)
GO

-- 22. ������� ����� ������� ����� ������
WITH MC(ModelNo, NumberOfTrains)
AS
(
	SELECT Model_Code, SUM(Qty) AS Total
	FROM Stocks
	GROUP BY Model_Code
)
SELECT AVG(NumberOfTrains) AS '������� ����� ������� ����� ������'
FROM MC
GO

-- 23. ������� ����� 1 ������ � ������������� ������ ������ � ���� ���������
WITH TunnelTransfer(ID_Station_1, ID_Station_2, Time, Level)
AS
(
	SELECT T.ID_Station_1, T.ID_Station_2, T.Time, 0 AS Level
	FROM Transfers AS T
	WHERE NOT EXISTS
	(
		SELECT Transfers.ID_Station_2
		FROM Transfers
		WHERE Transfers.ID_Station_2 = T.ID_Station_1
	) AND T.ID_Station_1 IN
	(
		SELECT ID
		FROM Stations
		WHERE Line_ID = 1
	)
	UNION ALL

	SELECT T.ID_Station_1, T.ID_Station_2, T.Time, Level + 1
	FROM Transfers AS T INNER JOIN TunnelTransfer AS T2
	ON T.ID_Station_1 = T2.ID_Station_2
	WHERE T2.ID_Station_2 IN
	(
		SELECT ID
		FROM Stations
		WHERE Line_ID = 1
	)
)
SELECT ID_Station_1, ID_Station_2, Time, Level
FROM TunnelTransfer
GO

-- 24. ������� �������
SELECT Lines.Code, Lines.Color, Stations.Name, Stations.Depth,
		AVG(Stations.Depth) OVER(PARTITION BY Stations.Line_ID) AS AvgDepth,
		MIN(Stations.Depth) OVER(PARTITION BY Stations.Line_ID) AS MinDepth,
		MAX(Stations.Depth) OVER(PARTITION BY Stations.Line_ID) AS MaxDepth
FROM Lines JOIN Stations ON Stations.Line_ID = Lines.Code
GO

-- 25. ���������� ������: ��������� ���������
SELECT Job
FROM (
	SELECT ROW_NUMBER() OVER(PARTITION BY Workers.Job ORDER BY Workers.Job) AS N, Job
	FROM Workers JOIN Stations on Workers.Station_ID = Stations.ID
) AS W
WHERE N = 1