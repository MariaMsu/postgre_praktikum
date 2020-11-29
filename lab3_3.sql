 \connect session_big

DROP FUNCTION IF EXISTS Get_Average_Mark;
DROP FUNCTION IF EXISTS Get_Marks_Info;
DROP TYPE IF EXISTS type_exam_PK;

CREATE FUNCTION Get_Average_Mark(marks json) RETURNS numeric
AS $$
DECLARE
	single_mark integer;
	mars_sum numeric = 0;
	marks_count integer = 0;
	mark_info json;
	result_value numeric;
BEGIN
	FOR mark_info IN (SELECT value FROM json_each(marks)) LOOP
		SELECT mark_info::json->'mark' INTO single_mark;
			IF single_mark IS NULL THEN
			RAISE EXCEPTION 'The input json has incorrect format: no fild "mark"';
			END IF;
		mars_sum = mars_sum + single_mark;
		marks_count = marks_count + 1;
	END LOOP;

	IF marks_count=0 THEN
	RAISE EXCEPTION 'The input json can not has zero length';
	END IF;

	result_value =  mars_sum / marks_count;
	RETURN result_value;
END
$$ LANGUAGE plpgsql
IMMUTABLE;

------использование
SELECT marks FROM Exams WHERE year=2019 AND subject_id=6;
SELECT Get_Average_Mark((SELECT marks FROM Exams WHERE year=2019 AND subject_id=6));
------


CREATE TYPE type_exam_PK AS (
    year integer,
    subject_id integer
);

CREATE function Get_Marks_Info(ref_name refcursor, data_source type_exam_PK[]) 
	RETURNS refcursor
AS $$
DECLARE
	curs refcursor;
BEGIN
	OPEN ref_name FOR SELECT year, subject_name, university, Get_Average_Mark(marks) 
		FROM unnest(data_source) NATURAL JOIN Subjects NATURAL JOIN Exams;
	RETURN ref_name;
END
$$ LANGUAGE plpgsql;

------использование
BEGIN;
SELECT Get_Marks_Info('data_cur', array(
	SELECT ROW(year, subject_id)::type_exam_PK FROM Exams LIMIT 100));
FETCH ALL IN "data_cur";
ROLLBACK;
------






-- функция может возвращать войд, представление - нет. Функция может вернуть чиселку, а не таблицу, представление -нет. В пердставление в сложной таблице нельзя менять данные, в функции - можно. В функции ты можешь задавать аргументы и, вроде как, функции ты можешь несколько раз переиспользовать, а представления — нет.
-- курсор нужен, если искомое значение в начале таблицы и не надо мержить гигантсвкие таблицы: можно, проходя по каждой строке найти нужную. Курсор позволяет исполнять запрос по шагам, а не выполнять предложение сравзу для все гигантской ьаблицыЫ

