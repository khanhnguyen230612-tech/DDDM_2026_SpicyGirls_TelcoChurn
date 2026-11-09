/* ==========================================================
   DDDM 2026 | Week 4 | File 07
   Purpose: create the view that feeds the Power BI dashboard.
   One row per customer: cleaned data + model output + risk tier.
   Run AFTER file 06 and AFTER the KNIME workflow Week3_ML_Churn
   has written churn_predictions (7,043 rows).
   Risk tiers: High >= 0.50, Medium >= 0.25 and < 0.50, Low < 0.25.
   ========================================================== */

USE dddm_telco_churn;

CREATE OR REPLACE VIEW v_dashboard_data AS
SELECT
    c.*,
    p.dataset_split,
    p.churn_probability,
    p.predicted_churn,
    CASE
        WHEN p.churn_probability >= 0.50 THEN 'High'
        WHEN p.churn_probability >= 0.25 THEN 'Medium'
        ELSE 'Low'
    END AS risk_tier
FROM cleaned_customer_data c
JOIN churn_predictions p ON p.customerID = c.customerID;

/* Check 1: expected 7043 rows */
SELECT COUNT(*) AS rows_in_view FROM v_dashboard_data;

/* Check 2: expected train 5634 and test 1409 */
SELECT dataset_split, COUNT(*) AS customers
FROM v_dashboard_data
GROUP BY dataset_split;

/* Check 3: risk tiers on the test set.
   Expected: High 309 customers 68.0 percent, Medium 289 and 33.2, Low 811 and 8.4 */
SELECT risk_tier,
       COUNT(*)                          AS customers,
       SUM(churn_flag)                   AS churners,
       ROUND(100 * AVG(churn_flag), 1)   AS churn_pct
FROM v_dashboard_data
WHERE dataset_split = 'test'
GROUP BY risk_tier
ORDER BY FIELD(risk_tier, 'High', 'Medium', 'Low');
