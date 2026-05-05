SELECT * FROM vvtat_data.case_resolution;

SELECT 
    case_resolution_ID,
    resolution_text,
    CASE 
        -- 1. NUTRAUKTI PIRKIMO-PARDAVIMO SUTARTĮ
        -- Pagauna tiesiogines frazes, klaidas ('prikimo') ir nukirstus sakinius, kurie baigiasi 'sutartį'
        WHEN LOWER(resolution_text) REGEXP 'nutraukti.*(pirkimo|prikimo).*(pardavimo).*sutart' 
             OR LOWER(resolution_text) LIKE '%pirkimo-pardavimo sutart%'
             OR (LOWER(resolution_text) LIKE 'nutraukti %' AND LENGTH(resolution_text) > 40) THEN 'Nutraukti pirkimo-pardavimo sutartį'
        
        -- 2. PINIGŲ GRĄŽINIMAS
        -- Apima: lėšas, sumas, įmokas, užstatus, bilietus ir "sumokėtus pinigus"
        WHEN LOWER(resolution_text) REGEXP '(grąžinti|gražinti|atmokėti|išmokėti|grąžinimas)'
             AND LOWER(resolution_text) REGEXP '(pinig|lėš|įmok|užstat|uţstat|depozit|likut|skol|sumą|avans|biliet|mokest|kainos|vertės|eurai|eurų)' THEN 'Pinigų grąžinimas'
             
        -- 3. TRŪKUMŲ PAŠALINIMAS (REMONTAS)
        -- Apima: remontą, trūkumų šalinimą, taisymą ir poliravimą (iš jūsų CSV)
        WHEN LOWER(resolution_text) LIKE '%pašalinti%trūkum%' 
             OR LOWER(resolution_text) LIKE '%remont%' 
             OR LOWER(resolution_text) LIKE '%taisyti%' 
             OR LOWER(resolution_text) LIKE '%poliravimas%' 
             OR LOWER(resolution_text) LIKE '%sutaisyti%' THEN 'Trūkumų pašalinimas (Remontas)'
             
        -- 4. PREKĖS PAKEITIMAS
        WHEN LOWER(resolution_text) LIKE '%pakeisti%' 
             OR LOWER(resolution_text) LIKE '%apkeisti%' THEN 'Prekės pakeitimas'

        -- 5. NUOSTOLIŲ ATLYGINIMAS
        -- Apima: žalą, nuostolius, teisines išlaidas, kompensacijas
        WHEN LOWER(resolution_text) REGEXP '(atlyginti|kompensuoti|padengti|žalos|nuostol|išlaidas)' THEN 'Nuostolių atlyginimas'
        
        -- 6. ĮPAREIGOJIMAS ATLIKTI VEIKSMUS
        -- Svarbu: dovanų kuponų vykdymas, paslaugų suteikimas, garantijos suteikimas
        WHEN LOWER(resolution_text) REGEXP '(įpareigoti|suteikti|parduoti|įvykdyti|perduoti|pateikti|garantiją)' THEN 'Įpareigojimas atlikti veiksmus'
             
        -- 7. KITI SPECIFINIAI
        WHEN LOWER(resolution_text) LIKE '%nutraukti%sutart%' THEN 'Sutarties nutraukimas'
        WHEN LOWER(resolution_text) LIKE '%sumažinti%kain%' THEN 'Kainos sumažinimas'
        WHEN LOWER(resolution_text) LIKE '%pristatyti%' THEN 'Prekės pristatymas'
        
        ELSE 'Kiti sprendimai'
    END AS segmentas
FROM case_resolution;
-- ----------------------------------------------------------------------------------------------------

SELECT 
    case_dispute_ID,
    dispute_non_financial_demand,
    CASE 
        -- 1. Nutraukti pirkimo-pardavimo sutartį
        -- Pagauna visus variantus, net jei sakinys labai ilgas ar nukirstas
        WHEN LOWER(dispute_non_financial_demand) REGEXP 'nutraukti.*(pirkimo|prikimo).*(pardavimo).*sutart' 
             OR LOWER(dispute_non_financial_demand) LIKE '%pirkimo-pardavimo sutart%'
             OR (LOWER(dispute_non_financial_demand) LIKE 'nutraukti %' AND LENGTH(dispute_non_financial_demand) > 30) THEN 'Nutraukti pirkimo-pardavimo sutartį'
        
        -- 2. Pinigų grąžinimas
        -- Išplėsta lėktuvų bilietams, įmokoms, sumoms ir "pagrįstumo" klausimams
        WHEN LOWER(dispute_non_financial_demand) REGEXP '(grąžinti|gražinti|atmokėti|grąžinimas)'
             AND LOWER(dispute_non_financial_demand) REGEXP '(pinig|lėš|įmok|užstat|uţstat|depozit|likut|skol|sumą|avans|biliet|mokest|kainos|vertės)' THEN 'Pinigų grąžinimas'
             
        -- 3. Trūkumų pašalinimas (Remontas)
        WHEN LOWER(dispute_non_financial_demand) LIKE '%pašalinti%trūkum%' 
             OR LOWER(dispute_non_financial_demand) LIKE '%remont%' 
             OR LOWER(dispute_non_financial_demand) LIKE '%taisyti%' 
             OR LOWER(dispute_non_financial_demand) LIKE '%sutaisyti%' 
             OR LOWER(dispute_non_financial_demand) LIKE '%kokybės atstatymas%' THEN 'Trūkumų pašalinimas (Remontas)'
             
        -- 4. Prekės pakeitimas
        WHEN LOWER(dispute_non_financial_demand) LIKE '%pakeisti%' 
             OR LOWER(dispute_non_financial_demand) LIKE '%apkeisti%' THEN 'Prekės pakeitimas'

        -- 5. Nuostolių atlyginimas
        -- Apima turtinę/neturtinę žalą, išlaidas, kompensacijas
        WHEN LOWER(dispute_non_financial_demand) REGEXP '(atlyginti|kompensuoti|padengti|žalos|nuostol|išlaidas)' THEN 'Nuostolių atlyginimas'
        
        -- 6. Įpareigojimas atlikti veiksmus
        -- Apima paslaugų suteikimą, kuponų aktyvavimą, prekių pardavimą
        WHEN LOWER(dispute_non_financial_demand) REGEXP '(įpareigoti|suteikti|parduoti|įvykdyti|perduoti|pateikti)' THEN 'Įpareigojimas atlikti veiksmus'
             
        -- 7. Specifiniai mažesni segmentai
        WHEN LOWER(dispute_non_financial_demand) LIKE '%nutraukti%sutart%' THEN 'Sutarties nutraukimas'
        WHEN LOWER(dispute_non_financial_demand) LIKE '%sumažinti%kain%' THEN 'Kainos sumažinimas'
        WHEN LOWER(dispute_non_financial_demand) LIKE '%pristatyti%' THEN 'Prekės pristatymas'
        
        ELSE 'Kiti sprendimai'
    END AS segmentas
FROM case_dispute;