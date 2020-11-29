DROP TABLE IF EXISTS Session, Groups, University_Subjects, Teachers;
DROP TYPE IF EXISTS control_types;
DROP DATABASE IF EXISTS sessions_database;


CREATE DATABASE sessions_database;
\connect sessions_database

CREATE TYPE control_types AS ENUM ('exam', 'credit');

CREATE TABLE Teachers (
 teacher_nick varchar(32),
 teacher_name varchar(100) NOT NULL,
 university_department varchar(100) NOT NULL,
 email varchar(100) UNIQUE,
 teacher_quit BOOLEAN DEFAULT FALSE,
 PRIMARY KEY (teacher_nick)
);

CREATE TABLE University_Subjects (
 subject_id varchar(32),
 faculty varchar(100) NOT NULL,
 term smallint CHECK (0 < term AND term < 15),
 subject_name varchar(100),
 course_language varchar(32) DEFAULT 'RUS',
 duration_in_hours integer CHECK (duration_in_hours > 0),
 type_of_control control_types NOT NULL,
 PRIMARY KEY (subject_id)
);

CREATE TABLE Groups (
 group_id SERIAL,
 faculty varchar(100) NOT NULL,
 term smallint CHECK (0 < term AND term < 15),
 students_number integer CHECK (students_number > 0),
 PRIMARY KEY (group_id)
);

CREATE TABLE Session (
 group_id integer REFERENCES Groups  ON DELETE CASCADE,
 subject_id varchar(32) REFERENCES University_Subjects  ON DELETE RESTRICT,
 teacher_nick varchar(32) REFERENCES Teachers  ON DELETE RESTRICT ON UPDATE CASCADE,
 exam_date date,
 lecture_hall varchar(32),
 exam_in_current_term_flag boolean DEFAULT true,
 PRIMARY KEY (group_id, subject_id),
 UNIQUE (group_id, exam_date)
);


CREATE OR REPLACE FUNCTION quit_teacher() RETURNS trigger AS $quit_teacher$
    -- может уволиться только тот учитель, у которого в ближайшее время нет экзаменов
    BEGIN
        IF OLD.teacher_quit = FALSE AND NEW.teacher_quit = TRUE THEN
            IF (SELECT min(exam_date-current_date) < 28 FROM session WHERE teacher_nick=NEW.teacher_nick) THEN
                 RAISE EXCEPTION
                     'the teacher who takes an exam within the next 4 weeks cannot be dismissed, nearest exam is %',
                     (SELECT min(exam_date) FROM session WHERE teacher_nick=NEW.teacher_nick);
            END IF;
        END IF;
        RAISE INFO 'number of affected groups: %',
            (SELECT count(*) FROM session WHERE teacher_nick=NEW.teacher_nick AND exam_in_current_term_flag);
        UPDATE Session SET teacher_nick=NULL WHERE teacher_nick=NEW.teacher_nick AND exam_in_current_term_flag;
        RETURN NEW;
    END;
$quit_teacher$ LANGUAGE plpgsql;

CREATE TRIGGER emp_stamp BEFORE UPDATE OF teacher_quit ON Teachers
    FOR EACH ROW EXECUTE FUNCTION quit_teacher();



INSERT INTO Teachers (teacher_nick, teacher_name, university_department, email) VALUES
('a.stolarov', 'Столяров', 'ВМК', 's@server.com'),
('p.dykonov', 'Дьяконов', 'ВМК', 'la-la@msu.com'),
('g.bahtin', 'Бахтин', 'ВМК', 't123@msu.com'),
('s.pupkina', 'Пупкина', 'ВМК', 'hoshka@ya.ru'),
('a.raevskaya', 'Раевская', 'ВМК', 'qwerty@server.com'),
('i.ivanov', 'Иванов', 'ВМК', 'aaa@google.com'),
('v.petuhov', 'Петухов', 'ВМК', NULL),
('s.ivannikov', 'Иванников', 'ФФ', 'bbb@google.com'),
('k.maysuradze', 'Майсурадзе', 'ФФ', 'prepod@google.com'),
('p.trepetova', 'Трепетова', 'ФФ', 'kiska@server.com'),
('m.ziganov', 'Циганов', 'ФФ', 'ivanov@server.com'),
('a.solomatina', 'Соломатин', 'ФФ', 'dyakonaov@server.com'),
('a.sorokina', 'Сорокина', 'ФФ', NULL);

