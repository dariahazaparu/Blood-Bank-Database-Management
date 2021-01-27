CREATE OR REPLACE TYPE number_list IS
    TABLE OF NUMBER(4);
/

CREATE OR REPLACE TYPE char_list IS
    TABLE OF VARCHAR2(50);
/

CREATE TABLE bank_staff (
    bank_id   NUMBER(4)
);

ALTER TABLE bank_staff ADD (
    staff_list   number_list
)
NESTED TABLE staff_list STORE AS table_staff;

DESC bank_staff;

INSERT INTO blood_bank VALUES (
    sec_blood_bank.NEXTVAL,
    'Nume',
    1
);

CREATE OR REPLACE PROCEDURE staff_categories (
    to_address address.address_id%TYPE
) AS

    nr_address   NUMBER(4);
    lista_emp    number_list := number_list ();
    lista_bank   number_list := number_list ();
    lista_spec   char_list := char_list ();
    spec         staff_category.speciality%TYPE;
    ind          NUMBER(4) := 0;
    is_in_list   BOOLEAN;
    no_bank_found EXCEPTION;
    no_address_found EXCEPTION;
    no_staff EXCEPTION;
BEGIN
    SELECT
        COUNT(*)
    INTO nr_address
    FROM
        address
    WHERE
        address_id = to_address;

    IF
        nr_address = 0
    THEN
        RAISE no_address_found;
    END IF;
    SELECT
        bank_id
    BULK COLLECT
    INTO lista_bank
    FROM
        blood_bank
    WHERE
        address_id = to_address;

    IF
        lista_bank.count () = 0
    THEN
        RAISE no_bank_found;
    END IF;
    FOR i IN lista_bank.first..lista_bank.last LOOP
        SELECT
            staff_category_id
        BULK COLLECT
        INTO lista_emp
        FROM
            staff
        WHERE
            bank_id = lista_bank(i);

        INSERT INTO bank_staff VALUES (
            lista_bank(i),
            lista_emp
        );

        IF
            lista_emp.count () = 0
        THEN
            dbms_output.put_line('No one works at this bank -> ' || lista_bank(i) );
        ELSE
            FOR j IN lista_emp.first..lista_emp.last LOOP
                SELECT
                    speciality
                INTO spec
                FROM
                    staff_category
                WHERE
                    category_id = lista_emp(j);

                is_in_list := true;
                IF
                    lista_spec.count () <> 0
                THEN
                    FOR k IN lista_spec.first..lista_spec.last LOOP    
                        --dbms_output.put_line(lista_spec(k));
                        IF
                            lista_spec(k) = spec
                        THEN
                            is_in_list := false;
                        END IF;
                    END LOOP;
                END IF;

                IF
                    is_in_list = true
                THEN
                    ind := ind + 1;
                    lista_spec.extend ();
                    lista_spec(ind) := spec;
                END IF;

            END LOOP;
        END IF;

    END LOOP;

    FOR i IN lista_spec.first..lista_spec.last LOOP
        IF
            lista_spec(i) <> 'None'
        THEN
            dbms_output.put_line(lista_spec(i) );
        END IF;
    END LOOP;

EXCEPTION
    WHEN no_bank_found THEN
        raise_application_error(-20001,'No bank found at this address.');
    WHEN no_address_found THEN
        raise_application_error(-20002,'No address found');
    WHEN no_staff THEN
        raise_application_error(-20003,'No one works at this address.');
END;
/

DECLARE
    to_address   address.address_id%TYPE := '&address';
BEGIN
    staff_categories(to_address);
END;
/

SELECT
    *
FROM
    bank_staff;

ROLLBACK;


------------------

