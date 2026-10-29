/* ==========================================================
   DDDM 2026 | Week 2 | File 05 (danh cho ban lam KNIME tren may khac)
   Muc dich: dung database dddm_telco_churn tren may SACH (chua co gi),
   giong het cau truc database chinh.
   Cach chay: mo file trong MySQL Workbench, bam Ctrl+Shift+Enter
   (Mac: Cmd+Shift+Enter) de chay ca file.
   Sau khi chay xong: nap file CSV Telco vao bang raw_customer_data
   bang Table Data Import Wizard (Use existing table, tick Truncate).
   ========================================================== */

CREATE DATABASE IF NOT EXISTS dddm_telco_churn;
USE dddm_telco_churn;

/* Xoa theo thu tu de khong vuong khoa ngoai. Chay lai file nay bao nhieu lan cung duoc. */
DROP TABLE IF EXISTS cleaned_customer_data;
DROP TABLE IF EXISTS dim_contract;
DROP TABLE IF EXISTS raw_customer_data;

/* Bang raw: moi cot kieu text de nap du 7,043 dong (gom 11 dong TotalCharges trong) */
CREATE TABLE raw_customer_data (
    customerID        VARCHAR(20),
    gender            VARCHAR(10),
    SeniorCitizen     VARCHAR(5),
    Partner           VARCHAR(5),
    Dependents        VARCHAR(5),
    tenure            VARCHAR(10),
    PhoneService      VARCHAR(5),
    MultipleLines     VARCHAR(30),
    InternetService   VARCHAR(20),
    OnlineSecurity    VARCHAR(30),
    OnlineBackup      VARCHAR(30),
    DeviceProtection  VARCHAR(30),
    TechSupport       VARCHAR(30),
    StreamingTV       VARCHAR(30),
    StreamingMovies   VARCHAR(30),
    Contract          VARCHAR(20),
    PaperlessBilling  VARCHAR(5),
    PaymentMethod     VARCHAR(40),
    MonthlyCharges    VARCHAR(20),
    TotalCharges      VARCHAR(20),
    Churn             VARCHAR(5)
);

/* Bang tham chieu loai hop dong */
CREATE TABLE dim_contract (
    contract_type   VARCHAR(20) NOT NULL,
    contract_months INT         NOT NULL,
    PRIMARY KEY (contract_type)
);

INSERT INTO dim_contract (contract_type, contract_months) VALUES
    ('Month-to-month', 1),
    ('One year', 12),
    ('Two year', 24);

/* Bang dich: KNIME se ghi du lieu sach vao day */
CREATE TABLE cleaned_customer_data (
    customerID        VARCHAR(20)   NOT NULL,
    gender            VARCHAR(10)   NOT NULL,
    SeniorCitizen     TINYINT       NOT NULL,
    Partner           VARCHAR(5)    NOT NULL,
    Dependents        VARCHAR(5)    NOT NULL,
    tenure            INT           NOT NULL,
    PhoneService      VARCHAR(5)    NOT NULL,
    MultipleLines     VARCHAR(5)    NOT NULL,
    InternetService   VARCHAR(20)   NOT NULL,
    OnlineSecurity    VARCHAR(5)    NOT NULL,
    OnlineBackup      VARCHAR(5)    NOT NULL,
    DeviceProtection  VARCHAR(5)    NOT NULL,
    TechSupport       VARCHAR(5)    NOT NULL,
    StreamingTV       VARCHAR(5)    NOT NULL,
    StreamingMovies   VARCHAR(5)    NOT NULL,
    Contract          VARCHAR(20)   NOT NULL,
    PaperlessBilling  VARCHAR(5)    NOT NULL,
    PaymentMethod     VARCHAR(40)   NOT NULL,
    MonthlyCharges    DECIMAL(8,2)  NOT NULL,
    TotalCharges      DECIMAL(10,2) NOT NULL,
    Churn             VARCHAR(5)    NOT NULL,
    churn_flag        TINYINT       NOT NULL,
    tenure_group      VARCHAR(12)   NOT NULL,
    PRIMARY KEY (customerID),
    INDEX idx_contract (Contract),
    INDEX idx_tenure_group (tenure_group),
    CONSTRAINT fk_cleaned_contract FOREIGN KEY (Contract) REFERENCES dim_contract (contract_type)
);

/* Kiem tra cau truc: phai co 3 bang */
SHOW TABLES;

/* SAU KHI NAP CSV, chay 2 cau nay:
   cau 1 phai ra 7043, cau 2 phai ra 11 */
-- SELECT COUNT(*) AS total_rows FROM raw_customer_data;
-- SELECT COUNT(*) AS blank_total_charges FROM raw_customer_data WHERE TotalCharges IS NULL OR TRIM(TotalCharges) = '';
