/* ==========================================================
   DDDM 2026 | Week 2 | File 04
   Muc dich: kiem tra bang sach SAU khi KNIME ghi ve MySQL,
   ghi so lieu AFTER, tao bang so sanh truoc va sau, chay KPI ban dau.
   Chay SAU khi workflow KNIME da ghi xong cleaned_customer_data.
   ========================================================== */

USE dddm_telco_churn;

/* A. KIEM TRA BANG SACH */

SELECT COUNT(*) AS cleaned_rows, COUNT(DISTINCT customerID) AS distinct_ids
FROM cleaned_customer_data;

SELECT
    (SELECT COUNT(*) FROM raw_customer_data)     AS raw_rows,
    (SELECT COUNT(*) FROM cleaned_customer_data) AS cleaned_rows;

/* Khach co trong raw nhung mat o cleaned, ky vong 0 dong */
SELECT r.customerID
FROM raw_customer_data r
LEFT JOIN cleaned_customer_data c ON c.customerID = r.customerID
WHERE c.customerID IS NULL;

/* Bang dung 11 khach tenure bang 0 voi TotalCharges da dien 0 */
SELECT customerID, tenure, MonthlyCharges, TotalCharges, Churn
FROM cleaned_customer_data
WHERE tenure = 0;

DESCRIBE cleaned_customer_data;

/* B. GHI SO LIEU AFTER (xoa truoc de chay lai khong bi trung) */
DELETE FROM data_quality_log WHERE stage = 'AFTER' AND log_id > 0;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'AFTER', 'TotalCharges trong', 'Completeness',
       SUM(TotalCharges IS NULL), COUNT(*)
FROM cleaned_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'AFTER', 'customerID trung lap', 'Uniqueness',
       COUNT(*) - COUNT(DISTINCT customerID), COUNT(*)
FROM cleaned_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'AFTER', 'TotalCharges khong phai so', 'Validity',
       SUM(TotalCharges IS NULL OR TotalCharges < 0), COUNT(*)
FROM cleaned_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'AFTER', 'Gia tri ngoai mien (Churn, gender, SeniorCitizen, Contract, InternetService)', 'Validity',
       SUM(Churn NOT IN ('Yes', 'No')
           OR gender NOT IN ('Male', 'Female')
           OR SeniorCitizen NOT IN (0, 1)
           OR Contract NOT IN ('Month-to-month', 'One year', 'Two year')
           OR InternetService NOT IN ('DSL', 'Fiber optic', 'No')), COUNT(*)
FROM cleaned_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
SELECT 'AFTER', 'Nhan du thua No internet service hoac No phone service', 'Consistency',
       SUM(OnlineSecurity NOT IN ('Yes', 'No') OR OnlineBackup NOT IN ('Yes', 'No')
           OR DeviceProtection NOT IN ('Yes', 'No') OR TechSupport NOT IN ('Yes', 'No')
           OR StreamingTV NOT IN ('Yes', 'No') OR StreamingMovies NOT IN ('Yes', 'No')
           OR MultipleLines NOT IN ('Yes', 'No')), COUNT(*)
FROM cleaned_customer_data;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
WITH ranked AS (
    SELECT MonthlyCharges AS v,
           ROW_NUMBER() OVER (ORDER BY MonthlyCharges) AS rn,
           COUNT(*) OVER () AS n
    FROM cleaned_customer_data
), q AS (
    SELECT MAX(CASE WHEN rn = CEIL(0.25 * n) THEN v END) AS q1,
           MAX(CASE WHEN rn = CEIL(0.75 * n) THEN v END) AS q3
    FROM ranked
)
SELECT 'AFTER', 'MonthlyCharges ngoai hang rao IQR', 'Outliers',
       (SELECT COUNT(*) FROM ranked r
         WHERE r.v < q.q1 - 1.5 * (q.q3 - q.q1) OR r.v > q.q3 + 1.5 * (q.q3 - q.q1)),
       (SELECT COUNT(*) FROM cleaned_customer_data)
FROM q;

INSERT INTO data_quality_log (stage, check_name, dimension, issue_count, total_rows)
WITH ranked AS (
    SELECT tenure AS v,
           ROW_NUMBER() OVER (ORDER BY tenure) AS rn,
           COUNT(*) OVER () AS n
    FROM cleaned_customer_data
), q AS (
    SELECT MAX(CASE WHEN rn = CEIL(0.25 * n) THEN v END) AS q1,
           MAX(CASE WHEN rn = CEIL(0.75 * n) THEN v END) AS q3
    FROM ranked
)
SELECT 'AFTER', 'tenure ngoai hang rao IQR', 'Outliers',
       (SELECT COUNT(*) FROM ranked r
         WHERE r.v < q.q1 - 1.5 * (q.q3 - q.q1) OR r.v > q.q3 + 1.5 * (q.q3 - q.q1)),
       (SELECT COUNT(*) FROM cleaned_customer_data)
