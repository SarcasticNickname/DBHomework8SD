DO $$
BEGIN
    IF EXISTS (SELECT * FROM pg_proc WHERE proname = 'get_years_service') THEN
        DROP FUNCTION get_years_service(integer);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION get_years_service(p_emp_id integer)
RETURNS integer AS $$
DECLARE
    v_hire_date date;
    v_total_days int := 0;
    v_years int;
BEGIN
    SELECT hire_date INTO v_hire_date FROM employees WHERE employee_id = p_emp_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee ID % not found', p_emp_id;
    END IF;

    -- Суммируем периоды из JOB_HISTORY
    SELECT COALESCE(SUM((end_date - start_date)),0) INTO v_total_days
    FROM job_history
    WHERE employee_id = p_emp_id;

    -- Добавим текущий период службы
    v_total_days := v_total_days + (CURRENT_DATE - v_hire_date);

    -- Переведём дни в годы приблизительно (деление на 365)
    v_years := floor(v_total_days / 365);
    RETURN v_years;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова:
SELECT get_years_service(999); -- не существует, выдаст исключение
SELECT get_years_service(106); -- покажет кол-во лет службы
