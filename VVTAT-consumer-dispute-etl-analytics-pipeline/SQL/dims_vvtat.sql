# ---------------------------------------------------------
# 1. DIM_Geography
# ---------------------------------------------------------
DELIMITER //
DROP PROCEDURE IF EXISTS DIM_Geography//
CREATE PROCEDURE DIM_Geography()
BEGIN
    CREATE TABLE IF NOT EXISTS DIM_Geography (
        AddressKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        City_Company_OR_Seller VARCHAR(255) NOT NULL,
        Address_Company VARCHAR(255) NOT NULL
    );
    TRUNCATE TABLE DIM_Geography;

    INSERT INTO DIM_Geography (City_Company_OR_Seller, Address_Company)
    SELECT DISTINCT seller_or_company_city, company_address
    FROM vvtat_data.case_seller_or_service_provider
    WHERE seller_or_company_city IS NOT NULL AND company_address IS NOT NULL; 
END//
DELIMITER ;
CALL DIM_Geography();

# ---------------------------------------------------------
# 2. DIM_Entity
# ---------------------------------------------------------
DELIMITER //
DROP PROCEDURE IF EXISTS DIM_Entity//
CREATE PROCEDURE DIM_Entity()
BEGIN
    DROP TABLE IF EXISTS DIM_Entity;
    CREATE TABLE DIM_Entity (
        EntityKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        Original_Provider_ID INT,
        Type_Seller_Service_Provider VARCHAR(50) NOT NULL,
        Name_Seller_Service_Provider VARCHAR(255) NOT NULL,
        Company_Code VARCHAR(20) NULL,
        Company_Address VARCHAR(255) NULL,
        Seller_Company_City VARCHAR(255) NULL
    );

    INSERT INTO DIM_Entity (Original_Provider_ID, Type_Seller_Service_Provider, Name_Seller_Service_Provider, Company_Code, Company_Address, Seller_Company_City)
    SELECT seller_or_service_provider_ID, seller_or_service_provider_type, seller_or_service_provider_name, company_code, company_address, seller_or_company_city
    FROM vvtat_data.case_seller_or_service_provider;
END//
DELIMITER ;
CALL DIM_Entity();

# ---------------------------------------------------------
# 3. DIM_Consumer 
# ---------------------------------------------------------
DELIMITER //
DROP PROCEDURE IF EXISTS DIM_Consumer//
CREATE PROCEDURE DIM_Consumer()
BEGIN
    DROP TABLE IF EXISTS DIM_Consumer;
    CREATE TABLE DIM_Consumer (
        ConsumerKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        Original_Consumer_ID INT,
        Consumer_Initials VARCHAR(10) NULL,
        Consumer_Gender VARCHAR(20) NOT NULL
    );

    INSERT INTO DIM_Consumer (Original_Consumer_ID, Consumer_Initials, Consumer_Gender)
    SELECT 
        consumer_person_ID, 
        consumer_person_initials, 
        consumer_person_gender
    FROM vvtat_data.case_consumer_person;
END//
DELIMITER ;
CALL DIM_Consumer();

