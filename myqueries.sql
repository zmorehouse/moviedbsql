--Please input your UID here: u7637337
--Course Number : 2400

-- Q1 How many persons were born after 1974 whose first name ends with ’e’? List that number.
SELECT COUNT(*) 
FROM PERSON
WHERE year_born > 1974
AND first_name LIKE '%e';

-- Q2 Find the average run time of movie(s) which were produced before 1991 and categorised as ’PG-13’ restriction in the USA.(round to two decimal places).
SELECT ROUND(AVG(m.run_time), 2)
FROM MOVIE AS m
INNER JOIN RESTRICTION AS r ON m.title = r.title and m.production_year = r.production_year
WHERE m.production_year < 1991
AND LOWER(r.description) = 'pg-13'
AND LOWER(r.country) = 'usa';

-- Q3 How many movies have at most 2 crew members? List that number.
SELECT COUNT(*)
FROM (
    SELECT title
    FROM CREW
    GROUP BY title
    HAVING COUNT(title) <= 2
) AS movie_list;

-- Q4 Find director(s) who have never been nominated for a director award. List their count.
SELECT COUNT(DISTINCT id)
FROM DIRECTOR
WHERE id NOT IN (
    SELECT d.id 
    FROM DIRECTOR AS d JOIN DIRECTOR_AWARD AS da ON d.title = da.title
);

-- Q5 List the first and last name of director(s) who have directed the maximum number of ’comedy’ movies. Order your result in the ascending order of their first names.
WITH comedy_directors AS (
    SELECT p.first_name, p.last_name, COUNT(*) AS appearance_count
    FROM PERSON AS p 
    JOIN DIRECTOR as d ON d.id = p.id 
    JOIN MOVIE AS m on m.title = d.title  AND m.production_year = d.production_year
    WHERE LOWER(m.major_genre) = 'comedy'
    GROUP BY p.first_name, p.last_name
)
SELECT first_name, last_name
FROM comedy_directors
WHERE appearance_count = (
    SELECT MAX(appearance_count) FROM comedy_directors
)
ORDER BY first_name ASC;

-- Q6 What proportion of comedy movies are produced in Australia among all comedy movies in this database? List the proportion as a decimal (round to two decimal places).
SELECT 
    CASE
        WHEN EXISTS (
            SELECT *
            FROM MOVIE
            WHERE LOWER(major_genre) = 'comedy'
            AND LOWER(country) = 'australia'
        )
        THEN
            ROUND(
                ( 
                SELECT COUNT(*)
                FROM MOVIE
                WHERE LOWER(major_genre) = 'comedy'
                AND LOWER(country) = 'australia'
                ) 
                * 1.0 /
                ( 
                SELECT COUNT(*) 
                FROM MOVIE
                WHERE LOWER(major_genre) = 'comedy'
                ), 2)
        ELSE 0.00  
    END
AS proportion;

-- Q7 Of all the movies that have won both a director award and an actor award in the same year, which movie(s) have won the largest combined total of both director and actor awards in a single year? List their title(s) and production year(s).
WITH director_awards AS (
    SELECT title, production_year, year_of_award, COUNT(year_of_award) AS DIRECTOR_AWARD_COUNT
    FROM DIRECTOR_AWARD
    WHERE LOWER(result) = 'won'
    GROUP BY title, production_year, year_of_award
),
actor_awards AS (
    SELECT title, production_year, year_of_award, COUNT(year_of_award) AS ACTOR_AWARD_COUNT
    FROM ACTOR_AWARD
    WHERE LOWER(result) = 'won'
    GROUP BY title, production_year, year_of_award
),
combined_awards AS (
    SELECT da.title, da.production_year, 
           SUM(da.DIRECTOR_AWARD_COUNT + aa.ACTOR_AWARD_COUNT) AS award_total
    FROM director_awards AS da
    JOIN actor_awards AS aa ON da.title = aa.title AND da.year_of_award = aa.year_of_award
    GROUP BY da.title, da.production_year
)
SELECT ca.title, ca.production_year
FROM combined_awards AS ca
WHERE ca.award_total = (
    SELECT MAX(award_total)
    FROM combined_awards
);


-- Q8 How many movies have won at least one award (including movie awards, crew awards, director awards, writer awards and actor awards)? List that number.
SELECT COUNT(DISTINCT title) AS movies_with_awards
FROM (
    SELECT year_of_award, title
    FROM DIRECTOR_AWARD
    WHERE LOWER(result) = 'won'
    UNION 
    SELECT year_of_award, title
    FROM ACTOR_AWARD
    WHERE LOWER(result) = 'won'
    UNION 
    SELECT year_of_award, title
    FROM CREW_AWARD
    WHERE LOWER(result) = 'won'
    UNION 
    SELECT year_of_award, title
    FROM WRITER_AWARD
    WHERE LOWER(result) = 'won'
    UNION 
    SELECT year_of_award, title
    FROM MOVIE_AWARD
    WHERE LOWER(result) = 'won'
) AS combined_awards;

-- Q9 Which director(s) directed the least variety of movies (i.e., the least number of distinct major genres)? List their id(s).
WITH d_genres AS (
    SELECT d.id, COUNT(DISTINCT m.major_genre) as num_genres
    FROM DIRECTOR AS d
    JOIN MOVIE AS m ON d.title = m.title AND d.production_year = m.production_year
    GROUP BY d.id
)
SELECT d_genres.id 
FROM d_genres 
WHERE d_genres.num_genres = (
    SELECT MIN(num_genres)
    FROM d_genres
);


-- Q10 List every pair of movies that have won any award within the same year. In the case of more than 2 films winning an award within a given year, all pairs (eg {movie1, movie2}, {movie2, movie3} and {movie1, movie3}) should be present.
    
    SELECT DISTINCT CONCAT(table1.title, ', ', table1.production_year) AS movie_a, CONCAT(table2.title, ', ', table2.production_year) AS movie_b
FROM
    (
        SELECT year_of_award, title, production_year
        FROM DIRECTOR_AWARD
        WHERE LOWER(result) = 'won'
        UNION ALL
        SELECT year_of_award, title, production_year
        FROM ACTOR_AWARD
        WHERE LOWER(result) = 'won'
        UNION ALL
        SELECT year_of_award, title, production_year
        FROM CREW_AWARD
        WHERE LOWER(result) = 'won'
        UNION ALL
        SELECT year_of_award, title, production_year
        FROM WRITER_AWARD
        WHERE LOWER(result) = 'won'
        UNION ALL
        SELECT year_of_award, title, production_year
        FROM MOVIE_AWARD
        WHERE LOWER(result) = 'won'
    ) table1
JOIN (
        SELECT year_of_award, title, production_year
        FROM DIRECTOR_AWARD
        WHERE LOWER(result) = 'won'
        UNION ALL
        SELECT year_of_award, title, production_year
        FROM ACTOR_AWARD
        WHERE LOWER(result) = 'won'
        UNION ALL
        SELECT year_of_award, title, production_year
        FROM CREW_AWARD
        WHERE LOWER(result) = 'won'
        UNION ALL
        SELECT year_of_award, title, production_year
        FROM WRITER_AWARD
        WHERE LOWER(result) = 'won'
        UNION ALL
        SELECT year_of_award, title, production_year
        FROM MOVIE_AWARD
        WHERE LOWER(result) = 'won'
    ) table2
ON table1.year_of_award = table2.year_of_award
WHERE table1.title < table2.title
GROUP BY movie_a, movie_b;
