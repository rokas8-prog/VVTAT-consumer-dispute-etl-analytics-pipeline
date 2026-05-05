CREATE DATABASE IF NOT EXISTS VVTAT_DATA;
USE VVTAT_DATA;

-- Table for storing raw HTML pages
CREATE TABLE IF NOT EXISTS raw_page (
    page_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    url VARCHAR(2048) NOT NULL,
    sha256 CHAR(64) NOT NULL,
    http_status SMALLINT NULL,
    html LONGTEXT NOT NULL,
    extracted JSON NULL,
    fetched_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (page_id),
    -- Fixed: Added (768) prefix to stay under the 3072 byte limit (768 * 4 = 3072)
    UNIQUE KEY uq_raw_page_url (url(768)),
    KEY idx_raw_page_sha256 (sha256),
    KEY idx_raw_page_fetched_at (fetched_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Table for storing individual rows scraped from listing pages
CREATE TABLE IF NOT EXISTS raw_case_row (
    row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    year SMALLINT NOT NULL,
    case_type VARCHAR(64) NOT NULL,
    source_list_url VARCHAR(2048) NOT NULL,
    list_page_updated_at DATETIME NULL,
    company_name_raw TEXT NOT NULL,
    subject_raw TEXT NULL,
    pdf_url VARCHAR(2048) NOT NULL,
    pdf_url_hash CHAR(64) NOT NULL,
    link_text TEXT NULL,
    case_no_guess VARCHAR(255) NULL,
    decision_date_guess DATE NULL,
    payload JSON NOT NULL,
    scraped_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (row_id),
    UNIQUE KEY uq_raw_case_row_pdf_url_hash (pdf_url_hash),
    KEY idx_raw_case_row_year (year),
    KEY idx_raw_case_row_case_type (case_type),
    KEY idx_raw_case_row_decision_date_guess (decision_date_guess)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Table for tracking PDF download status and local storage
CREATE TABLE IF NOT EXISTS raw_pdf (
    pdf_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    row_id BIGINT UNSIGNED NULL,
    pdf_url VARCHAR(2048) NOT NULL,
    pdf_url_hash CHAR(64) NOT NULL,
    sha256 CHAR(64) NOT NULL,
    local_path VARCHAR(2048) NOT NULL,
    http_status SMALLINT NULL,
    downloaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (pdf_id),
    UNIQUE KEY uq_raw_pdf_pdf_url_hash (pdf_url_hash),
    KEY idx_raw_pdf_row_id (row_id),
    KEY idx_raw_pdf_sha256 (sha256),
    KEY idx_raw_pdf_downloaded_at (downloaded_at),
    CONSTRAINT fk_raw_pdf_row
        FOREIGN KEY (row_id) REFERENCES raw_case_row(row_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Table for storing extracted text from PDFs, keyed by content hash
CREATE TABLE IF NOT EXISTS raw_pdf_text (
    sha256 CHAR(64) NOT NULL,
    page_count INT NULL,
    text LONGTEXT NOT NULL,
    extracted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (sha256),
    KEY idx_raw_pdf_text_page_count (page_count),
    KEY idx_raw_pdf_text_extracted_at (extracted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS vvtat_data.raw_pdf_error (
    id INT AUTO_INCREMENT PRIMARY KEY,
    case_id VARCHAR(255),          -- The ID of the case being processed
    error_url TEXT,                -- The URL that failed
    status_code INT,               -- e.g., 502, 404, 500
    response_size INT,             -- The size of the body returned
    error_message TEXT,            -- The specific RuntimeError message
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);