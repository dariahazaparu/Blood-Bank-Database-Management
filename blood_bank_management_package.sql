CREATE OR REPLACE PACKAGE blood_bank_management IS
    PROCEDURE staff_categories (
        to_address address.address_id%TYPE
    );

    PROCEDURE registered;

    FUNCTION get_staff (
        l_name staff.last_name%TYPE
    ) RETURN NUMBER;

    FUNCTION bank_max_donations RETURN VARCHAR2;

    FUNCTION get_blood_id (
        blood blood_types.blood_group%TYPE
    ) RETURN char_list;

    FUNCTION get_condition_id (
        condition medical_condition.condition_name%TYPE
    ) RETURN medical_condition.condition_id%TYPE;

    PROCEDURE get_donations (
        condition   medical_condition.condition_name%TYPE,
        blood       blood_types.blood_group%TYPE
    );

END blood_bank_management;
/

CREATE OR REPLACE PACKAGE BODY blood_bank_management IS

    PROCEDURE staff_categories (
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

    PROCEDURE registered IS

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

    FUNCTION get_staff (
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

    FUNCTION bank_max_donations RETURN VARCHAR2 IS
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

    FUNCTION get_blood_id (
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

    FUNCTION get_condition_id (
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

    PROCEDURE get_donations (
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

END blood_bank_management;
/