
------ To use database Game_Analysis ------
USE Game_Analysis;

------ Creating table for player_details ------
CREATE TABLE pd 
(
	P_ID INT PRIMARY KEY,
	PName VARCHAR(255) NOT NULL,
	L1_Status VARCHAR(50),
	L2_Status VARCHAR(50),
	L1_Code VARCHAR(255),
	L2_Code VARCHAR(255)
);

------ Bulk inserting data into the table pd ------
BULK INSERT pd
FROM "C:\Users\preet\OneDrive\Desktop\player_details - Copy.csv"
WITH 
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',  --CSV field delimiter
	ROWTERMINATOR = '\n'   --Use to shift the control to next row
);

SELECT * FROM pd;

------ Creating table for level_details ------
CREATE TABLE ld
(
	P_ID INT,
	Dev_ID VARCHAR(10),
	TimeStamp DATETIME,
	Stages_crossed INT,
	Level INT,
	Difficulty VARCHAR(10),
	Kill_Count INT,
	Headshots_Count INT,
	Score INT,
	Lives_Earned INT,
	PRIMARY KEY (P_ID, Dev_ID, TimeStamp),
	CONSTRAINT FK_P_ID FOREIGN KEY (P_ID)
	REFERENCES pd(P_ID)
);

------ Bulk inserting data into the table ld ------
BULK INSERT ld
FROM "C:\Users\preet\OneDrive\Desktop\level_details2 - Copy.csv"
WITH 
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);

--DROP TABLE ld;

SELECT * FROM pd;
SELECT * FROM ld;

------ QUESTIONS & ANSWERS ------

-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players at level 0

SELECT 
	ld.P_ID, 
	ld.Dev_ID, 
	pd.PName, 
	ld.Difficulty
FROM ld
LEFT JOIN pd 
ON pd.P_ID = ld.P_ID
WHERE ld.Level = 0;

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast 3 stages are crossed

SELECT 
	L1_Code, 
	AVG(Kill_Count) AS Avg_Kill_Count
FROM pd
LEFT JOIN ld
ON ld.P_ID = pd.P_ID
WHERE 
	Lives_Earned = 2 AND 
	Stages_crossed >= 3 
GROUP BY L1_Code;


-- Q3) Find the total number of stages crossed at each difficulty level where for Level2 with players use zm_series devices. Arrange the result
-- in decreasing order of total number of stages crossed.

SELECT 
	Difficulty,
	SUM(Stages_crossed) AS Total_stages_crossed
FROM ld
WHERE 
	Level = 2 AND
	Dev_ID LIKE 'zm_%'
GROUP BY Difficulty
ORDER BY Total_stages_crossed DESC;

-- Q4) Extract P_ID and the total number of unique dates for those players who have played games on multiple days.

SELECT 
	P_ID,
	COUNT(DISTINCT CONVERT(DATE, TimeStamp)) AS Total_unique_dates
FROM ld
GROUP BY P_ID
HAVING COUNT(DISTINCT CONVERT(DATE, TimeStamp)) > 1;


-- Q5) Find P_ID and level wise sum of kill_counts where kill_count is greater than avg kill count for the Medium difficulty.

SELECT 
	P_ID,
	Level,
	SUM(Kill_Count) AS Total_kill_counts
FROM ld
WHERE Kill_Count > 
	(
		SELECT AVG(Kill_Count) AS Avg_kill_count
		FROM ld
		WHERE Difficulty = 'Medium'
	)
GROUP BY 
	P_ID, 
	Level;

-- Q6)  Find Level and its corresponding Level code wise sum of lives earned excluding level 0. Arrange in asecending order of level.

SELECT 
	ld.Level,
	pd.L1_Code,
	pd.L2_Code,
	SUM(ld.Lives_Earned) AS Total_lives_earned
FROM ld
LEFT JOIN pd
ON pd.P_ID = ld.P_ID
WHERE ld.Level != 0
GROUP BY
	ld.Level,
	pd.L1_Code,
	pd.L2_Code
ORDER BY ld.Level;


-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order using Row_Number. Display difficulty as well. 

SELECT  
	Dev_ID,
	Score,
	Difficulty, 
	Rank
FROM (
		SELECT 
			Dev_ID,
			Difficulty,
			Score,
			ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score) AS Rank
		FROM ld) AS Subquery
WHERE Rank <=3;

-- Q8) Find first_login datetime for each device id

SELECT 
	Dev_ID,
	MIN(TimeStamp) AS First_login
