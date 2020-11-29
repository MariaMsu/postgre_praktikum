--READ COMMITTED: возможно всё и чтение незафиксированных данных (но не в PG)
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SHOW transaction_isolation;
UPDATE groups
SET students_number = students_number + 2
WHERE group_id = 1;
SELECT * FROM groups WHERE group_id = 1; -- появились обновленные данные
-- 2
ROLLBACK; --откатываем изменения
-- 2
-----------------------
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM groups WHERE group_id = 1;
--не видит "грязных данных" из первого запроса, т.к. в PG READ COMMITTED = READ UNCOMMITTED
UPDATE groups
SET students_number = students_number + 1
WHERE group_id = 1;
--заблокируется и ждет окончания завершения 1
-- 1
-- перечитывает данные и добавляет еще 1, т.е. аномалии потерынных изменений не происходит
SELECT * FROM groups WHERE group_id = 1;
END;




--Read Committed: чтение только зафиксированных данных
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE groups
SET students_number = students_number + 2
WHERE group_id = 1;
SELECT * FROM groups WHERE group_id = 1; -- появились обновленные данные
-- 2
COMMIT;
-- 2
-------------
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT * FROM groups WHERE group_id = 1;--не видит "грязных данных" из первого запроса
UPDATE groups
SET students_number = students_number + 1
WHERE group_id = 1;
--заблокируется и ждет окончания завершения 1
-- 1
-- перечитывает данные и добавляет еще 1,
-- считанные данные отличаются, т.е. присутствубт неповторяющиеся чтения
SELECT * FROM groups WHERE group_id = 1;
END;




--Repeatable Read: недопускается неповторяющеся чтение данных,
-- снимок данных создается однократно перед выполнением первого запроса, а не укаждого
-- возмождно, транзакции придется запускать повторно (если в ней изменяются данные)
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM University_Subjects WHERE faculty='ФФ';
-- 2
SELECT * FROM University_Subjects WHERE faculty='ФФ';
--не появился предмет БД, т.к. данные не перчитываются
--запрос НЕ вернул ошибку, т.к. данные только считаываются, но не изменяются
--//--
--ошибка фантомного чтения. Изменился набор строк для условия WHERE faculty='ФФ
UPDATE University_Subjects SET type_of_control='credit' WHERE faculty='ФФ';
ROLLBACK;
--запросы из этой консольки не изменили состояния
SELECT * FROM University_Subjects WHERE faculty='ФФ';
-----------------
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
DELETE FROM University_Subjects WHERE subject_id='МолФиз';
SELECT * FROM University_Subjects WHERE faculty='ФФ';
END;
-- 1



--другой пример REPEATABLE READ
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM University_Subjects WHERE faculty='ФФ';
-- 2
--ошибка неповторяющегося чтения
UPDATE university_subjects SET duration_in_hours=duration_in_hours+15
    WHERE subject_id='КФ';
ROLLBACK;
------------------
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
UPDATE university_subjects SET duration_in_hours=duration_in_hours+12
    WHERE subject_id='КФ';
END;
-- 1



--Serializable: транзакции могут работать параллельно точно так же, как если бы они выполнялись последовательно
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE Session SET teacher_nick='s.pupkina' WHERE teacher_nick='p.dykonov';
SELECT * FROM Session;
--2
COMMIT;--завершится с ошибкой
--------------------------------
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE Session SET teacher_nick='p.dykonov' WHERE teacher_nick='i.ivanov';
SELECT * FROM Session;
END;
-- 1

--другой пример на SERIALIZABLE
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
--дьяконов съездил в китай и его надо посадить на карантин
UPDATE Session SET lecture_hall='zoom.com' WHERE teacher_nick='p.dykonov';
SELECT * FROM Session;
--2
COMMIT;--завершится с ошибкой,
-- т.к. изменился набор строк, удовлетворяюший условию teacher_nick='p.dykonov'
-----------------------------
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
--иванов заболел, меняем его на дьяконова
UPDATE Session SET teacher_nick='p.dykonov' WHERE teacher_nick='i.ivanov';
SELECT * FROM Session;
END;


--Триггер, проверка
--преподаватель может уволиться
SELECT * FROM session WHERE teacher_nick='p.dykonov';
UPDATE teachers SET teacher_quit = TRUE WHERE teacher_nick='p.dykonov';

--преподователь не может уволиться
UPDATE session SET exam_date='2020-11-02' WHERE group_id=5 AND subject_id='MA2';
SELECT * FROM session WHERE teacher_nick='i.ivanov';
UPDATE teachers SET teacher_quit = TRUE WHERE teacher_nick='i.ivanov';
