DO $$
BEGIN
    IF EXISTS (SELECT * FROM pg_proc WHERE proname = 'upd_jobsal') THEN
        DROP FUNCTION upd_jobsal(varchar, integer, integer);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION upd_jobsal(p_job_id varchar, p_min_sal integer, p_max_sal integer)
RETURNS void AS $$
DECLARE
    v_count int;
BEGIN
    IF p_max_sal < p_min_sal THEN
        RAISE EXCEPTION 'Maximum salary (%), is less than minimum salary (%)', p_max_sal, p_min_sal;
    END IF;

    SELECT COUNT(*) INTO v_count FROM jobs WHERE job_id = p_job_id;
    IF v_count = 0 THEN
        RAISE EXCEPTION 'Job ID % not found', p_job_id;
    END IF;

    BEGIN
        UPDATE jobs
        SET min_salary = p_min_sal, max_salary = p_max_sal
        WHERE job_id = p_job_id;
    EXCEPTION
        WHEN SQLSTATE '55P03' THEN  -- lock not available
            RAISE NOTICE 'The row in the JOBS table is locked and cannot be updated now.';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error: %', SQLERRM;
            RAISE;
    END;

END;
$$ LANGUAGE plpgsql;

-- Пример выполнения (3.b):
SELECT upd_jobsal('SY_ANAL', 7000, 140);  -- Будет ошибка, т.к. max_sal < min_sal или что-то подобное

-- (3.c) отключаем триггеры:
ALTER TABLE employees DISABLE TRIGGER ALL;
ALTER TABLE jobs DISABLE TRIGGER ALL;

-- (3.d) Повторный вызов:
SELECT upd_jobsal('SY_ANAL', 7000, 14000);

-- Проверить JOBS:
SELECT * FROM jobs WHERE job_id='SY_ANAL';

-- Закоммитить изменения, затем включить триггеры:
ALTER TABLE employees ENABLE TRIGGER ALL;
ALTER TABLE jobs ENABLE TRIGGER ALL;
