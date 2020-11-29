\connect session_big

--  relkind = обычная таблица (Relation), i = индекс (Index),
SELECT relname, relkind, reltuples, relpages FROM pg_class
	WHERE relname IN ('subjects', 'exams', 'universities');

DROP INDEX IF EXISTS _gin_exams_examinators;
DROP INDEX IF EXISTS _gin_subjects_subject_description;
DROP INDEX IF EXISTS _btree_exams_avarege_mark;

---------------------------FILTERING ARRAY
EXPLAIN ANALYZE
SELECT year, semester, subject_id, examinators FROM Exams 
	WHERE examinators@>ARRAY['Trueman Dunnaway']::varchar[] AND year < 2000;

CREATE INDEX _gin_exams_examinators ON Exams USING GIN(examinators);
/* Было
(cost=1000.00..2764011.95 rows=150026 width=71)
(actual time=3516.164..99638.178 rows=11 loops=1)

Стало
(cost=3304.51..1016233.71 rows=150033 width=71)
(actual time=90.005..159.015 rows=11 loops=1)*/


--------------------------FULL TEXT SEARCH
EXPLAIN ANALYZE 
SELECT subject_id, subject_name, university, array_agg(DISTINCT unnested_examinators.v)
	FROM (Exams CROSS JOIN unnest(examinators) AS unnested_examinators(v)) 
		NATURAL JOIN Subjects NATURAL JOIN Universities 
	WHERE to_tsvector('english', subject_description) @@ to_tsquery('Navalny & Americans')  
		AND schooling_language='ENG'
	GROUP BY subject_id, subject_name, university;

CREATE INDEX _gin_subjects_subject_description ON Subjects USING GIN(to_tsvector('english', subject_description));
/*Было
(cost=3029454.91..3029667.23 rows=8493 width=96)
(actual time=207298.296..207314.838 rows=1 loops=1)

Стало
(cost=2700507.48..2700719.98 rows=8500 width=96)
(actual time=64203.941..64209.480 rows=1 loops=1)*/


--------------------------FILTERING JSON
EXPLAIN ANALYZE 
SELECT year, semester, subject_id, (marks#>>'{Margit Nekrews, mark}')::int FROM Exams 
WHERE (marks#>>'{Margit Nekrews, mark}')::int > 2; 

CREATE INDEX _btree_exams_margit_marks 
	ON Exams (((marks#>>'{Margit Nekrews, mark}')::int )) 
	WHERE (marks->>'Margit Nekrews') IS NOT NULL;
/*
(cost=0.00..3435524.00 rows=16666667 width=12)
(actual time=4623.606..186255.830 rows=18 loops=1)
*/



EXPLAIN ANALYZE 
SELECT year, semester, subject_id, average_mark 
	FROM Exams CROSS JOIN Get_Average_Mark(marks) AS a_m(average_mark) 
	WHERE average_mark > 9.5; 

CREATE INDEX _btree_exams_avarege_mark ON Exams ((Get_Average_Mark(marks)));

/*Было
(cost=0.25..4060524.25 rows=50000000 width=44)
(actual time=76.331..2161827.962 rows=574359 loops=1)

Стало
(cost=0.25..4060524.25 rows=50000000 width=44)
(actual time=76.331..2161827.962 rows=574359 loops=1)
*/




----------------------TABLE PARTITION
CREATE TABLE IF NOT EXISTS Exams_parted (
    year integer,
    semester exam_semester,
    subject_id integer,
    marks json,
    examinators varchar(100)[],
    PRIMARY KEY (year, subject_id)
) PARTITION BY RANGE (year);

CREATE TABLE IF NOT EXISTS Exams_begin_to_2015
	PARTITION OF Exams_parted FOR VALUES FROM (0) TO (2015);

CREATE TABLE IF NOT EXISTS Exams_2015_to_2020
	PARTITION OF Exams_parted FOR VALUES FROM (2015) TO (2020);
	
INSERT INTO Exams_parted (year, semester, subject_id, marks, examinators) 
	SELECT * FROM Exams;
	
ANALYZE;

CREATE INDEX _bree_exams_parted_year ON Exams_parted(year);
CREATE INDEX _bree_exams_2015_to_2020_year ON Exams_2015_to_2020(year);

EXPLAIN ANALYZE
SELECT count(*) FROM Exams WHERE subject_id=200 AND year=2019;
EXPLAIN ANALYZE
SELECT count(*) FROM Exams_parted WHERE subject_id=200 AND year=2019;
EXPLAIN ANALYZE
SELECT count(*) FROM Exams_2015_to_2020 WHERE subject_id=200 AND year=2019;
/* анализ запросов соответственно:
(cost=8.59..8.60 rows=1 width=8)
(actual time=3.707..3.709 rows=1 loops=1)

(cost=8.45..8.46 rows=1 width=8)
(actual time=0.086..0.087 rows=1 loops=1)

(cost=8.45..8.46 rows=1 width=8)
(actual time=0.018..0.018 rows=1 loops=1)
*/