# ---------------------------------------------------------
# 4. DIM_Dispute
# ---------------------------------------------------------
DELIMITER //
DROP PROCEDURE IF EXISTS DIM_Dispute//
CREATE PROCEDURE DIM_Dispute()
BEGIN
    DROP TABLE IF EXISTS DIM_Dispute; 
    CREATE TABLE DIM_Dispute (
        DisputeKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        Original_Dispute_ID INT,
        Type_Dispute VARCHAR(100) NOT NULL,
        Start_Date_Dispute DATETIME NOT NULL,
        Subject_Dispute VARCHAR(255) NOT NULL,
        Amount_In_Euros_Dispute DECIMAL(15, 2) NOT NULL,
        Amount_Segment VARCHAR(100) NOT NULL,
        Non_Financial_Demand_Dispute VARCHAR(255) NULL,
        Dispute_Validity BOOLEAN NOT NULL,
        Dispute_Segment VARCHAR(100) NOT NULL
    );

    INSERT INTO DIM_Dispute (Original_Dispute_ID, Type_Dispute, Start_Date_Dispute, Subject_Dispute, Amount_In_Euros_Dispute, Amount_Segment, Non_Financial_Demand_Dispute, Dispute_Validity, Dispute_Segment)
    SELECT 
        case_dispute_ID, dispute_type, dispute_start_date, dispute_subject, dispute_amount_in_euros,
        CASE
            WHEN dispute_amount_in_euros = 0 THEN '0 € (Nefinansinis reikalavimas)'
            WHEN dispute_amount_in_euros > 0 AND dispute_amount_in_euros <= 50 THEN '0.01 - 50 €'
            WHEN dispute_amount_in_euros > 50 AND dispute_amount_in_euros <= 150 THEN '50.01 - 150 €'
            WHEN dispute_amount_in_euros > 150 AND dispute_amount_in_euros <= 500 THEN '150.01 - 500 €'
            WHEN dispute_amount_in_euros > 500 AND dispute_amount_in_euros <= 1000 THEN '500.01 - 1000 €'
            WHEN dispute_amount_in_euros > 1000 THEN 'Daugiau nei 1000 €'
            ELSE 'Nenurodyta'
        END,
        dispute_non_financial_demand, dispute_validity,
        CASE
            WHEN LOWER(dispute_non_financial_demand) REGEXP 'nutraukti.*(pirkimo|prikimo).*(pardavimo).*sutart'
                 OR LOWER(dispute_non_financial_demand) LIKE '%pirkimo-pardavimo sutart%'
                 OR (LOWER(dispute_non_financial_demand) LIKE 'nutraukti %' AND LENGTH(dispute_non_financial_demand) > 30) THEN 'Nutraukti pirkimo-pardavimo sutartį'
            WHEN LOWER(dispute_non_financial_demand) REGEXP '(grąžinti|gražinti|atmokėti|grąžinimas)'
                 AND LOWER(dispute_non_financial_demand) REGEXP '(pinig|lėš|įmok|užstat|uţstat|depozit|likut|skol|sumą|avans|biliet|mokest|kainos|vertės)' THEN 'Pinigų grąžinimas'
            WHEN LOWER(dispute_non_financial_demand) LIKE '%pašalinti%trūkum%'
                 OR LOWER(dispute_non_financial_demand) LIKE '%remont%'
                 OR LOWER(dispute_non_financial_demand) LIKE '%taisyti%'
                 OR LOWER(dispute_non_financial_demand) LIKE '%sutaisyti%' THEN 'Trūkumų pašalinimas (Remontas)'
            WHEN LOWER(dispute_non_financial_demand) LIKE '%pakeisti%'
                 OR LOWER(dispute_non_financial_demand) LIKE '%apkeisti%' THEN 'Prekės pakeitimas'
            WHEN LOWER(dispute_non_financial_demand) REGEXP '(atlyginti|kompensuoti|padengti|žalos|nuostol|išlaidas)' THEN 'Nuostolių atlyginimas'
            WHEN LOWER(dispute_non_financial_demand) REGEXP '(įpareigoti|suteikti|parduoti|įvykdyti|perduoti|pateikti)' THEN 'Įpareigojimas atlikti veiksmus'
            WHEN LOWER(dispute_non_financial_demand) LIKE '%nutraukti%sutart%' THEN 'Sutarties nutraukimas'
            WHEN LOWER(dispute_non_financial_demand) LIKE '%sumažinti%kain%' THEN 'Kainos sumažinimas'
            WHEN LOWER(dispute_non_financial_demand) LIKE '%pristatyti%' THEN 'Prekės pristatymas'
            ELSE 'Kiti sprendimai'
        END,
        CASE 
			WHEN LOWER(dispute_subject) REGEXP 'avalyn|bat|drabuž|aprang|tekstil' THEN 'Avalynė ir apranga'
			WHEN LOWER(dispute_subject) REGEXP 'telefon|kompiut|šaldyt|skalb|televiz|siurbl|elektron' THEN 'Buitinė technika ir elektronika'
			WHEN LOWER(dispute_subject) REGEXP 'biliet|koncert|skryd|aviac|viešbu|turizm|kelion' THEN 'Laisvalaikis ir renginiai'
			WHEN LOWER(dispute_subject) REGEXP 'bald|lova|sofa|durys|lang|statyb' THEN 'Namų apyvoka ir baldai'
			WHEN LOWER(dispute_subject) REGEXP 'automobil|padang|remont|detal' THEN 'Transportas ir remontas'
			WHEN LOWER(dispute_subject) REGEXP 'elektr|šildym|intern|ryšio|vandens' THEN 'Komunalinės ir ryšio paslaugos'
			WHEN LOWER(dispute_subject) REGEXP 'kosmet|odontolog|grož|medicin' THEN 'Sveikata ir grožis'
			ELSE 'Kitos prekės ir paslaugos'
		END AS Subject_Category
    FROM vvtat_data.case_dispute;
END//
DELIMITER ;
CALL DIM_Dispute();

