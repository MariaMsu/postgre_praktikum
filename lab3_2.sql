--1--
\connect session_big
SET ROLE postgres;
REVOKE ALL ON Universities FROM test;
REVOKE ALL ON Subjects FROM test;
REVOKE ALL ON Exams From test;
DROP ROLE IF EXISTS test;
CREATE USER test WITH PASSWORD '123';
SELECT SESSION_USER, CURRENT_USER;

--2 и 5 и 6--
SET ROLE postgres;
GRANT SELECT, UPDATE, INSERT ON Exams TO test; 
GRANT SELECT(subject_id, university, schooling_language), UPDATE (schooling_language)
 ON Subjects TO test;
GRANT SELECT ON Universities TO test; 
SET ROLE test;
SELECT university FROM Subjects LIMIT 10;
-- ERROR:  permission denied for table subjects
--SELECT subject_name FROM Subjects LIMIT 10;
BEGIN;
SELECT subject_id, university, schooling_language FROM subjects WHERE subject_id = 11;
UPDATE subjects SET schooling_language='ENG' WHERE subject_id = 11;
-- ERROR:  permission denied for table subjects
--UPDATE subjects SET university='University of Southampton' WHERE subject_id = 11;
SELECT subject_id, university, schooling_language FROM subjects WHERE subject_id = 11;
ROLLBACK;

--3 и 5 и 7--
SET ROLE postgres;
DROP VIEW IF EXISTS universities_and_languages;
-- информация только о том, на каких языках ведется обучение в разных унивеситетах
CREATE VIEW universities_and_languages AS 
 SELECT DISTINCT university, schooling_language FROM Universities NATURAL JOIN Subjects;
GRANT SELECT ON universities_and_languages TO test;
SET ROLE test;
SELECT * FROM universities_and_languages LIMIT 10;

--4 и 7--
SET ROLE postgres;
DROP VIEW IF EXISTS only_subjects;
-- информация только о преподаваемых предметах, без уточнения деталей
CREATE VIEW only_subjects AS
 SELECT subject_id, subject_name, subject_description FROM Subjects;

DROP ROLE subject_owner;
CREATE ROLE subject_owner INHERIT;
GRANT UPDATE (subject_name, subject_description), 
 SELECT (subject_id, subject_name, subject_description) ON only_subjects TO subject_owner;

GRANT SELECT ON only_subjects TO test;
GRANT subject_owner TO test;
SET ROLE test;

BEGIN;
SELECT subject_id, subject_name FROM only_subjects WHERE subject_id = 11;
UPDATE only_subjects SET subject_name = 'The creativity of group System of a down' 
 WHERE subject_id = 11;
SELECT subject_id, subject_name FROM only_subjects WHERE subject_id = 11;
ROLLBACK;

