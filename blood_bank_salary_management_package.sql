
CREATE OR REPLACE PACKAGE salary_management IS
    PROCEDURE set_default;

    PROCEDURE upgrade_salary (
        bank         blood_bank.bank_name%TYPE,
        categ_name   staff_category.category_name%TYPE
    );

    PROCEDURE upgrade_salary (
        spec   staff_category.speciality%TYPE,
        exp    staff.experience%TYPE
    );

    FUNCTION get_bank_id (
        bank blood_bank.bank_name%TYPE
    ) RETURN blood_bank.bank_id%TYPE;

    FUNCTION get_category_id (
        categ staff_category.category_name%TYPE
    ) RETURN number_list;

    FUNCTION get_category_id_from_spec (
        categ staff_category.speciality%TYPE
    ) RETURN number_list;

END salary_management;
/

CREATE OR REPLACE PACKAGE BODY salary_management IS

    PROCEDURE set_default IS
        id_categ   staff_category.category_id%TYPE;
        spec       staff_category.category_name%TYPE;
    BEGIN
        FOR i IN (
            SELECT
                *
            FROM
                staff
        ) LOOP
            SELECT
                staff_category_id
            INTO id_categ
            FROM
                staff
            WHERE
                staff_id = i.staff_id;

            SELECT
                category_name
            INTO spec
            FROM
                staff_category
            WHERE
                category_id = id_categ;

            IF
                spec = 'Doctor'
            THEN
                UPDATE staff
                SET
                    salary = 10000
                WHERE
                    staff_id = i.staff_id;

            ELSIF spec = 'Nurse' THEN
                UPDATE staff
                SET
                    salary = 5000
                WHERE
                    staff_id = i.staff_id;

            ELSIF spec = 'Resident' THEN
                UPDATE staff
                SET
                    salary = 4000
                WHERE
                    staff_id = i.staff_id;

            ELSIF spec = 'None' THEN
                UPDATE staff
                SET
                    salary = 2000
                WHERE
                    staff_id = i.staff_id;

            END IF;

        END LOOP;
    END;

    FUNCTION get_bank_id (
        bank blood_bank.bank_name%TYPE
    ) RETURN blood_bank.bank_id%TYPE IS
        b_id   blood_bank.bank_id%TYPE;
    BEGIN
        SELECT
            bank_id
        INTO b_id
        FROM
            blood_bank
        WHERE
            bank_name = initcap(bank);

        RETURN b_id;
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20015,'No bank found.');
        WHEN too_many_rows THEN
            raise_application_error(-20016,'Too many banks with this name.');
    END;

    FUNCTION get_category_id (
        categ staff_category.category_name%TYPE
    ) RETURN number_list IS
        categ_id   number_list;
    BEGIN
        SELECT
            category_id
        BULK COLLECT
        INTO categ_id
        FROM
            staff_category
        WHERE
            category_name = initcap(categ);

        IF
            categ_id.count () = 0
        THEN
            RAISE no_data_found;
        END IF;
        RETURN categ_id;
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20015,'No category found.');
    END;

    PROCEDURE upgrade_salary (
        bank         blood_bank.bank_name%TYPE,
        categ_name   staff_category.category_name%TYPE
    ) IS

        b_id         blood_bank.bank_id%TYPE := get_bank_id(bank);
        categ_list   number_list := get_category_id(categ_name);
        categ        staff.staff_category_id%TYPE;
        to_upgrade   BOOLEAN;
    BEGIN
        FOR i IN (
            SELECT
                *
            FROM
                staff
        ) LOOP
            SELECT
                staff_category_id
            INTO categ
            FROM
                staff
            WHERE
                staff_id = i.staff_id;

            to_upgrade := false;
            FOR j IN categ_list.first..categ_list.last LOOP
                IF
                    categ_list(j) = categ
                THEN
                    to_upgrade := true;
                END IF;
            END LOOP;

            IF
                to_upgrade = true
            THEN
                UPDATE staff
                SET
                    salary = salary * 1.1
                WHERE
                    staff_id = i.staff_id
                    AND bank_id = b_id;

            END IF;

        END LOOP;
    END;

    FUNCTION get_category_id_from_spec (
        categ staff_category.speciality%TYPE
    ) RETURN number_list IS
        categ_list   number_list;
    BEGIN
        SELECT
            category_id
        BULK COLLECT
        INTO categ_list
        FROM
            staff_category
        WHERE
            speciality = categ;

        IF
            categ_list.count () = 0
        THEN
            RAISE no_data_found;
        END IF;
        RETURN categ_list;
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20016,'No such speciality.');
    END;

    PROCEDURE upgrade_salary (
        spec   staff_category.speciality%TYPE,
        exp    staff.experience%TYPE
    ) IS

        categ        staff.staff_category_id%TYPE;
        to_upgrade   BOOLEAN;
        categ_list   number_list := get_category_id_from_spec(spec);
        no_staff_in_categ EXCEPTION;
    BEGIN
        FOR i IN (
            SELECT
                *
            FROM
                staff
        ) LOOP
            SELECT
                staff_category_id
            INTO categ
            FROM
                staff
            WHERE
                staff_id = i.staff_id;

            IF
                categ_list.count () > 0
            THEN
                to_upgrade := false;
                FOR j IN categ_list.first..categ_list.last LOOP
                    IF
                        categ_list(j) = categ
                    THEN
                        to_upgrade := true;
                    END IF;
                END LOOP;

                IF
                    to_upgrade = true
                THEN
                    UPDATE staff
                    SET
                        salary = salary * 1.3
                    WHERE
                        staff_id = i.staff_id
                        AND i.experience > exp;

                END IF;

            END IF;

        END LOOP;
    END;

END salary_management;
/

DECLARE
    x   NUMBER;
begin
    --salary_management.set_default;
    --dbms_output.put_line(salary_management.get_bank_id('Romanian Red Cross'));
    --salary_management.upgrade_salary('Romanian Red Cross', 'Nurs');
    salary_management.upgrade_salary('OBGYN', 10);
end;
/

ROLLBACK;
