# DDDM 2026: Telecom Customer Churn Prediction and Retention Decision Support

Group Spicy Girls, Data Driven Decision Making (DDDM) 2026, VNUK.
Members: Nguyễn Gia Khả Ái (23060016), Nguyễn Ngọc Vân Khanh (23060012), Nguyễn Lê Tiên An (23060006).

This repository holds a reproducible decision support system that predicts which telecom customers are likely to churn and turns the predictions into retention decisions. The pipeline is: dataset, MySQL, KNIME, Logistic Regression, MySQL (results), Power BI dashboard, decisions.

## 1. Decision questions

- DQ1: Which customer segments, defined by contract, tenure and monthly charges, have the highest probability of churn?
- DQ2: Which add-on services (Tech Support, Online Security) reduce churn risk?
- DQ3: How should the retention budget be allocated across risk groups defined by the predicted probability?

## 2. Results at a glance

| Item | Result |
|---|---|
| Customers | 7,043 (1,869 churners, 26.54%) |
| Split | 80/20, stratified by churn_flag, seed 42: 5,634 train, 1,409 test |
| Model | Logistic Regression (IRLS) with 18 input variables, trained on the training set only |
| Threshold | 0.25 (chosen to reach the recall target) |
| Recall (test) | 0.818 (target at least 0.80) |
| Precision (test) | 0.512 |
| AUC-ROC (test) | 0.860 (target at least 0.75) |
| Risk tiers (test) | High (probability at least 0.50): 309 customers, 68.0% churn. Medium (0.25 to below 0.50): 289, 33.2%. Low (below 0.25): 811, 8.4% |

Known limitations: the threshold was chosen on the test set, there is one split and no cross-validation, multicollinearity was not tested with the variance inflation factor, and the data has no cost or date information. The paper (docs/paper) discusses them.

## 3. Repository structure

| Path | Content |
|---|---|
| sql/ | MySQL scripts 01 to 07, run in numeric order (section 6) |
| knime/ | KNIME workflows: Week2_Data_Cleaning.knwf and Week3_ML_Churn.knwf |
| dashboard/ | Power BI source files (.pbix) |
| docs/paper/ | IEEE-style paper (PDF and editable DOCX) and figures |
| docs/slides/ | Week 4 presentation (PPTX and PDF) |
| docs/screenshots/ | Evidence screenshots for Weeks 2 and 3 |
| docs/ | Work breakdown structure (WBS) with planned and actual effort |

The customer CSV is not in the repository (see section 4).

## 4. Data

