USE maven_advanced_sql;
-- PART I: SCHOOL ANALYSIS
-- 1. View the schools and school details tables
SELECT * FROM schools;
SELECT * FROM school_details;
-- 2. In each decade, how many schools were there that produced players?
SELECT FLOOR(yearID/10) * 10 AS decade, 
	   COUNT(DISTINCT schoolID) AS num_schools
FROM schools
GROUP BY decade;

-- 3. What are the names of the top 5 schools that produced the most players?
SELECT sd.name_full AS school_name,
       COUNT(DISTINCT s.playerID) AS num_players
FROM schools s LEFT JOIN school_details sd
    ON s.schoolID = sd.schoolID
GROUP BY s.schoolID
ORDER BY num_players DESC
LIMIT 5;

-- 4. For each decade, what were the names of the top 3 schools that produced the most players?
WITH sd AS (SELECT sd.name_full AS school_name, FLOOR(s.yearID/10) * 10 AS decades, COUNT(*) AS num_records
			FROM schools s LEFT JOIN school_details sd
				ON s.schoolID = sd.schoolID
			GROUP BY sd.name_full, FLOOR(s.yearID/10) * 10),
						
	 rs AS (SELECT school_name, decades, num_records,
			ROW_NUMBER() OVER (PARTITION BY decades ORDER BY num_records DESC) AS rank_in_decade
			FROM sd)
                                            
SELECT *
FROM rs
WHERE rank_in_decade <= 3;

-- PART II: SALARY ANALYSIS
-- 1. View the salaries table
SELECT * FROM salaries;
-- 2. Return the top 20% of teams in terms of average annual spending
SELECT teamID, ROUND(AVG(sum_salary)) AS avg_salary
FROM (SELECT teamID, yearID, SUM(salary) AS sum_salary
		FROM salaries
		GROUP BY teamID, yearID) t
		GROUP BY teamID;

WITH avg_sl AS (SELECT teamID, ROUND(AVG(sum_salary)) AS avg_salary
				FROM (SELECT teamID, yearID, SUM(salary) AS sum_salary
					  FROM salaries
					  GROUP BY teamID, yearID) t
				GROUP BY teamID),
                
	 tp AS (SELECT teamID, avg_salary,
				    NTILE(5) OVER (ORDER BY avg_salary DESC) AS spend_pct
			FROM avg_sl)
            
SELECT teamID, ROUND(avg_salary / 1000000, 1) AS avg_salary
FROM tp
WHERE spend_pct = 1;

-- 3. For each team, show the cumulative sum of spending over the years

SELECT DISTINCT yearID
FROM salaries
WHERE teamID = "ANA";

SELECT teamID, yearID, SUM(salary) AS sum_salary
FROM salaries
GROUP BY yearID, teamID
ORDER BY teamID, yearID;

WITH  ys AS (SELECT teamID, yearID, SUM(salary) AS sum_salary
			FROM salaries
			GROUP BY yearID, teamID),

	  cs AS (SELECT teamID, yearID,
		    ROUND(SUM(sum_salary) OVER(PARTITION BY teamID ORDER BY yearID) / 1000000, 1) 
            AS cumulative_sum_milions
			FROM ys) 
            
SELECT *
FROM cs;

-- 4. Return the first year that each team's cumulative spending surpassed 1 billion
WITH  ys AS (SELECT teamID, yearID, SUM(salary) AS sum_salary
			FROM salaries
			GROUP BY yearID, teamID),

		cs AS (SELECT teamID, yearID,
		    SUM(sum_salary) OVER(PARTITION BY teamID ORDER BY yearID)  AS cumulative_sum
			FROM ys),
		
        ts AS (SELECT teamID, yearID, cumulative_sum,
				ROW_NUMBER() OVER(PARTITION BY teamID ORDER BY cumulative_sum) AS spending_1bill
                FROM cs
                WHERE cumulative_sum > 1000000000)
            
SELECT teamID, yearID, ROUND(cumulative_sum / 1000000000, 2) AS cumulative_sum_billions
FROM ts
WHERE spending_1bill = 1;

-- PART III: PLAYER CAREER ANALYSIS
USE maven_advanced_sql;
-- 1. View the players table and find the number of players in the table
SELECT * FROM players;
SELECT COUNT(playerID) AS player_count FROM players;
-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.
SELECT nameGiven, birthYear, YEAR(debut), YEAR(finalGame)
FROM players
WHERE nameGiven = "Nicholas";

WITH calc AS (SELECT nameGiven, birthYear, 
	   YEAR(debut) AS debut, 
       YEAR(finalGame) AS final_game
	   FROM players)
       
SELECT nameGiven, 
	   (debut - birthYear) AS age_at_debut,
       (final_game - birthYear) AS age_at_final,
       (final_game - debut) AS careerLength
FROM calc
ORDER BY careerLength DESC;

-- 3. What team did each player play on for their starting and ending years?
SELECT * FROM players;
SELECT * 
FROM salaries;