FROM q;

/* C. BANG SO SANH TRUOC VA SAU (chup man hinh cho slide) */
SELECT b.dimension, b.check_name,
       b.issue_count AS before_count, b.issue_pct AS before_pct,
       a.issue_count AS after_count,  a.issue_pct AS after_pct
FROM data_quality_log b
JOIN data_quality_log a ON a.check_name = b.check_name AND a.stage = 'AFTER'
WHERE b.stage = 'BEFORE'
ORDER BY b.log_id;

/* D. KPI BAN DAU TREN BANG SACH */

/* D1: KPI tong quan */
SELECT COUNT(*)                                          AS total_customers,
       SUM(churn_flag)                                   AS churned_customers,
       ROUND(AVG(churn_flag) * 100, 2)                   AS churn_rate_pct,
       ROUND(AVG(MonthlyCharges), 2)                     AS avg_monthly_charges,
       ROUND(SUM(MonthlyCharges), 2)                     AS total_monthly_revenue,
       ROUND(SUM(CASE WHEN churn_flag = 1 THEN MonthlyCharges ELSE 0 END), 2) AS monthly_revenue_lost,
       ROUND(SUM(CASE WHEN churn_flag = 1 THEN MonthlyCharges ELSE 0 END) * 100.0 / SUM(MonthlyCharges), 2) AS revenue_lost_pct
FROM cleaned_customer_data;

/* D2: churn theo loai hop dong, JOIN voi dim_contract (tra loi DQ1) */
SELECT d.contract_type, d.contract_months,
       COUNT(*)                                  AS total_customers,
       SUM(c.churn_flag)                         AS churn_count,
       ROUND(AVG(c.churn_flag) * 100, 2)         AS churn_rate_pct,
       ROUND(AVG(c.MonthlyCharges), 2)           AS avg_monthly_charges
FROM cleaned_customer_data c
JOIN dim_contract d ON d.contract_type = c.Contract
GROUP BY d.contract_type, d.contract_months
ORDER BY churn_rate_pct DESC;

/* D3: churn theo nhom tenure (DQ1) */
SELECT tenure_group,
       COUNT(*)                          AS total_customers,
       SUM(churn_flag)                   AS churn_count,
       ROUND(AVG(churn_flag) * 100, 2)   AS churn_rate_pct
FROM cleaned_customer_data
GROUP BY tenure_group
ORDER BY tenure_group;

/* D4: churn theo dich vu internet va muc phi hang thang (DQ1) */
SELECT InternetService,
       COUNT(*)                          AS total_customers,
       ROUND(AVG(churn_flag) * 100, 2)   AS churn_rate_pct,
       ROUND(AVG(MonthlyCharges), 2)     AS avg_monthly_charges
FROM cleaned_customer_data
GROUP BY InternetService
ORDER BY churn_rate_pct DESC;

/* D5: tac dong cua dich vu bo tro len churn, chi tinh khach co internet (DQ2) */
SELECT 'TechSupport' AS addon, TechSupport AS has_addon, COUNT(*) AS customers, ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM cleaned_customer_data WHERE InternetService <> 'No' GROUP BY TechSupport
UNION ALL
SELECT 'OnlineSecurity', OnlineSecurity, COUNT(*), ROUND(AVG(churn_flag) * 100, 2)
FROM cleaned_customer_data WHERE InternetService <> 'No' GROUP BY OnlineSecurity
UNION ALL
SELECT 'OnlineBackup', OnlineBackup, COUNT(*), ROUND(AVG(churn_flag) * 100, 2)
FROM cleaned_customer_data WHERE InternetService <> 'No' GROUP BY OnlineBackup
UNION ALL
SELECT 'DeviceProtection', DeviceProtection, COUNT(*), ROUND(AVG(churn_flag) * 100, 2)
FROM cleaned_customer_data WHERE InternetService <> 'No' GROUP BY DeviceProtection
ORDER BY addon, has_addon;

/* D6: churn theo phuong thuc thanh toan */
SELECT PaymentMethod,
       COUNT(*)                          AS total_customers,
       ROUND(AVG(churn_flag) * 100, 2)   AS churn_rate_pct
FROM cleaned_customer_data
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;

/* D7: nhom rui ro cao de dinh huong DQ3: hop dong thang, tenure toi 12 thang, co internet */
SELECT COUNT(*)                                   AS customers,
       ROUND(AVG(churn_flag) * 100, 2)            AS churn_rate_pct,
       ROUND(SUM(MonthlyCharges), 2)              AS monthly_revenue_in_segment
FROM cleaned_customer_data
WHERE Contract = 'Month-to-month' AND tenure <= 12 AND InternetService <> 'No';
