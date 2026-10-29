/* ==========================================================
   DDDM 2026 | Week 2 | File 01
   Muc dich: tao lai bang raw voi MOI cot kieu text de nap du 7,043 dong
   (Import Wizard o Week 1 da tu bo 11 dong vi TotalCharges bi trong).
   Cach chay: mo file trong MySQL Workbench, chon toan bo, bam Ctrl+Shift+Enter.
   ========================================================== */

USE dddm_telco_churn;

/* AN TOAN KHI CHAY LAI: file nay chi tao bang neu chua co, khong xoa, khong doi ten.
   (Buoc doi ten bang Week 1 thanh raw_customer_data_week1_backup da lam mot lan
   tren may chinh. Neu chay lai lenh DROP va RENAME, bang raw dang co 7043 dong
   se bi chuyen thanh bang sao luu va bang raw moi rong.) */
CREATE TABLE IF NOT EXISTS raw_customer_data (
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

/* SAU KHI CHAY XONG PHAN TREN:
   Chuot phai bang raw_customer_data trong Navigator > Table Data Import Wizard
   > chon file CSV Telco > Use existing table: dddm_telco_churn.raw_customer_data
   > kiem tra 21 cot da ghep dung ten > Next > Finish.
   Roi chay tiep phan kiem tra duoi day. */

/* Kiem tra 1: tong so dong, ky vong 7043 */
SELECT COUNT(*) AS total_rows FROM raw_customer_data;

/* Kiem tra 2: so dong TotalCharges trong, ky vong 11 */
SELECT COUNT(*) AS blank_total_charges
FROM raw_customer_data
WHERE TotalCharges IS NULL OR TRIM(TotalCharges) = '';

/* Kiem tra 3: xem 11 dong do, tenure thuong bang 0 */
SELECT customerID, tenure, MonthlyCharges, TotalCharges, Churn
FROM raw_customer_data
WHERE TotalCharges IS NULL OR TRIM(TotalCharges) = '';

/* Kiem tra 4 (chi o may chinh co bang sao luu): so dong bang sao luu va bang raw */
-- SELECT
--     (SELECT COUNT(*) FROM raw_customer_data_week1_backup) AS backup_rows,
--     (SELECT COUNT(*) FROM raw_customer_data)              AS raw_rows;
