USE dddm_telco_churn;

CREATE TABLE IF NOT EXISTS churn_predictions (
    customerID        VARCHAR(10)  NOT NULL,
    dataset_split     VARCHAR(5)   NOT NULL,
    actual_churn      TINYINT      NOT NULL,
    churn_probability DECIMAL(6,4) NOT NULL,
    predicted_churn   TINYINT      NOT NULL,
    PRIMARY KEY (customerID),
    CONSTRAINT fk_pred_customer FOREIGN KEY (customerID)
        REFERENCES cleaned_customer_data (customerID)
);