SELECT p.nameGiven,
	   s.yearID, s.teamID,
       e.yearID, e.teamID
FROM players p INNER JOIN salaries s
						  ON p.playerID = s.playerID
                          AND YEAR(p.debut) = s.yearID
			   INNER JOIN salaries e
						  ON p.playerID = e.playerID
                          AND YEAR(p.finalGame) = e.yearID;

-- 4. How many players started and ended on the same team and also played for over a decade?
SELECT p.nameGiven,
	   s.yearID, s.teamID,
       e.yearID, e.teamID
FROM players p INNER JOIN salaries s
						  ON p.playerID = s.playerID
                          AND YEAR(p.debut) = s.yearID
			   INNER JOIN salaries e
						  ON p.playerID = e.playerID
                          AND YEAR(p.finalGame) = e.yearID
WHERE	s.teamID = e.teamID AND e.yearID - s.yearID > 10;

-- PART IV: PLAYER COMPARISON ANALYSIS
USE maven_advanced_sql;
-- 1. View the players table
SELECT * FROM players;
-- 2. Which players have the same birthday?
/*SELECT p.nameGiven AS player1, 
	   CONCAT(p.birthYear, '-', LPAD(p.birthMonth, 2, '0'), '-', LPAD(p.birthDay, 2, '0')) AS birthDate1,
       e.nameGiven AS player2, 
       CONCAT(p.birthYear, '-', LPAD(p.birthMonth, 2, '0'), '-', LPAD(p.birthDay, 2, '0')) AS birthDate2
FROM players p INNER JOIN players e
			   ON p.birthYear = e.birthYear
               AND p.birthMonth = e.birthMonth
               AND p.birthDay = e.birthDay
               AND p.nameGiven <> e.nameGiven; */

WITH bd AS (SELECT CAST(CONCAT(birthYear, '-' , birthMonth, '-' , birthDay)AS DATE) AS birthDate,
				   nameGiven
		    FROM players)
            
SELECT birthDate, GROUP_CONCAT(nameGiven SEPARATOR ', ') AS players, COUNT(nameGiven)
FROM bd
WHERE birthDate IS NOT NULL AND YEAR(birthDate) BETWEEN 1980 AND 1990
GROUP BY birthDate
HAVING COUNT(nameGiven) >= 2
ORDER BY birthDate;

-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both
USE maven_advanced_sql;
SELECT nameGiven AS players, bats
FROM players; 

-- Join the salary and the players table
WITH pl AS (SELECT s.teamID AS teamID, COUNT(DISTINCT p.nameGiven) AS players, p.bats AS bats	
				FROM players p INNER JOIN salaries s 
				ON p.playerID = s.playerID
				GROUP BY p.bats, s.teamID),
           
 -- sum the total of players based on the specified teamID       
	 sum_pl AS (SELECT teamID, players, bats,
				SUM(players) OVER (PARTITION BY teamID) AS total_players
				FROM pl
				GROUP BY bats, teamID),
                
 -- create a percentage for base handed players according to the teamID                
	 pct_pl AS (SELECT teamID, players, total_players, bats,
				ROUND(players * 100.0 / total_players, 1) AS percent
				FROM sum_pl)

-- write the main query and create a case statement for the num of batting percentage using coalesce to remove the null values
SELECT teamID, 
	   COALESCE(MAX(CASE WHEN bats = 'B' THEN percent END), 1) AS both_handed,
	   COALESCE(MAX(CASE WHEN bats = 'L' THEN percent END), 1) AS left_handed,
       COALESCE(MAX(CASE WHEN bats = 'R' THEN percent END), 1) AS right_handed
FROM pct_pl
GROUP BY teamID;

-- Alice's version
SELECT s.teamID,
	   ROUND(SUM(CASE WHEN p.bats = 'R' THEN 1 ELSE 0 END) / COUNT(s.playerID)*100, 1) AS right_handed,
       ROUND(SUM(CASE WHEN p.bats = 'L' THEN 1 ELSE 0 END) / COUNT(s.playerID)*100, 1) AS left_handed, 
       ROUND(SUM(CASE WHEN p.bats = 'B' THEN 1 ELSE 0 END) / COUNT(s.playerID)*100, 1) AS both_handed
FROM salaries s LEFT JOIN players p
	 ON s.playerID = p.playerID
GROUP BY s.teamID
ORDER BY s.teamID;

-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?
SELECT * FROM players; 

WITH hw AS (SELECT ROUND(AVG(height), 2) AS avg_height, ROUND(AVG(weight), 2) AS avg_weight, 
	   ROUND(YEAR(debut), -1) AS decade
       FROM players
	   GROUP BY decade)
       
SELECT decade,
	   avg_height - LAG(avg_height) OVER(ORDER BY decade) AS height_diff, -- calc the prior h and w players using LAG function 
       avg_weight - LAG(avg_weight) OVER(ORDER BY decade) AS weight_diff
FROM hw
WHERE decade IS NOT NULL;