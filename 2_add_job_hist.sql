DO $$
BEGIN
    IF EXISTS (SELECT * FROM pg_proc WHERE proname = 'add_job_hist') THEN
        DROP FUNCTION add_job_hist(integer, varchar);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION add_job_hist(p_emp_id integer, p_new_job_id varchar)
RETURNS void AS $$
DECLARE
    v_first_hire_date date;
    v_current_job_id varchar;
    v_min_salary integer;
    v_old_hire_date date;
BEGIN
    -- Проверим наличие сотрудника
    SELECT hire_date, job_id INTO v_old_hire_date, v_current_job_id
    FROM employees
    WHERE employee_id = p_emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee with ID % not found', p_emp_id;
    END IF;

    -- Получим min_salary для новой должности
    SELECT min_salary INTO v_min_salary
    FROM jobs
    WHERE job_id = p_new_job_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Job ID % not found', p_new_job_id;
    END IF;

    -- Вставляем запись в JOB_HISTORY
    INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
    VALUES (p_emp_id, v_old_hire_date, CURRENT_DATE, v_current_job_id,
       (SELECT department_id FROM employees WHERE employee_id = p_emp_id));

    -- Обновляем EMPLOYEES для сотрудника
    UPDATE employees
    SET hire_date = CURRENT_DATE,
        job_id = p_new_job_id,
        salary = v_min_salary + 500
    WHERE employee_id = p_emp_id;

    -- Задание просит отключить триггеры перед вызовом, затем включить после. Это можно сделать вручную в DataGrip:
    --  ALTER TABLE employees DISABLE TRIGGER ALL;
    --  ALTER TABLE jobs DISABLE TRIGGER ALL;
    --  ALTER TABLE job_history DISABLE TRIGGER ALL;

    -- После выполнения:
    --  SELECT add_job_hist(106, 'SY_ANAL');

    -- Проверить изменения:
    -- SELECT * FROM job_history WHERE employee_id=106;
    -- SELECT * FROM employees WHERE employee_id=106;

    -- Потом снова включить триггеры:
    --  ALTER TABLE employees ENABLE TRIGGER ALL;
    --  ALTER TABLE jobs ENABLE TRIGGER ALL;
    --  ALTER TABLE job_history ENABLE TRIGGER ALL;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'An error occurred: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова:
-- Перед вызовом отключите триггеры:
ALTER TABLE employees DISABLE TRIGGER ALL;
ALTER TABLE jobs DISABLE TRIGGER ALL;
ALTER TABLE job_history DISABLE TRIGGER ALL;

SELECT add_job_hist(106, 'SY_ANAL');

ALTER TABLE employees ENABLE TRIGGER ALL;
ALTER TABLE jobs ENABLE TRIGGER ALL;
ALTER TABLE job_history ENABLE TRIGGER ALL;