INSERT INTO University_Subjects (subject_id, faculty, term, subject_name, duration_in_hours, type_of_control) VALUES
('MA1', 'ВМК', 1, 'мат. анализ 1', 40, 'exam'),
('MA2', 'ВМК', 2, 'мат. анализ 2', 40, 'exam'),
('MA3', 'ВМК', 3, 'мат. анализ 3', 40, 'exam'),
('MA4', 'ВМК', 4, 'мат. анализ 4', 40, 'exam'),
('КлМех', 'ВМК', 3, 'классическая механника', 30, 'exam'),
('ЭД', 'ВМК', 4, 'электродинамика', 30, 'credit'),
('РЯ', 'ВМК', 2, 'русский язык', 20, 'exam'),
('история', 'ВМК', 1, 'история', 20, 'exam'),
('СМ', 'ФФ', 1, 'сопротивление материалов', 60, 'exam'),
('КФ', 'ФФ', 2, 'квантовая физика', 60, 'credit'),
('МолФиз', 'ФФ', 2, 'молекулярная физика', 60, 'credit');

INSERT INTO Groups (faculty, term, students_number) VALUES
('ВМК', 1, 15),
('ВМК', 1, 13),
('ВМК', 1, 15),
('ВМК', 1, 12),
('ВМК', 2, 11),
('ВМК', 2, 9),
('ВМК', 2, 8),
('ВМК', 3, 18),
('ВМК', 3, 19),
('ВМК', 3, 15),
('ВМК', 3, 18),
('ФФ', 1, 11),
('ФФ', 1, 12),
('ФФ', 1, 20),
('ФФ', 1, 21),
('ФФ', 1, 13),
('ФФ', 1, 17),
('ФФ', 2, 16),
('ФФ', 2, 19),
('ФФ', 2, 11),
('ФФ', 2, 11),
('ФФ', 2, 12),
('ВМК', 4, 17);

INSERT INTO Session (group_id, subject_id, teacher_nick, exam_date, lecture_hall) VALUES
(1, 'MA1', 'p.dykonov', '2021-01-03', 'П-8а'),
(2, 'MA1', 'p.dykonov', '2021-01-02', 'П-9'),
(3, 'MA1', 'p.dykonov', '2021-01-03', 'П-8а'),
(4, 'MA1', 'p.dykonov', '2021-01-02', 'П-9'),
(5, 'MA2', 'i.ivanov', '2021-01-02', 'П-5'),
(6, 'MA2', 'i.ivanov', '2021-01-02', 'П-5'),
(7, 'MA2', 'i.ivanov', '2021-01-02', 'П-5'),
(8, 'MA3', NULL, '2021-01-03', 'П-8а'),
(9, 'MA3', NULL, '2021-01-10', 'П-7'),
(10, 'MA3', 's.pupkina', '2021-01-10', 'П-7'),
(11, 'СМ', 'a.solomatina', '2021-01-11', 'Г-1'),
(12, 'СМ', 'a.solomatina', '2021-01-11', 'Г-1'),
(13, 'СМ', 'm.ziganov', '2021-01-03', 'Г-2'),
(14, 'СМ', 'm.ziganov', '2021-01-03', 'Г-2'),
(15, 'СМ', 'm.ziganov', '2021-01-03', 'Г-2'),
(16, 'КФ', 's.ivannikov', '2021-01-04', 'Г_1'),
(17, 'КФ', 's.ivannikov', '2021-01-04', 'Г-1'),
(18, 'КФ', 'k.maysuradze', '2021-01-07', 'K-12'),
(19, 'КФ', 'k.maysuradze', '2021-01-07', 'K-12'),
(20, 'КФ', 'k.maysuradze', '2021-01-07', 'K-12');