FROM ld
GROUP BY Dev_ID;

-- Q9) Find Top 5 score based on each difficulty level and Rank them in increasing order using Rank. Display dev_id as well.

SELECT
	Dev_ID,
	Score,
	Difficulty,
	Rank
FROM (
		SELECT 
			Dev_ID,
			Score,
			Difficulty,
			RANK() OVER (PARTITION BY Difficulty ORDER BY Score) AS Rank
		FROM ld ) AS Subquery1
WHERE Rank <= 5;


-- Q10) Find the device ID that is first logged in(based on start_datetime) for each player(p_id). Output should contain player id, device id and first login datetime.

SELECT 
	P_ID,
	Dev_ID,
	MIN(TimeStamp) AS First_login
FROM ld
GROUP BY 
	P_ID,
	Dev_ID;


-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played -- by the player until that date.
-- a) window function
-- b) without window function

-- a) window function

SELECT 
	P_ID, 
	TimeStamp, 
	SUM(Kill_Count) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS Total_Kill_Count
FROM ld;

-- b) without window function

SELECT 
	ld.P_ID, 
	ld.TimeStamp,
    SUM(ld2.Kill_Count) AS Total_Kill_Count
FROM ld
JOIN ld ld2 
ON ld.P_ID = ld2.P_ID AND ld.TimeStamp >= ld2.TimeStamp
GROUP BY 
	ld.P_ID, 
	ld.TimeStamp
ORDER BY 
	ld.P_ID, 
	ld.TimeStamp;


-- Q12) Find the cumulative sum of stages crossed over a start_datetime 

SELECT 
	P_ID,
	Dev_ID,
	TimeStamp,
	Stages_crossed,
	SUM(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS Cumulative_stages_crossed
FROM ld;

-- Q13) Find the cumulative sum of an stages crossed over a start_datetime for each player id but exclude the most recent start_datetime.

WITH ExcludedRecentStart AS (
    SELECT 
		P_ID, 
		TimeStamp, 
		Stages_crossed,
        ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY TimeStamp DESC) AS RowNum
    FROM ld
)
SELECT 
	er.P_ID, 
	er.TimeStamp,
	er.Stages_crossed,
    SUM(er.Stages_crossed) OVER (PARTITION BY er.P_ID ORDER BY er.TimeStamp) AS Cumulative_stages_crossed
FROM ExcludedRecentStart er
WHERE er.RowNum > 1;



-- Q14) Extract top 3 highest sum of score for each device id and the corresponding player_id

SELECT 
	P_ID,
	Dev_ID,
	Total_Score
FROM (
		SELECT 
			P_ID, 
			Dev_ID,
			SUM(Score) AS Total_Score,
			ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Rank
		FROM ld
		GROUP BY 
			Dev_ID, 
			P_ID
	) AS RankedData
WHERE Rank <= 3;


-- Q15) Find players who scored more than 50% of the avg score scored by sum of scores for each player_id

WITH PlayerTotalScores AS 
(
    SELECT 
		P_ID, 
		SUM(Score) AS TotalScore
    FROM ld
    GROUP BY P_ID
),
AvgTotalScore AS 
(
    SELECT AVG(TotalScore) AS AvgScore
    FROM PlayerTotalScores
)
SELECT P_ID
FROM PlayerTotalScores
CROSS JOIN AvgTotalScore
WHERE TotalScore > AvgScore * 0.5;


-- Q16) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order using Row_Number. Display difficulty as well.

CREATE PROCEDURE TopNHeadshotsCount
    @n INT
AS
BEGIN
    SELECT Dev_ID, Rank,
           Headshots_Count,
           Difficulty
    FROM (
        SELECT Dev_ID,
               ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Headshots_Count ASC) AS Rank,
               Headshots_Count,
               Difficulty
        FROM ld
    ) AS RankedData
    WHERE Rank <= @n;
END;


EXEC TopNHeadshotsCount @n = 4;


-- DROP PROCEDURE TopNHeadshotsCount;


-- Q17) Create a function to return sum of Score for a given player_id.

CREATE FUNCTION TotalScoreForPlayer
(
    @player_id INT
)
RETURNS INT
AS
BEGIN
    DECLARE @totalScore INT;

    SELECT @totalScore = SUM(Score)
    FROM ld
    WHERE P_ID = @player_id;

    RETURN ISNULL(@totalScore, 0);
END;

SELECT dbo.TotalScoreForPlayer(558) AS TotalScoreForPlayer;

