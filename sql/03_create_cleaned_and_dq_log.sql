/* ==========================================================
   DDDM 2026 | Week 2 | File 03
   Muc dich: tao cac bang dich truoc khi KNIME ghi du lieu ve
   gom dim_contract, cleaned_customer_data, data_quality_log
   va ghi cac so lieu BEFORE vao data_quality_log.
   Chay SAU file 01 va SAU khi da import du 7,043 dong.
   ========================================================== */

USE dddm_telco_churn;

/* Bang tham chieu loai hop dong (quan he 1 nhieu voi cleaned_customer_data) */
DROP TABLE IF EXISTS cleaned_customer_data;
DROP TABLE IF EXISTS dim_contract;

CREATE TABLE dim_contract (
    contract_type   VARCHAR(20) NOT NULL,
    contract_months INT         NOT NULL,
    PRIMARY KEY (contract_type)
);

INSERT INTO dim_contract (contract_type, contract_months) VALUES
    ('Month-to-month', 1),
    ('One year', 12),
    ('Two year', 24);

/* Bang sach: ten cot khop voi bang trong KNIME de DB Writer ghi dung */
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

/* Bang nhat ky chat luong du lieu, dung cho bang so sanh truoc va sau */
DROP TABLE IF EXISTS data_quality_log;

CREATE TABLE data_quality_log (
    log_id      INT AUTO_INCREMENT PRIMARY KEY,
    stage       VARCHAR(10) NOT NULL,
    check_name  VARCHAR(80) NOT NULL,
    dimension   VARCHAR(20) NOT NULL,
    issue_count INT         NOT NULL,
    total_rows  INT         NOT NULL,
    issue_pct   DECIMAL(6,2) GENERATED ALWAYS AS (ROUND(100 * issue_count / total_rows, 2)) STORED,
    logged_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* Ghi cac so lieu BEFORE tu bang raw. Xoa truoc de chay lai khong bi trung. */
DELETE FROM data_quality_log WHERE stage = 'BEFORE' AND log_id > 0;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'BEFORE', 'TotalCharges trong', 'Completeness',
       SUM(TotalCharges IS NULL OR TRIM(TotalCharges) = ''), COUNT(*)
FROM raw_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'BEFORE', 'customerID trung lap', 'Uniqueness',
       COUNT(*) - COUNT(DISTINCT customerID), COUNT(*)
FROM raw_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'BEFORE', 'TotalCharges khong phai so', 'Validity',
       SUM(TRIM(TotalCharges) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'), COUNT(*)
FROM raw_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'BEFORE', 'Gia tri ngoai mien (Churn, gender, SeniorCitizen, Contract, InternetService)', 'Validity',
       SUM(TRIM(Churn) NOT IN ('Yes', 'No')
           OR TRIM(gender) NOT IN ('Male', 'Female')
           OR TRIM(SeniorCitizen) NOT IN ('0', '1')
           OR TRIM(Contract) NOT IN ('Month-to-month', 'One year', 'Two year')
           OR TRIM(InternetService) NOT IN ('DSL', 'Fiber optic', 'No')), COUNT(*)
FROM raw_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'BEFORE', 'Nhan du thua No internet service hoac No phone service', 'Consistency',
       SUM(OnlineSecurity = 'No internet service' OR OnlineBackup = 'No internet service'
           OR DeviceProtection = 'No internet service' OR TechSupport = 'No internet service'
           OR StreamingTV = 'No internet service' OR StreamingMovies = 'No internet service'
           OR MultipleLines = 'No phone service'), COUNT(*)
FROM raw_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
WITH ranked AS (
    SELECT CAST(MonthlyCharges AS DECIMAL(10,2)) AS v,
           ROW_NUMBER() OVER (ORDER BY CAST(MonthlyCharges AS DECIMAL(10,2))) AS rn,
           COUNT(*) OVER () AS n
    FROM raw_customer_data
), q AS (
    SELECT MAX(CASE WHEN rn = CEIL(0.25 * n) THEN v END) AS q1,
           MAX(CASE WHEN rn = CEIL(0.75 * n) THEN v END) AS q3
    FROM ranked
)
SELECT 'BEFORE', 'MonthlyCharges ngoai hang rao IQR', 'Outliers',
       (SELECT COUNT(*) FROM ranked r
         WHERE r.v < q.q1 - 1.5 * (q.q3 - q.q1) OR r.v > q.q3 + 1.5 * (q.q3 - q.q1)),
       (SELECT COUNT(*) FROM raw_customer_data)
FROM q;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
WITH ranked AS (
    SELECT CAST(tenure AS SIGNED) AS v,
           ROW_NUMBER() OVER (ORDER BY CAST(tenure AS SIGNED)) AS rn,
           COUNT(*) OVER () AS n
    FROM raw_customer_data
), q AS (
    SELECT MAX(CASE WHEN rn = CEIL(0.25 * n) THEN v END) AS q1,
           MAX(CASE WHEN rn = CEIL(0.75 * n) THEN v END) AS q3
    FROM ranked
)
SELECT 'BEFORE', 'tenure ngoai hang rao IQR', 'Outliers',
       (SELECT COUNT(*) FROM ranked r
         WHERE r.v < q.q1 - 1.5 * (q.q3 - q.q1) OR r.v > q.q3 + 1.5 * (q.q3 - q.q1)),
       (SELECT COUNT(*) FROM raw_customer_data)
FROM q;

SELECT * FROM data_quality_log WHERE stage = 'BEFORE';
