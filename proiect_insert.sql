------Address
CREATE TABLE address (
    address_id        NUMBER(4) PRIMARY KEY,
    street_name       VARCHAR2(30) NOT NULL,
    building_number   NUMBER(4),
    city              VARCHAR2(30) NOT NULL
);

CREATE SEQUENCE sec_address MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE;

INSERT INTO address VALUES (
    sec_address.NEXTVAL,
    'Piata Unirii',
    '5',
    'Bucuresti'
);

INSERT INTO address VALUES (
    sec_address.NEXTVAL,
    'Splaiul Independentei',
    '10',
    'Bucuresti'
);

INSERT INTO address VALUES (
    sec_address.NEXTVAL,
    'Calea Victoriei',
    '1',
    'Brasov'
);

INSERT INTO address VALUES (
    sec_address.NEXTVAL,
    'Aleea Cu Flori',
    '20',
    'Cluj'
);

INSERT INTO address VALUES (
    sec_address.NEXTVAL,
    'Valea Oltului',
    '105',
    'Craiova'
);

SELECT
    *
FROM
    address;


--Staff category

CREATE TABLE staff_category (
    category_id     NUMBER(4) PRIMARY KEY,
    category_name   VARCHAR2(30) NOT NULL,
    speciality      VARCHAR2(30) DEFAULT 'None',
    CONSTRAINT u_1 UNIQUE ( category_name,
                            speciality )
);

CREATE SEQUENCE sec_staff_category MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE;

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Doctor',
    'Cardiology'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Nurse',
    'Cardiology'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Resident',
    'Cardiology'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Doctor',
    'General'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Nurse',
    'General'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Resident',
    'General'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Doctor',
    'OBGYN'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Nurse',
    'OBGYN'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Resident',
    'OBGYN'
);

INSERT INTO staff_category VALUES (
    sec_staff_category.NEXTVAL,
    'Receptionist',DEFAULT
);

SELECT
    *
FROM
    staff_category;



--Blood Bank

CREATE TABLE blood_bank (
    bank_id      NUMBER(4) PRIMARY KEY,
    bank_name    VARCHAR2(30) NOT NULL,
    address_id   NUMBER(4)
        REFERENCES address ( address_id ),
    CONSTRAINT u_2 UNIQUE ( bank_id,
                            address_id )
);

CREATE SEQUENCE sec_blood_bank MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE;

INSERT INTO blood_bank VALUES (
    sec_blood_bank.NEXTVAL,
    'Blood Cross Society',
    5
);

INSERT INTO blood_bank VALUES (
    sec_blood_bank.NEXTVAL,
    'Medicine Club',
    1
);

INSERT INTO blood_bank VALUES (
    sec_blood_bank.NEXTVAL,
    'Romanian Red Cross',
    1
);

INSERT INTO blood_bank VALUES (
    sec_blood_bank.NEXTVAL,
    'Youth for Blood',
    5
);

INSERT INTO blood_bank VALUES (
    sec_blood_bank.NEXTVAL,
    'Red Cross Society',
    5
);

INSERT INTO blood_bank VALUES (
    sec_blood_bank.NEXTVAL,
    'Friends2support',
    2
);

SELECT
    *
FROM
    blood_bank;


--Staff

CREATE TABLE staff (
    staff_id            NUMBER(4) PRIMARY KEY,
    first_name          VARCHAR2(30),
    last_name           VARCHAR2(30),
    hire_date           DATE DEFAULT SYSDATE,
    staff_category_id   NUMBER(4)
        REFERENCES staff_category ( category_id ),
    bank_id             NUMBER(4)
        REFERENCES blood_bank ( bank_id ),
    address_id          NUMBER(4)
        REFERENCES address ( address_id ),
    experience          NUMBER(2) DEFAULT 0,
    salary              NUMBER(6)
        CONSTRAINT ck_2 CHECK ( salary > 0 )
);

CREATE SEQUENCE sec_staff MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE;

DECLARE BEGIN
    FOR i IN (
        SELECT
            first_name,
            last_name,
            hire_date,
            salary
        FROM
            employees
        WHERE
            employee_id < 121
    ) LOOP
        INSERT INTO staff VALUES (
            sec_staff.NEXTVAL,
            i.first_name,
            i.last_name,
            i.hire_date,
            1,
            1,
            1,
            6,
            i.salary
        );

    END LOOP;
END;
/

SELECT
    *
FROM
    blood_bank;


--Blood types

