DO $$
BEGIN
    IF EXISTS (SELECT * FROM pg_proc WHERE proname = 'get_job_count') THEN
        DROP FUNCTION get_job_count(integer);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION get_job_count(p_emp_id integer)
RETURNS integer AS $$
DECLARE
    v_count int;
BEGIN
    -- Проверим сотрудника
    PERFORM 1 FROM employees WHERE employee_id = p_emp_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee ID % not found', p_emp_id;
    END IF;

    WITH all_jobs AS (
        SELECT job_id FROM job_history WHERE employee_id = p_emp_id
        UNION
        SELECT job_id FROM employees WHERE employee_id = p_emp_id
    )
    SELECT COUNT(*) INTO v_count FROM all_jobs;

    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова:
SELECT get_job_count(176);
