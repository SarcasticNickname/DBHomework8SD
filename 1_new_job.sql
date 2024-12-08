DO $$
BEGIN
    -- Сначала удалим, если уже есть, чтобы можно было перезапустить скрипт
    IF EXISTS (SELECT * FROM pg_proc WHERE proname = 'new_job') THEN
        DROP FUNCTION new_job(varchar, varchar, integer);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION new_job(p_job_id varchar, p_job_title varchar, p_min_salary integer)
RETURNS void AS $$
BEGIN
    -- Проверяем, существует ли запись с таким же job_id
    IF NOT EXISTS (SELECT 1 FROM jobs WHERE job_id = p_job_id) THEN
        INSERT INTO jobs (job_id, job_title, min_salary, max_salary)
        VALUES (p_job_id, p_job_title, p_min_salary, p_min_salary * 2);
    ELSE
        RAISE NOTICE 'Job with ID % already exists.', p_job_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Выполнение пункта 1.b
SELECT new_job('SY_ANAL', 'System Analyst', 6000);