CREATE TABLE blood_types (
    blood_id      VARCHAR2(10) PRIMARY KEY,
    blood_group   NUMBER(2) NOT NULL,
    antigen       VARCHAR2(10),
    anticorp      VARCHAR2(10),
    rh            VARCHAR2(10),
    CONSTRAINT u_4 UNIQUE ( blood_id,
                            rh ),
    CONSTRAINT ck_4 CHECK ( rh IN (
        'negative',
        'positive'
    ) )
);

INSERT INTO blood_types VALUES (
    'O-neg',
    1,
    NULL,
    'Alpha Beta',
    'negative'
);

INSERT INTO blood_types VALUES (
    'O-pos',
    1,
    NULL,
    'Alpha Beta',
    'positive'
);

INSERT INTO blood_types VALUES (
    'A-neg',
    2,
    'A',
    'Beta',
    'negative'
);

INSERT INTO blood_types VALUES (
    'A-pos',
    2,
    'A',
    'Beta',
    'positive'
);

INSERT INTO blood_types VALUES (
    'B-neg',
    3,
    'B',
    'Alpha',
    'negative'
);

INSERT INTO blood_types VALUES (
    'B-pos',
    3,
    'B',
    'Alpha',
    'positive'
);

INSERT INTO blood_types VALUES (
    'AB-neg',
    4,
    'A + B',
    NULL,
    'negative'
);

INSERT INTO blood_types VALUES (
    'AB-pos',
    4,
    'A + B',
    NULL,
    'positive'
);

SELECT
    *
FROM
    blood_types;



--Donor

CREATE TABLE donor (
    donor_id       NUMBER(4) PRIMARY KEY,
    first_name     VARCHAR2(30) NOT NULL,
    last_name      VARCHAR2(30) NOT NULL,
    birth_date     DATE DEFAULT SYSDATE,
    phone_number   VARCHAR2(20),
    address_id     NUMBER(4)
        REFERENCES address ( address_id ),
    bank_id        NUMBER(4)
        REFERENCES blood_bank ( bank_id ),
    blood_type     VARCHAR2(10)
        REFERENCES blood_types ( blood_id ),
    CONSTRAINT u_5 UNIQUE ( first_name,
                            last_name,
                            birth_date )
);

CREATE SEQUENCE sec_donor MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE;

SELECT
    *
FROM
    employees;

BEGIN
    FOR i IN (
        SELECT
            employee_id,
            first_name,
            last_name,
            hire_date,
            phone_number
        FROM
            employees
    ) LOOP
        IF
            MOD(i.employee_id,4) = 0
        THEN
            INSERT INTO donor VALUES (
                sec_donor.NEXTVAL,
                i.first_name,
                i.last_name,
                i.hire_date,
                i.phone_number,
                1,
                2,
                'O-neg'
            );

        ELSIF MOD(i.employee_id,8) = 1 THEN
            INSERT INTO donor VALUES (
                sec_donor.NEXTVAL,
                i.first_name,
                i.last_name,
                i.hire_date,
                i.phone_number,
                5,
                2,
                'O-pos'
            );

        ELSIF MOD(i.employee_id,8) = 2 THEN
            INSERT INTO donor VALUES (
                sec_donor.NEXTVAL,
                i.first_name,
                i.last_name,
                i.hire_date,
                i.phone_number,
                2,
                4,
                'A-neg'
            );

        ELSIF MOD(i.employee_id,8) = 3 THEN
            INSERT INTO donor VALUES (
                sec_donor.NEXTVAL,
                i.first_name,
                i.last_name,
                i.hire_date,
                i.phone_number,
                2,
                5,
                'AB-neg'
            );

        ELSIF MOD(i.employee_id,8) = 5 THEN
            INSERT INTO donor VALUES (
                sec_donor.NEXTVAL,
                i.first_name,
                i.last_name,
                i.hire_date,
                i.phone_number,
                3,
                1,
                'O-neg'
            );

        ELSIF MOD(i.employee_id,8) = 7 THEN
            INSERT INTO donor VALUES (
                sec_donor.NEXTVAL,
                i.first_name,
                i.last_name,
                i.hire_date,
                i.phone_number,
                1,
                2,
                'AB-pos'
            );

        ELSIF MOD(i.employee_id,8) = 6 THEN
            INSERT INTO donor VALUES (
                sec_donor.NEXTVAL,
                i.first_name,
                i.last_name,
                i.hire_date,
                i.phone_number,
                1,
                2,
                'B-pos'
            );

        END IF;
    END LOOP;
END;
/

SELECT
    *
FROM
    donor;


--Donations

