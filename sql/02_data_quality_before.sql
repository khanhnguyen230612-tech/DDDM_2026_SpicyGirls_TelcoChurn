/* ==========================================================
   DDDM 2026 | Week 2 | File 02
   Muc dich: danh gia chat luong du lieu TRUOC khi lam sach (tren bang raw)
   Moi khoi la mot kiem tra. Chay tung khoi, chup man hinh ket qua cho slide.
   ========================================================== */

USE dddm_telco_churn;

/* KIEM TRA 1: COMPLETENESS (gia tri thieu hoac rong) tren 21 cot */
SELECT 'customerID' AS column_name, SUM(customerID IS NULL OR TRIM(customerID) = '') AS missing_count, COUNT(*) AS total_rows FROM raw_customer_data
UNION ALL SELECT 'gender', SUM(gender IS NULL OR TRIM(gender) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'SeniorCitizen', SUM(SeniorCitizen IS NULL OR TRIM(SeniorCitizen) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'Partner', SUM(Partner IS NULL OR TRIM(Partner) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'Dependents', SUM(Dependents IS NULL OR TRIM(Dependents) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'tenure', SUM(tenure IS NULL OR TRIM(tenure) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'PhoneService', SUM(PhoneService IS NULL OR TRIM(PhoneService) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'MultipleLines', SUM(MultipleLines IS NULL OR TRIM(MultipleLines) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'InternetService', SUM(InternetService IS NULL OR TRIM(InternetService) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'OnlineSecurity', SUM(OnlineSecurity IS NULL OR TRIM(OnlineSecurity) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'OnlineBackup', SUM(OnlineBackup IS NULL OR TRIM(OnlineBackup) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'DeviceProtection', SUM(DeviceProtection IS NULL OR TRIM(DeviceProtection) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'TechSupport', SUM(TechSupport IS NULL OR TRIM(TechSupport) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'StreamingTV', SUM(StreamingTV IS NULL OR TRIM(StreamingTV) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'StreamingMovies', SUM(StreamingMovies IS NULL OR TRIM(StreamingMovies) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'Contract', SUM(Contract IS NULL OR TRIM(Contract) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'PaperlessBilling', SUM(PaperlessBilling IS NULL OR TRIM(PaperlessBilling) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'PaymentMethod', SUM(PaymentMethod IS NULL OR TRIM(PaymentMethod) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'MonthlyCharges', SUM(MonthlyCharges IS NULL OR TRIM(MonthlyCharges) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'TotalCharges', SUM(TotalCharges IS NULL OR TRIM(TotalCharges) = ''), COUNT(*) FROM raw_customer_data
UNION ALL SELECT 'Churn', SUM(Churn IS NULL OR TRIM(Churn) = ''), COUNT(*) FROM raw_customer_data;

/* KIEM TRA 2A: UNIQUENESS theo customerID */
SELECT
    COUNT(*)                                  AS total_rows,
    COUNT(DISTINCT customerID)                AS distinct_ids,
    COUNT(*) - COUNT(DISTINCT customerID)     AS duplicate_id_rows
FROM raw_customer_data;

/* KIEM TRA 2B: nhom khach co ho so giong het nhau o 20 cot (khong tinh customerID).
   Chi bao cao. Hai khach khac ID co the trung ho so ma van la hai nguoi that. */
SELECT COUNT(*) AS identical_profile_groups, COALESCE(SUM(c), 0) AS rows_in_those_groups
FROM (
    SELECT COUNT(*) AS c
    FROM raw_customer_data
    GROUP BY gender, SeniorCitizen, Partner, Dependents, tenure, PhoneService, MultipleLines,
             InternetService, OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport,
             StreamingTV, StreamingMovies, Contract, PaperlessBilling, PaymentMethod,
             MonthlyCharges, TotalCharges, Churn
    HAVING COUNT(*) > 1
) AS g;

/* KIEM TRA 3: VALIDITY (kieu, dinh dang, mien gia tri). Moi dong la mot quy tac. */
SELECT 'TotalCharges khong phai so' AS rule_name,
       SUM(TRIM(TotalCharges) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$') AS violations
FROM raw_customer_data
UNION ALL
SELECT 'MonthlyCharges khong phai so duong',
       SUM(TRIM(MonthlyCharges) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' OR TRIM(MonthlyCharges) REGEXP '^0+(\\.0+)?$')
FROM raw_customer_data
UNION ALL
SELECT 'tenure khong phai so nguyen khong am',
       SUM(TRIM(tenure) NOT REGEXP '^[0-9]+$')
FROM raw_customer_data
UNION ALL
SELECT 'SeniorCitizen ngoai {0,1}',
       SUM(TRIM(SeniorCitizen) NOT IN ('0', '1'))
FROM raw_customer_data
UNION ALL
SELECT 'Churn ngoai {Yes,No}',
       SUM(TRIM(Churn) NOT IN ('Yes', 'No'))
FROM raw_customer_data
UNION ALL
SELECT 'gender ngoai {Male,Female}',
       SUM(TRIM(gender) NOT IN ('Male', 'Female'))
FROM raw_customer_data
UNION ALL
SELECT 'Contract ngoai 3 loai hop dong',
       SUM(TRIM(Contract) NOT IN ('Month-to-month', 'One year', 'Two year'))
FROM raw_customer_data
UNION ALL
SELECT 'InternetService ngoai {DSL,Fiber optic,No}',
       SUM(TRIM(InternetService) NOT IN ('DSL', 'Fiber optic', 'No'))
FROM raw_customer_data
UNION ALL
SELECT 'Gia tri co khoang trang thua o dau hoac cuoi (cot Contract, Churn, PaymentMethod)',
       SUM(Contract <> TRIM(Contract) OR Churn <> TRIM(Churn) OR PaymentMethod <> TRIM(PaymentMethod))
FROM raw_customer_data;

/* KIEM TRA 4: CONSISTENCY (nhat quan giua cac cot) */

/* 4A: khach khong dung internet nhung sau cot dich vu khong ghi 'No internet service' */
SELECT COUNT(*) AS internet_no_but_service_not_marked
FROM raw_customer_data
WHERE InternetService = 'No'
  AND (OnlineSecurity <> 'No internet service' OR OnlineBackup <> 'No internet service'
       OR DeviceProtection <> 'No internet service' OR TechSupport <> 'No internet service'
       OR StreamingTV <> 'No internet service' OR StreamingMovies <> 'No internet service');

/* 4B: khach khong co dich vu dien thoai nhung MultipleLines khong ghi 'No phone service' */
SELECT COUNT(*) AS phone_no_but_lines_not_marked
FROM raw_customer_data
WHERE PhoneService = 'No' AND MultipleLines <> 'No phone service';

/* 4C: nhan du thua 'No internet service' hoac 'No phone service' (mot y nghia, hai nhan).
   Day la ly do ta gop ve 'No' trong KNIME. */
SELECT COUNT(*) AS rows_with_redundant_labels
FROM raw_customer_data
WHERE OnlineSecurity = 'No internet service' OR OnlineBackup = 'No internet service'
   OR DeviceProtection = 'No internet service' OR TechSupport = 'No internet service'
   OR StreamingTV = 'No internet service' OR StreamingMovies = 'No internet service'
   OR MultipleLines = 'No phone service';

/* 4D: giai thich 11 dong TotalCharges trong, chung phai khop tenure = 0 */
SELECT
    SUM(TRIM(TotalCharges) = '' AND tenure = '0')  AS blank_and_tenure_zero,
    SUM(TRIM(TotalCharges) = '' AND tenure <> '0') AS blank_but_tenure_positive,
    SUM(TRIM(TotalCharges) <> '' AND tenure = '0') AS tenure_zero_but_has_charges
FROM raw_customer_data;

/* KIEM TRA 5: OUTLIERS theo quy tac IQR 1.5 (can MySQL 8.0 tro len) */
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
SELECT 'MonthlyCharges' AS column_name, q.q1, q.q3,
       q.q1 - 1.5 * (q.q3 - q.q1) AS lower_fence,
       q.q3 + 1.5 * (q.q3 - q.q1) AS upper_fence,
       (SELECT COUNT(*) FROM ranked r
         WHERE r.v < q.q1 - 1.5 * (q.q3 - q.q1) OR r.v > q.q3 + 1.5 * (q.q3 - q.q1)) AS outlier_count
FROM q;

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
SELECT 'tenure' AS column_name, q.q1, q.q3,
       q.q1 - 1.5 * (q.q3 - q.q1) AS lower_fence,
       q.q3 + 1.5 * (q.q3 - q.q1) AS upper_fence,
       (SELECT COUNT(*) FROM ranked r
         WHERE r.v < q.q1 - 1.5 * (q.q3 - q.q1) OR r.v > q.q3 + 1.5 * (q.q3 - q.q1)) AS outlier_count
FROM q;

/* Khoang gia tri de mo ta (min, max, trung binh) */
SELECT MIN(CAST(tenure AS SIGNED)) AS tenure_min, MAX(CAST(tenure AS SIGNED)) AS tenure_max,
       ROUND(AVG(CAST(tenure AS SIGNED)), 2) AS tenure_avg,
       MIN(CAST(MonthlyCharges AS DECIMAL(10,2))) AS monthly_min,
       MAX(CAST(MonthlyCharges AS DECIMAL(10,2))) AS monthly_max,
       ROUND(AVG(CAST(MonthlyCharges AS DECIMAL(10,2))), 2) AS monthly_avg,
       MIN(CAST(NULLIF(TRIM(TotalCharges), '') AS DECIMAL(10,2))) AS total_min,
       MAX(CAST(NULLIF(TRIM(TotalCharges), '') AS DECIMAL(10,2))) AS total_max
FROM raw_customer_data;

/* KIEM TRA 6: CLASS BALANCE cua bien muc tieu Churn (cho muc rui ro mo hinh) */
SELECT Churn, COUNT(*) AS customers,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM raw_customer_data), 2) AS pct
FROM raw_customer_data
GROUP BY Churn;
