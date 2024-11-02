\pset tuples_only on
\set string '\'801dfffffffffff\''
\set asbigint 576988517884755967
\set hexagon ':string::h3index'
\set pentagon '\'844c001ffffffff\'::h3index'

--
-- TEST operators
--
SELECT :hexagon = :hexagon;
SELECT NOT :hexagon = :pentagon;
SELECT NOT :hexagon <> :hexagon;
SELECT :hexagon <> :pentagon;
SELECT :pentagon <@ h3_cell_to_parent(:pentagon);
SELECT bool_and(:pentagon @> c) FROM (
    SELECT h3_cell_to_children(:pentagon) c
) q;

--
-- TEST bigint casting
--
SELECT :asbigint = :hexagon::bigint;

SELECT :hexagon = :asbigint::h3index;

--
-- TEST binary io
--
CREATE OR REPLACE FUNCTION copy_to_and_from_file(index h3index) RETURNS BOOLEAN LANGUAGE PLPGSQL AS
$$
DECLARE
    result BOOL;
BEGIN
    CREATE TEMPORARY TABLE from_temp (val h3index);
    INSERT INTO from_temp (val) VALUES (index);
    CREATE TEMPORARY TABLE to_tmp (val h3index);
    IF (
        SELECT CASE setting WHEN 'windows' THEN true ELSE false END AS isWindows
        FROM pg_catalog.pg_file_settings
        WHERE name = 'dynamic_shared_memory_type'
    )
    THEN
        COPY (SELECT val FROM from_temp) TO 'D:\a\h3-pg\test.bin' (FORMAT binary);
        COPY to_tmp FROM 'D:\a\h3-pg\test.bin' (FORMAT binary);
    ELSE
        COPY (SELECT val FROM from_temp) TO '/tmp/test.bin' (FORMAT binary);
        COPY to_tmp FROM '/tmp/test.bin' (FORMAT binary);
    END IF;

    SELECT val = index into result FROM to_tmp WHERE val = index;
    RETURN result;
END;
$$;
SELECT copy_to_and_from_file(:hexagon);
