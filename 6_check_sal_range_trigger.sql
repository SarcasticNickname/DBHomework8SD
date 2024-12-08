DO $$
BEGIN
    IF EXISTS (SELECT * FROM pg_proc WHERE proname = 'check_sal_range_fn') THEN
        DROP FUNCTION check_sal_range_fn();
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION check_sal_range_fn()
RETURNS trigger AS $$
DECLARE
    v_count int;
BEGIN
    -- Проверяем, изменяются ли границы
    IF (NEW.min_salary IS DISTINCT FROM OLD.min_salary OR
        NEW.max_salary IS DISTINCT FROM OLD.max_salary) THEN
        -- Проверим есть ли сотрудники, выходящие за новый диапазон
        SELECT COUNT(*)
        INTO v_count
        FROM employees
        WHERE job_id = NEW.job_id
          AND (salary < NEW.min_salary OR salary > NEW.max_salary);

        IF v_count > 0 THEN
            RAISE EXCEPTION 'Cannot update salary range. Some employees have salaries outside the new range.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF EXISTS (SELECT * FROM pg_trigger WHERE tgname = 'check_sal_range') THEN
        DROP TRIGGER check_sal_range ON jobs;
    END IF;
END;
$$;

CREATE TRIGGER check_sal_range
BEFORE UPDATE ON jobs
FOR EACH ROW
EXECUTE FUNCTION check_sal_range_fn();

-- Тестирование:
-- До изменения проверить текущий диапазон и сотрудников:
SELECT * FROM jobs WHERE job_id='SY_ANAL';
SELECT employee_id, last_name, salary FROM employees WHERE job_id='SY_ANAL';

-- Попытка обновить:
UPDATE jobs SET min_salary=5000, max_salary=7000 WHERE job_id='SY_ANAL';