CREATE OR REPLACE PROCEDURE registered IS

    TYPE refcursor IS REF CURSOR;
    CURSOR conditions IS SELECT
        donor_id,
        d.condition_id,
        CURSOR (
            SELECT
                condition_name
            FROM
                medical_condition
            WHERE
                condition_id = d.condition_id
        )
                         FROM
        donor_condition d;

    CURSOR donor_reg IS SELECT
        bank_id,
        donor_id
                        FROM
        registration;

    v_cursor           refcursor;
    v_donor_id         donor.donor_id%TYPE;
    v_condition_id     medical_condition.condition_id%TYPE;
    v_condition_name   medical_condition.condition_name%TYPE;
    f_name             donor.first_name%TYPE;
    l_name             donor.last_name%TYPE;
BEGIN
    FOR i IN donor_reg LOOP
        EXIT WHEN donor_reg%notfound;
        FOR j IN (
            SELECT
                bank_id,
                donor_id,
                donation_id
            FROM
                donation
        ) LOOP
            IF
                i.bank_id = j.bank_id AND i.donor_id = j.donor_id
            THEN
                SELECT
                    first_name,
                    last_name
                INTO
                    f_name,
                    l_name
                FROM
                    donor
                WHERE
                    donor_id = i.donor_id;

                dbms_output.put(f_name
                                  || ' '
                                  || l_name
                                  || ' cu donatioa nr '
                                  || j.donation_id);

                OPEN conditions;
                LOOP
                    FETCH conditions INTO
                        v_donor_id,
                        v_condition_id,
                        v_cursor;
                    EXIT WHEN conditions%notfound;
                    IF
                        v_donor_id = i.donor_id
                    THEN
                        LOOP
                            FETCH v_cursor INTO v_condition_name;
                            EXIT WHEN v_cursor%notfound;
                            dbms_output.put(' ' || v_condition_name);
                        END LOOP;
                    END IF;

                END LOOP;

                CLOSE conditions;
                dbms_output.new_line;
            END IF;
        END LOOP;

    END LOOP;
END;
/

BEGIN
    registered;
END;
/



--------------------------

CREATE OR REPLACE FUNCTION get_staff (
    l_name staff.last_name%TYPE
) RETURN NUMBER IS
    to_id   staff.staff_id%TYPE;
BEGIN
    SELECT
        staff_id
    INTO to_id
    FROM
        staff
    WHERE
        last_name = initcap(l_name);

    RETURN to_id;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('No staff with this name found.');
    WHEN too_many_rows THEN
        dbms_output.put_line('More than one staff with this name.');
        FOR i IN (
            SELECT
                staff_id,
                first_name,
                last_name
            FROM
                staff
            WHERE
                last_name = initcap(l_name)
        ) LOOP
            dbms_output.put_line(i.first_name
                                   || ' '
                                   || i.last_name);
        END LOOP;

END;
/

CREATE OR REPLACE FUNCTION bank_max_donations RETURN VARCHAR2 IS
    bank     blood_bank.bank_id%TYPE;
    blood    blood_types.blood_id%TYPE;
    b_name   VARCHAR2(30);
BEGIN
    SELECT
        blood_id
    INTO blood
    FROM
        blood_types
    WHERE
        rh = 'negative'
        AND blood_id LIKE 'O%';

    SELECT
        bank_id
    INTO bank
    FROM
        donation
    WHERE
        blood_type = blood
    GROUP BY
        bank_id
    HAVING
        COUNT(*) = (
            SELECT
                MAX(COUNT(*) )
            FROM
                donation
            WHERE
                blood_type = blood
            GROUP BY
                bank_id
        );

    SELECT
        bank_name
    INTO b_name
    FROM
        blood_bank
    WHERE
        bank_id = bank;

    RETURN b_name;
EXCEPTION
    WHEN too_many_rows THEN
        raise_application_error(-20008,'There are more than one bank with the maximum donations number.');
END;
/

DECLARE
    n   VARCHAR2(30);
BEGIN
    n := bank_max_donations;
    dbms_output.put_line(n);
END;
/

--pentru a declansa exceptia

BEGIN
    FOR i IN 1..14 LOOP
        INSERT INTO donation VALUES (
            sec_donation.NEXTVAL,
            45,
            SYSDATE,
            'O-neg',
            1,
            'accepted'
        );

    END LOOP;
END;
/

ROLLBACK;

