DROP TABLE IF EXISTS Subjects, Exams, Universities;
DROP TYPE IF EXISTS exam_semester, languages;
DROP DATABASE IF EXISTS session_big;


CREATE DATABASE session_big;
\connect session_big

CREATE TYPE exam_semester AS ENUM ('autumn', 'spring');
CREATE TYPE languages AS ENUM ('ENG', 'GR', 'FR');

CREATE TABLE IF NOT EXISTS Universities (
    university varchar(100),
    phone varchar(32),
    PRIMARY KEY (university)
);
COPY Universities(university, phone)
FROM '/home/maria/Desktop/postgre/generator_task3/output_data/universities_table.csv'
DELIMITER '	';

CREATE TABLE IF NOT EXISTS Subjects (
  subject_id SERIAL,
  university varchar(100),
  subject_name varchar(256),
  subject_description text,
  schooling_language languages
);
COPY Subjects(university, subject_name, subject_description, schooling_language)
FROM '/home/maria/Desktop/postgre/generator_task3/output_data/subjects_table.csv'
DELIMITER '	';
ALTER TABLE Subjects ADD PRIMARY KEY (subject_id);
ALTER TABLE Subjects ADD FOREIGN KEY (university) REFERENCES Universities(university) ON DELETE RESTRICT;


CREATE TABLE IF NOT EXISTS Exams (
    year integer,
    semester exam_semester,
    subject_id integer,
    marks json,
    examinators varchar(100)[]
);
COPY Exams(year, semester, subject_id, marks, examinators)
FROM '/home/maria/Desktop/postgre/generator_task3/output_data/exams_table.csv'
DELIMITER '	';
ALTER TABLE Exams ADD PRIMARY KEY (year, subject_id);
ALTER TABLE Exams ADD FOREIGN KEY (subject_id) REFERENCES Subjects(subject_id) ON DELETE RESTRICT;


ANALYZE;

SELECT subject_id, university, substring(subject_name for 50), 
substring(subject_description for 100), schooling_language FROM subjects LIMIT 1000;

--SELECT year, semester, subject_id, examinators FROM Exams LIMIT 500;
