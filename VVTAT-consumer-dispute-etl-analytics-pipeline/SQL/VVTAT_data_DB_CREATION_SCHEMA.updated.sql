Create database VVTAT_data;

USE VVTAT_data;

CREATE TABLE if not exists case_seller_or_service_provider (
    seller_or_service_provider_ID INT NOT NULL PRIMARY KEY,
    seller_or_service_provider_type VARCHAR(50) NOT NULL,
    seller_or_service_provider_name VARCHAR(255) NOT NULL,
    company_code VARCHAR(20) NULL,
    company_address VARCHAR(255) NULL,
    seller_or_company_city VARCHAR(255) NULL
);

CREATE TABLE if not exists case_consumer_person(
    consumer_person_ID INT NOT NULL PRIMARY KEY,
    consumer_person_initials VARCHAR(10) NULL,
    consumer_person_gender VARCHAR(20) NOT NULL
);

CREATE TABLE if not exists case_dispute(
    case_dispute_ID INT NOT NULL PRIMARY KEY,
    dispute_type VARCHAR(100) NOT NULL,
    dispute_start_date DATETIME NOT NULL,
    dispute_subject VARCHAR(255) NOT NULL,
    dispute_amount_in_euros DECIMAL(15, 2) NOT NULL,
    dispute_non_financial_demand VARCHAR(255) NULL,
    dispute_validity BOOLEAN NOT NULL
);

CREATE TABLE if not exists case_resolution(
    case_resolution_ID INT NOT NULL PRIMARY KEY,
    case_dispute_ID INT NOT NULL,
    resolution_outcome_type VARCHAR(20) NOT NULL,
    resolution_amount_in_euros DECIMAL(15, 2) NOT NULL,
    resolution_text VARCHAR(255) NULL,
    FOREIGN KEY (case_dispute_ID) REFERENCES case_dispute(case_dispute_ID)
);

CREATE TABLE if not exists core_case_resolution_event (
    case_resolution_event_ID INT NOT NULL PRIMARY KEY,
    case_resolution_event_date DATETIME NOT NULL,
    seller_or_service_provider_ID INT NOT NULL,
    consumer_person_ID INT NOT NULL,
    case_dispute_ID INT NOT NULL,
    case_resolution_ID INT NOT NULL,
    pdf_url VARCHAR(255),
    sha256 VARCHAR(255),
    FOREIGN KEY (seller_or_service_provider_ID) REFERENCES case_seller_or_service_provider(seller_or_service_provider_ID),
    FOREIGN KEY (consumer_person_ID) REFERENCES case_consumer_person(consumer_person_ID),
    FOREIGN KEY (case_dispute_ID) REFERENCES case_dispute(case_dispute_ID),
    FOREIGN KEY (case_resolution_ID) REFERENCES case_resolution(case_resolution_ID)
);