- Source: IBM Telco Customer Churn sample data set, distributed on Kaggle (https://www.kaggle.com/datasets/blastchar/telco-customer-churn). Check the licence shown on that page before reuse.
- Size: 7,043 records and 21 attributes. Target: Churn (Yes or No).
- The repository does not redistribute the file. The .gitignore excludes all .csv files. Download the CSV from the source and keep it on your computer.

## 5. Requirements

- MySQL Server 8.0 or later and MySQL Workbench
- KNIME Analytics Platform 5.x
- Power BI Desktop (Windows)
- Git

## 6. How to rerun the pipeline from the beginning

Run these steps in order. Every SQL script is safe to run again unless its header says otherwise.

1. Download the Telco CSV from the source in section 4.
2. In MySQL Workbench, create the schema: `CREATE DATABASE dddm_telco_churn;`
3. Run `sql/01_create_raw_table.sql`. It creates raw_customer_data with every column as text, so all 7,043 rows load (the default import wizard drops 11 rows with a blank TotalCharges).
4. Load the CSV into raw_customer_data with the Table Data Import Wizard (use the existing table). Run the check at the end of file 01. The correct result is 7,043 rows.
5. Run `sql/02_data_quality_before.sql` to see data quality before cleaning.
6. Run `sql/03_create_cleaned_and_dq_log.sql`. It creates dim_contract, cleaned_customer_data and data_quality_log, and records the BEFORE figures.
7. In KNIME, choose File, Import KNIME Workflow, and select `knime/Week2_Data_Cleaning.knwf`. Open the Credentials Configuration node, enter your MySQL user and password, and check that the MySQL Connector points to localhost:3306 and the database dddm_telco_churn. The repository contains no password. Execute the whole workflow. It writes cleaned_customer_data.
8. Run `sql/04_verify_after_and_kpi.sql` to log the AFTER figures and see the KPIs.
9. Run `sql/06_create_churn_predictions.sql` to create the empty table churn_predictions.
10. In KNIME, import `knime/Week3_ML_Churn.knwf`, enter the credentials in the same way and execute it. The workflow reads cleaned_customer_data, splits the data 80/20 (stratified, seed 42), trains Logistic Regression on the training set, predicts for all customers, applies the 0.25 threshold, evaluates on the test set and writes 7,043 rows to churn_predictions.
11. Run `sql/07_dashboard_view.sql`. It creates the view v_dashboard_data (cleaned data, predictions and risk tier) and prints three checks. Expected results: 7,043 rows in the view; 5,634 train and 1,409 test; on the test set High 309 (68.0%), Medium 289 (33.2%), Low 811 (8.4%).
12. Refresh the dashboard (section 8).

For a clean second computer, `sql/05_setup_for_teammate.sql` builds the empty schema and tables in one run. After it, load the CSV (step 4) and continue from step 7.

## 7. Database tables

| Table or view | Content |
|---|---|
| raw_customer_data | Raw data, every column as text, 7,043 rows |
| dim_contract | Contract types and lengths, primary key contract_type |
| cleaned_customer_data | Cleaned data, primary key customerID, foreign key Contract to dim_contract; adds churn_flag and tenure_group |
| data_quality_log | Data quality results before and after cleaning |
| churn_predictions | One row per customer: customerID (primary key), dataset_split, actual_churn, churn_probability, predicted_churn |
| v_dashboard_data (view) | cleaned_customer_data joined with churn_predictions, plus risk_tier |

## 8. Dashboard: source, refresh and rerun

The Power BI dashboard uses the view v_dashboard_data, one row per customer.

- Option A, direct connection: in Power BI choose Get Data, MySQL database, enter the server and database, and select v_dashboard_data. After a rerun, choose Refresh.
- Option B, CSV export: in MySQL Workbench run `SELECT * FROM v_dashboard_data;`, export the result grid to CSV, and point Power BI to the file (Get Data, Text/CSV). After a rerun, export again and choose Refresh. The final dashboard (dashboard/DDDM_Dashboard_Final.pbix) uses this option and loads churn_dashboard_data.csv. The data is stored inside the .pbix file, so it opens without the CSV. To refresh it from a new export, open Transform data, Data source settings, and change the file path (the saved path points to the computer of the author).

The dashboard shows the KPIs (number of customers and churn rate), churn by contract, tenure group, payment method, internet service and add-on services, churn by monthly-charge bin, the distribution of the predicted probability, the risk tiers and a table of priority customers (probability at least 0.25, highest first). The two add-on charts (Online Security and Tech Support) count only customers with internet service (DSL or Fiber optic), as in the Week 2 analysis. A text note reports the model performance on the test set at threshold 0.25 (recall 0.818, precision 0.512, AUC 0.860), computed outside Power BI. Slicers filter the views by contract, internet service, tenure group, risk tier and dataset split. With no slicer selected, the tiers cover all 7,043 customers (High 1,531, Medium 1,460, Low 4,052). When the split slicer is set to test, the tier figures match the check in file 07 (309, 289 and 811).

## 9. Cleaning rules (Week 2)

- TotalCharges blank (11 customers with tenure 0): set to 0, keep the rows.
- Duplicate customerID: none found (the result is in data_quality_log).
- Labels No internet service and No phone service: merged into No (2,208 rows changed).
- IQR outliers: none found in MonthlyCharges or tenure.
- Two columns added: churn_flag (1 if Churn is Yes) and tenure_group (four bins: 0-12, 13-24, 25-48, 49-72 months).

## 10. Model design

- Input variables: 18 (4 demographic, 9 phone and internet services, 3 contract and payment, 2 numeric: tenure and MonthlyCharges).
- Excluded columns: customerID (identifier), Churn and churn_flag (target), tenure_group (duplicates tenure), TotalCharges (close to tenure times MonthlyCharges).
- Targets set in Week 1: recall at least 0.80 and AUC-ROC at least 0.75. Both are met on the test set at threshold 0.25.

## 11. Individual contributions

The WBS files are the record of tasks, owners, planned hours and actual hours: docs/DDDM_WBS_Week3_and_Week4_Plan.xlsx (Week 3 and the Week 4 plan) and docs/DDDM_WBS_Week4.xlsx (Week 4 final hours).

| Task | Owner |
|---|---|
| Feature and experimental design, KNIME Logistic Regression model (3.1) | Khanh |
| Methodology and Results sections of the paper, workflow figure (3.2) | Ái |
| Week 3 draft dashboard in Power BI (3.3) | An |
| Update of the WBS and the Week 4 plan (3.5) | An |
| Week 3 evidence on GitHub (3.6) | Khanh |
| End-to-end pipeline and README (4.1, 4.2) | Khanh |
| Final dashboard (4.3) | An |
| Recommendations (4.4) | An (draft), Khanh (model figures) |
| IEEE paper (4.5) | Ái (Abstract, Keywords, Introduction, Methodology, Experiments and Results), An (Discussion and Decision Recommendations), Khanh (Related Work, Conclusion, References, assembly and formatting) |
| Pipeline diagram (4.6) | Ái |
| Presentation (4.7) and final submission check (4.9) | Whole group |
| Plan versus actual reflection (4.8) | Each member enters own hours; An consolidates |

## 12. Academic integrity

The group cites its data source, tools and papers according to the VNUK academic integrity policy. The database password is never stored in the repository.