CREATE TABLE donation (
    donation_id     NUMBER(4) PRIMARY KEY,
    donor_id        NUMBER(4)
        REFERENCES donor ( donor_id ),
    donation_date   DATE DEFAULT SYSDATE,
    blood_type      VARCHAR2(10)
        REFERENCES blood_types ( blood_id ),
    bank_id         NUMBER(4)
        REFERENCES blood_bank ( bank_id ),
    status          VARCHAR2(10) DEFAULT 'pending',
    CONSTRAINT ck_3 CHECK ( status IN (
        'accepted',
        'declined',
        'pending'
    ) )
);

CREATE SEQUENCE sec_donation MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE;

BEGIN
    FOR i IN (
        SELECT
            donor_id,
            blood_type
        FROM
            donor
    ) LOOP
        IF
            MOD(i.donor_id,4) = 0
        THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('22-10-2020','dd-mm-yyyy'),
                i.blood_type,
                2,DEFAULT
            );

        ELSIF MOD(i.donor_id,9) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('13-11-2020','dd-mm-yyyy'),
                i.blood_type,
                3,DEFAULT
            );

        ELSIF MOD(i.donor_id,11) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('30-09-2020','dd-mm-yyyy'),
                i.blood_type,
                1,DEFAULT
            );

        ELSIF MOD(i.donor_id,5) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('20-12-2020','dd-mm-yyyy'),
                i.blood_type,
                3,DEFAULT
            );

        ELSIF MOD(i.donor_id,26) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('28-10-2020','dd-mm-yyyy'),
                i.blood_type,
                4,DEFAULT
            );

        ELSIF MOD(i.donor_id,2) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('07-01-2021','dd-mm-yyyy'),
                i.blood_type,
                1,DEFAULT
            );

        END IF;
    END LOOP;
END;
/

BEGIN
    FOR i IN (
        SELECT
            donor_id,
            blood_type
        FROM
            donor
    ) LOOP
        IF
            MOD(i.donor_id,6) = 0
        THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('25-10-2020','dd-mm-yyyy'),
                i.blood_type,
                2,DEFAULT
            );

        ELSIF MOD(i.donor_id,7) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('16-11-2020','dd-mm-yyyy'),
                i.blood_type,
                6,DEFAULT
            );

        ELSIF MOD(i.donor_id,46) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('30-09-2020','dd-mm-yyyy'),
                i.blood_type,
                6,DEFAULT
            );

        ELSIF MOD(i.donor_id,3) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('20-12-2020','dd-mm-yyyy'),
                i.blood_type,
                5,DEFAULT
            );

        ELSIF MOD(i.donor_id,50) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('28-10-2020','dd-mm-yyyy'),
                i.blood_type,
                2,DEFAULT
            );

        ELSIF MOD(i.donor_id,13) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('04-01-2021','dd-mm-yyyy'),
                i.blood_type,
                3,DEFAULT
            );

        END IF;
    END LOOP;
END;
/

BEGIN
    FOR i IN (
        SELECT
            donor_id,
            blood_type
        FROM
            donor
    ) LOOP
        IF
            MOD(i.donor_id,5) = 0
        THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('20-09-2020','dd-mm-yyyy'),
                i.blood_type,
                3,DEFAULT
            );

        ELSIF MOD(i.donor_id,8) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('18-12-2020','dd-mm-yyyy'),
                i.blood_type,
                4,DEFAULT
            );

        ELSIF MOD(i.donor_id,31) = 0 THEN
            INSERT INTO donation VALUES (
                sec_donation.NEXTVAL,
                i.donor_id,
                TO_DATE('15-11-2020','dd-mm-yyyy'),
                i.blood_type,
                3,DEFAULT
            );

        END IF;
    END LOOP;
END;
/

SELECT
    *
FROM
    donation;
    

-- Registration - asociativ

CREATE TABLE registration (
    bank_id             NUMBER(4)
        REFERENCES blood_bank ( bank_id ),
    donor_id            NUMBER(4)
        REFERENCES donor ( donor_id ),
    registration_date   DATE DEFAULT SYSDATE,
    CONSTRAINT pk_1 PRIMARY KEY ( bank_id,
                                  donor_id )
);