# ---------------------------------------------------------
# 5. DIM_Outcome
# ---------------------------------------------------------
DELIMITER //
DROP PROCEDURE IF EXISTS DIM_Outcome//
CREATE PROCEDURE DIM_Outcome()
BEGIN
    DROP TABLE IF EXISTS DIM_Outcome;
    CREATE TABLE DIM_Outcome (
        OutcomeKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        Original_Resolution_ID INT,
        Outcome_Type VARCHAR(20) NOT NULL,
        Outcome_Amount_In_Euros DECIMAL(15, 2) NOT NULL,
        Outcome_Amount_Segment VARCHAR(100) NOT NULL,
        Outcome_Text VARCHAR(255) NULL,
        Outcome_Segment VARCHAR(100) NOT NULL
    );

    INSERT INTO DIM_Outcome (Original_Resolution_ID, Outcome_Type, Outcome_Amount_In_Euros, Outcome_Amount_Segment, Outcome_Text, Outcome_Segment)
    SELECT 
        case_resolution_ID, resolution_outcome_type, resolution_amount_in_euros,
        CASE
            WHEN resolution_amount_in_euros = 0 THEN '0 € (Nefinansinis reikalavimas)'
            WHEN resolution_amount_in_euros > 0 AND resolution_amount_in_euros <= 50 THEN '0.01 - 50 €'
            WHEN resolution_amount_in_euros > 50 AND resolution_amount_in_euros <= 150 THEN '50.01 - 150 €'
            WHEN resolution_amount_in_euros > 150 AND resolution_amount_in_euros <= 500 THEN '150.01 - 500 €'
            WHEN resolution_amount_in_euros > 500 AND resolution_amount_in_euros <= 1000 THEN '500.01 - 1000 €'
            WHEN resolution_amount_in_euros > 1000 THEN 'Daugiau nei 1000 €'
            ELSE 'Nenurodyta'
        END,
        resolution_text,
        CASE
            WHEN LOWER(resolution_text) REGEXP 'nutraukti.*(pirkimo|prikimo).*(pardavimo).*sutart'
                 OR LOWER(resolution_text) LIKE '%pirkimo-pardavimo sutart%'
                 OR (LOWER(resolution_text) LIKE 'nutraukti %' AND LENGTH(resolution_text) > 40) THEN 'Nutraukti pirkimo-pardavimo sutartį'
            WHEN LOWER(resolution_text) REGEXP '(grąžinti|gražinti|atmokėti|išmokėti|grąžinimas)'
                 AND LOWER(resolution_text) REGEXP '(pinig|lėš|įmok|užstat|uţstat|depozit|likut|skol|sumą|avans|biliet|mokest|kainos|vertės|eurai|eurų)' THEN 'Pinigų grąžinimas'
            WHEN LOWER(resolution_text) LIKE '%pašalinti%trūkum%'
                 OR LOWER(resolution_text) LIKE '%remont%'
                 OR LOWER(resolution_text) LIKE '%taisyti%'
                 OR LOWER(resolution_text) LIKE '%poliravimas%'
                 OR LOWER(resolution_text) LIKE '%sutaisyti%' THEN 'Trūkumų pašalinimas (Remontas)'
            WHEN LOWER(resolution_text) LIKE '%pakeisti%'
                 OR LOWER(resolution_text) LIKE '%apkeisti%' THEN 'Prekės pakeitimas'
            WHEN LOWER(resolution_text) REGEXP '(atlyginti|kompensuoti|padengti|žalos|nuostol|išlaidas)' THEN 'Nuostolių atlyginimas'
            WHEN LOWER(resolution_text) REGEXP '(įpareigoti|suteikti|parduoti|įvykdyti|perduoti|pateikti|garantiją)' THEN 'Įpareigojimas atlikti veiksmus'
            WHEN LOWER(resolution_text) LIKE '%nutraukti%sutart%' THEN 'Sutarties nutraukimas'
            WHEN LOWER(resolution_text) LIKE '%sumažinti%kain%' THEN 'Kainos sumažinimas'
            WHEN LOWER(resolution_text) LIKE '%pristatyti%' THEN 'Prekės pristatymas'
            ELSE 'Kiti sprendimai'
        END
    FROM vvtat_data.case_resolution;
END//
DELIMITER ;
CALL DIM_Outcome();

# ---------------------------------------------------------
# 6. DIM_Main_Event 
# ---------------------------------------------------------
DELIMITER //
DROP PROCEDURE IF EXISTS DIM_Main_Event//
CREATE PROCEDURE DIM_Main_Event()
BEGIN
    DROP TABLE IF EXISTS DIM_Main_Event;
    CREATE TABLE DIM_Main_Event (
        EventKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        EventDate DATETIME NOT NULL,
        EntityKey INT,
        AddressKey INT,
        ConsumerKey INT,
        DisputeKey INT,
        OutcomeKey INT,
        PDF_URL VARCHAR(255),
        SHA256_Hash VARCHAR(255)
    );

    INSERT INTO DIM_Main_Event (EventDate, EntityKey, AddressKey, ConsumerKey, DisputeKey, OutcomeKey, PDF_URL, SHA256_Hash)
    SELECT 
        ce.case_resolution_event_date,
        de.EntityKey,
        dg.AddressKey,
        dc.ConsumerKey,
        dd.DisputeKey,
        do.OutcomeKey,
        ce.pdf_url,
        ce.sha256
    FROM vvtat_data.core_case_resolution_event ce
    LEFT JOIN DIM_Entity de ON ce.seller_or_service_provider_ID = de.Original_Provider_ID
    LEFT JOIN vvtat_data.case_seller_or_service_provider ssp ON ce.seller_or_service_provider_ID = ssp.seller_or_service_provider_ID
    LEFT JOIN DIM_Geography dg ON ssp.company_address = dg.Address_Company AND ssp.seller_or_company_city = dg.City_Company_OR_Seller
    LEFT JOIN DIM_Consumer dc ON ce.consumer_person_ID = dc.Original_Consumer_ID
    LEFT JOIN DIM_Dispute dd ON ce.case_dispute_ID = dd.Original_Dispute_ID
    LEFT JOIN DIM_Outcome do ON ce.case_resolution_ID = do.Original_Resolution_ID;
END//
DELIMITER ;
CALL DIM_Main_Event();