DELETE FROM donation
WHERE
    donation_id > 161;

---------------

CREATE OR REPLACE FUNCTION get_blood_id (
    blood blood_types.blood_group%TYPE
) RETURN char_list IS
    bloods   char_list;
    nr       NUMBER;
BEGIN
    SELECT
        COUNT(*)
    INTO nr
    FROM
        blood_types
    WHERE
        blood_group = blood;

    IF
        nr = 0
    THEN
        RAISE no_data_found;
    END IF;
    SELECT
        blood_id
    BULK COLLECT
    INTO bloods
    FROM
        blood_types
    WHERE
        blood_group = blood;

    RETURN bloods;
EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20006,'This group of blood does not exist.');
END;
/

DECLARE
    bloods   char_list;
BEGIN
    bloods := get_blood_id(2);
    --bloods := get_blood_id(5);
    FOR i IN bloods.first..bloods.last LOOP
        dbms_output.put_line(bloods(i) );
    END LOOP;

END;
/

CREATE OR REPLACE FUNCTION get_condition_id (
    condition medical_condition.condition_name%TYPE
) RETURN medical_condition.condition_id%TYPE IS
    condition_code   medical_condition.condition_id%TYPE;
BEGIN
    SELECT
        condition_id
    INTO condition_code
    FROM
        medical_condition
    WHERE
        condition_name = initcap(condition);

    RETURN condition_code;
EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20010,'No such condition found.');
    WHEN too_many_rows THEN
        raise_application_error(-20011,'More than one condition with this name');
END;
/

DECLARE
    condition_code   medical_condition.condition_id%TYPE;
BEGIN
    --condition_code := get_condition_id('alta conditie');
    --condition_code := get_condition_id('older vaccine');
    condition_code := get_condition_id('flu');
    dbms_output.put_line(condition_code);
END;
/

CREATE OR REPLACE PROCEDURE get_donations (
    condition   medical_condition.condition_name%TYPE,
    blood       blood_types.blood_group%TYPE
) IS

    blood_code       char_list := get_blood_id(blood);
    condition_code   medical_condition.condition_id%TYPE := get_condition_id(condition);
    donations        number_list := number_list ();
    donors           number_list := number_list ();
    banks            number_list := number_list ();
    nr               NUMBER;
    mt               NUMBER;
    ind              NUMBER := 0;
    b_name           blood_bank.bank_name%TYPE;
    no_donations_found EXCEPTION;
    no_donors_found EXCEPTION;
    no_banks_found EXCEPTION;
BEGIN
    dbms_output.put_line('Donations of blood type '
                           || blood
                           || ' made at banks where people with '
                           || condition
                           || ' are registred');

    dbms_output.put_line('----------------------------');
    FOR i IN (
        SELECT
            *
        FROM
            donation
    ) LOOP
        FOR j IN blood_code.first..blood_code.last LOOP
            IF
                i.blood_type = blood_code(j)
            THEN
                donations.extend;
                donations(donations.last) := i.donation_id;
            END IF;
        END LOOP;
    END LOOP;

    IF
        donations.count () = 0
    THEN
        RAISE no_donations_found;
    END IF;
    SELECT
        donor_id
    BULK COLLECT
    INTO donors
    FROM
        donor
    WHERE
        donor_id IN (
            SELECT
                donor_id
            FROM
                donor_condition
            WHERE
                condition_id = condition_code
        );

    IF
        donors.count () = 0
    THEN
        RAISE no_donors_found;
    END IF;
    FOR i IN donors.first..donors.last LOOP
        FOR j IN (
            SELECT
                *
            FROM
                registration
            WHERE
                donor_id = donors(i)
        ) LOOP
            banks.extend ();
            banks(banks.last) := j.bank_id;
        END LOOP;
    END LOOP;

    FOR i IN donations.first..donations.last LOOP
        SELECT
            bank_id
        INTO mt
        FROM
            donation
        WHERE
            donation_id = donations(i);

        FOR j IN banks.first..banks.last LOOP
            IF
                banks(j) = mt
            THEN
                SELECT
                    bank_name
                INTO b_name
                FROM
                    blood_bank
                WHERE
                    bank_id = banks(j);

                dbms_output.put_line('Donation '
                                       || donations(i)
                                       || ' from bank '
                                       || b_name);

                ind := ind + 1;
                EXIT;
            END IF;
        END LOOP;

    END LOOP;

    IF
        ind = 0
    THEN
        dbms_output.put_line('No donations.');
    END IF;
