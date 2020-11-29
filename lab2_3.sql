-- все преподаватели, которые принимают экзамены на ВМК в 3 семестре
SELECT DISTINCT teacher_nick, teacher_name, email
FROM Groups NATURAL JOIN Session NATURAL JOIN Teachers
WHERE faculty='ВМК' AND term=3 AND exam_in_current_term_flag;


-- все преподаватели, которые не принимают экзамены в текущем семестре
SELECT Teachers.* FROM Teachers
EXCEPT
SELECT Teachers.* FROM Session NATURAL JOIN Teachers WHERE exam_in_current_term_flag
ORDER BY university_department, teacher_name;


-- преподователи и предметы, котрые они принимали
SELECT DISTINCT teacher_nick, teacher_name, subject_name, faculty
FROM Teachers NATURAL JOIN Session NATURAL JOIN University_Subjects
ORDER BY teacher_name, subject_name;



-- вычеркиваем из запланированного на текущий семестр расписания уволившихся преподавателей и с
-- двигаем на 3 недели экзамены, поставленные на этих преподавателей. Список изменений выводим
UPDATE Teachers SET teacher_quit = TRUE WHERE teacher_nick = 'p.dykonov';
WITH Updated_Session AS (
    UPDATE Session SET teacher_nick = NULL, exam_date = exam_date + integer '21'
        FROM Teachers WHERE Session.teacher_nick = Teachers.teacher_nick AND teacher_quit AND exam_in_current_term_flag
    RETURNING group_id, subject_id, exam_date AS "new_exam_date"
)
SELECT group_id, subject_id, lecture_hall, new_exam_date, teacher_nick as "deprecated_teacher_nick",
       exam_date AS "deprecated_exam_date" FROM Updated_Session NATURAL JOIN Session;
-- при попытке поставить экзамен на преподавателя, которого нет в таблице Teachers, будет ОШИБКА
UPDATE Session SET teacher_nick = 'k.vetrov' WHERE teacher_nick IS NULL;


-- переносим в удаленный формат все зачёты и выводим список преподаватей, которых это затронуло
WITH Reomote_Credit(teacher_nick, exam_date) AS (
UPDATE Session SET lecture_hall = 'zoom.com'
FROM University_Subjects WHERE Session.subject_id = University_Subjects.subject_id
                           AND  type_of_control = 'credit'
                           AND exam_in_current_term_flag
    RETURNING teacher_nick, exam_date
)
SELECT DISTINCT teacher_nick, teacher_name, email, exam_date FROM Reomote_Credit NATURAL JOIN Teachers;


-- ОШИБКА попытка расформировать физфак и удалить все предметы.
-- Запрос не выполняется, пока таблица Session ссылаются на удалеяемы строки из University_Subjects
WITH Removed_Subjects AS (
DELETE FROM University_Subjects WHERE faculty = 'ФФ' RETURNING *
)
SELECT * FROM Removed_Subjects;