BEGIN
    FOR i IN (
        SELECT
            donor_id
        FROM
            donor
    ) LOOP
        IF
            MOD(i.donor_id,4) = 0
        THEN
            INSERT INTO registration VALUES (
                1,
                i.donor_id,
                TO_DATE('05-04-2020','dd-mm-yyyy')
            );

        ELSIF MOD(i.donor_id,3) = 1 THEN
            INSERT INTO registration VALUES (
                2,
                i.donor_id,
                TO_DATE('10-08-2020','dd-mm-yyyy')
            );

        ELSIF MOD(i.donor_id,3) = 2 THEN
            INSERT INTO registration VALUES (
                3,
                i.donor_id,
                TO_DATE('11-08-2020','dd-mm-yyyy')
            );

        END IF;

        IF
            MOD(i.donor_id,3) = 1
        THEN
            INSERT INTO registration VALUES (
                4,
                i.donor_id,
                TO_DATE('15-03-2020','dd-mm-yyyy')
            );

        ELSIF MOD(i.donor_id,5) = 1 THEN
            INSERT INTO registration VALUES (
                5,
                i.donor_id,
                TO_DATE('20-03-2020','dd-mm-yyyy')
            );

        END IF;

    END LOOP;
END;
/

SELECT
    *
FROM
    registration;

-- Medical conditions

CREATE TABLE medical_condition (
    condition_id     NUMBER(4) PRIMARY KEY,
    condition_name   VARCHAR2(30) NOT NULL,
    approvement      VARCHAR2(20) NOT NULL,
    CONSTRAINT ck_5 CHECK ( approvement IN (
        'accepted',
        'declined'
    ) )
);

CREATE SEQUENCE sec_condition MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE;

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Cold',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Flu',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Dentist visit',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Recent vaccination',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Older vaccine',
    'accepted'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Recent surgery',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Tattoo',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Diabetes',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Birth control treatment',
    'accepted'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Asthma',
    'accepted'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'High blood presure',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Pregnancy',
    'declined'
);

INSERT INTO medical_condition VALUES (
    sec_condition.NEXTVAL,
    'Low weight',
    'declined'
);

SELECT
    *
FROM
    medical_condition;


-- Donor conditions - asociativ

CREATE TABLE donor_condition (
    donor_id       NUMBER(4)
        REFERENCES donor ( donor_id ),
    condition_id   NUMBER(4)
        REFERENCES medical_condition ( condition_id ),
    CONSTRAINT pk_2 PRIMARY KEY ( donor_id,
                                  condition_id )
);

INSERT INTO donor_condition VALUES (
    5,
    6
);

INSERT INTO donor_condition VALUES (
    5,
    7
);

INSERT INTO donor_condition VALUES (
    7,
    11
);

INSERT INTO donor_condition VALUES (
    7,
    12
);

INSERT INTO donor_condition VALUES (
    12,
    6
);

INSERT INTO donor_condition VALUES (
    12,
    8
);

INSERT INTO donor_condition VALUES (
    27,
    3
);

INSERT INTO donor_condition VALUES (
    28,
    10
);

INSERT INTO donor_condition VALUES (
    30,
    13
);

INSERT INTO donor_condition VALUES (
    35,
    7
);

INSERT INTO donor_condition VALUES (
    35,
    9
);

INSERT INTO donor_condition VALUES (
    40,
    3
);

INSERT INTO donor_condition VALUES (
    81,
    7
);

INSERT INTO donor_condition VALUES (
    82,
    8
);

INSERT INTO donor_condition VALUES (
    85,
    1
);

INSERT INTO donor_condition VALUES (
    90,
    3
);

INSERT INTO donor_condition VALUES (
    90,
    5
);

INSERT INTO donor_condition VALUES (
    100,
    4
);

INSERT INTO donor_condition VALUES (
    106,
    4
);

INSERT INTO donor_condition VALUES (
    74,
    11
);

INSERT INTO donor_condition VALUES (
    73,
    6
);

INSERT INTO donor_condition VALUES (
    63,
    4
);

INSERT INTO donor_condition VALUES (
    23,
    4
);

INSERT INTO donor_condition VALUES (
    16,
    4
);

INSERT INTO donor_condition VALUES (
    88,
    4
);

INSERT INTO donor_condition VALUES (
    98,
    4
);

INSERT INTO donor_condition VALUES (
    35,
    4
);

SELECT
    *
FROM
    donor_condition;

DECLARE
    appr   VARCHAR2(30);
BEGIN
    FOR i IN (
        SELECT
            *
        FROM
            donor
    ) LOOP
        appr := 'accepted';
        FOR j IN (
            SELECT
                *
            FROM
                donor_condition
            WHERE
                donor_id = i.donor_id
        ) LOOP
            FOR k IN (
                SELECT
                    *
                FROM
                    medical_condition
                WHERE
                    condition_id = j.condition_id
            ) LOOP
                IF
                    k.approvement = 'declined'
                THEN
                    appr := 'declined';
                END IF;
            END LOOP;
        END LOOP;

        UPDATE donation
        SET
            status = appr
        WHERE
            donor_id = i.donor_id;

    END LOOP;
END;
/

SELECT
    *
FROM
    donation;