EXCEPTION
    WHEN no_donors_found THEN
        raise_application_error(-20012,'No donors with this condition found.');
    WHEN no_donations_found THEN
        raise_application_error(-20013,'No donations with this type of blood');
END;
/

CREATE TABLE donation_2
    AS
        ( SELECT
            *
          FROM
            donation
          WHERE
            donation_id < 10
        );

SELECT
    *
FROM
    donation_2;

BEGIN
    get_donations('Older vaccine',2);
END;
/

------------

CREATE TABLE no_of_donations (
    donor_id   NUMBER(4) PRIMARY KEY,
    nr         NUMBER(4)
);

CREATE OR REPLACE TRIGGER modify_no_of_donations AFTER
    INSERT ON donation
BEGIN
    FOR i IN (
        SELECT
            donor_id,
            COUNT(*) AS n
        FROM
            donation
        GROUP BY
            donor_id
    ) LOOP
        UPDATE no_of_donations
        SET
            nr = i.n
        WHERE
            donor_id = i.donor_id;

        IF
            SQL%notfound
        THEN
            INSERT INTO no_of_donations VALUES (
                i.donor_id,
                i.n
            );

        END IF;

    END LOOP;
END;
/

SELECT
    *
FROM
    no_of_donations;

SELECT
    *
FROM
    donation;

INSERT INTO donation VALUES (
    sec_donation.NEXTVAL,
    66,
    SYSDATE,
    'O-neg',
    5,DEFAULT
);

CREATE OR REPLACE TRIGGER no_blood BEFORE
    INSERT OR UPDATE OR DELETE ON blood_types
BEGIN
    raise_application_error(-20015,'Table not editable.');
END;
/

DELETE FROM blood_types
WHERE
    blood_id = 'O-neg';

CREATE OR REPLACE TRIGGER no_delete BEFORE
    DELETE ON donation
BEGIN
    raise_application_error(-20015,'Deleting is forbidden.');
END;
/

--------------

CREATE OR REPLACE TRIGGER update_status BEFORE
    INSERT ON donation
    FOR EACH ROW
DECLARE
    status_update   VARCHAR2(30);
    donor_code      NUMBER;
    conditions      number_list := number_list ();
    new_donation    NUMBER;
BEGIN
    donor_code :=:new.donor_id;
    SELECT
        condition_id
    BULK COLLECT
    INTO conditions
    FROM
        donor_condition
    WHERE
        donor_id = donor_code;

    IF
        conditions.count () <> 0
    THEN
        FOR i IN conditions.first..conditions.last LOOP
            SELECT
                approvement
            INTO status_update
            FROM
                medical_condition
            WHERE
                condition_id = conditions(i);

            IF
                status_update = 'declined'
            THEN
                raise_application_error(-20023,'Donatorul nu poate dona.');
            END IF;
        END LOOP;
    END IF;

END;
/

INSERT INTO donation VALUES (
    sec_donation.NEXTVAL,
    85,
    SYSDATE,
    'O-neg',
    5,DEFAULT
);

-----------------

CREATE TABLE actions (
    user_name     VARCHAR2(30),
    data_time     DATE,
    action_name   VARCHAR2(30),
    table_name    VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER put_actions AFTER CREATE OR ALTER OR DROP ON SCHEMA BEGIN
    INSERT INTO actions VALUES (
        user,
        SYSDATE,
        ora_sysevent,
        ora_dict_obj_name
    );

END;
/

DROP TABLE test_table;

CREATE TABLE test_table (
    coloana1   NUMBER(4)
);

SELECT
    *
FROM
    actions;
