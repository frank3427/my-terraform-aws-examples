-- CREATE OR REPLACE FUNCTION random_name(nb_chars INT)
--     RETURNS VARCHAR
--     LANGUAGE plpgsql
-- AS
-- $$
-- BEGIN
--    RETURN(
--         SELECT array_to_string(ARRAY(SELECT chr((97 + round(random() * 25)) :: INTEGER)
--         FROM generate_series(1,nb_chars)), '')
--         );
-- END;
-- $$;

-- CREATE OR REPLACE FUNCTION generate_first_names(nb INT)
--     RETURNS VARCHAR
--     LANGUAGE plpgsql
-- AS
-- $$
-- BEGIN
--    RETURN(
--         SELECT 
--             (SELECT * FROM random_name(10))
--         FROM generate_series(1,12);
--         );
-- END;
-- $$;

INSERT INTO tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date)
VALUES (1, 'Christophe','Pauliat','2022-10-03');

INSERT INTO tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date)
VALUES (2, 'Jean','Bon','2021-10-03');

INSERT INTO tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date)
VALUES (3, 'Pierre','Martin','2020-12-30');

INSERT INTO tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date)
VALUES (generate_series(4,1000), md5(random()::text), md5(random()::text), '2023-07-07');
