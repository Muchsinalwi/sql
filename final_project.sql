USE maven_advanced_sql;
-- PART I: SCHOOL ANALYSIS
-- 1. View the schools and school details tables
SELECT * FROM schools;
SELECT * FROM school_details;

-- 2. In each decade, how many schools were there that produced players?
SELECT FLOOR(yearID/10) * 10 AS decade,
	   COUNT(DISTINCT schoolID) AS num_schools
FROM schools
GROUP BY decade
ORDER BY decade;


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
SELECT COUNT(DISTINCT teamID)
FROM salaries;

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
-- 1. View the players table and find the number of players in the table
SELECT * FROM players;
SELECT COUNT(*) FROM players;

-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.
SELECT * FROM players
WHERE playerID = "aardsda01";

-- 3. What team did each player play on for their starting and ending years?
-- 4. How many players started and ended on the same team and also played for over a decade?

-- PART IV: PLAYER COMPARISON ANALYSIS
-- 1. View the players table
-- 2. Which players have the same birthday?
-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both
-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?
