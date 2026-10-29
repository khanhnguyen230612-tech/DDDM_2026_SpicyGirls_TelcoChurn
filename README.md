DDDM 2026 Telco Customer Churn: Retention Decision Support System

Nhóm Spicy Girls, môn Data Driven Decision Making, VNUK.
Thành viên: Nguyễn Gia Khả Ái (23060016), Nguyễn Ngọc Vân Khanh (23060012), Nguyễn Lê Tiên An (23060006).

Mục tiêu dự án

Xây dựng hệ thống hỗ trợ quyết định giữ chân khách hàng viễn thông theo luồng: Dataset, MySQL, KNIME, MySQL (kết quả), Power BI, Decisions. Mô hình chính là Logistic Regression dự đoán xác suất rời bỏ dịch vụ.

Ba câu hỏi quyết định

DQ1: Nhóm khách nào (theo hợp đồng, tenure, cước hàng tháng) có xác suất rời bỏ cao nhất?
DQ2: Dịch vụ bổ trợ nào (Tech Support, Online Security) giảm rủi ro rời bỏ rõ nhất?
DQ3: Ngân sách marketing giữ chân nên phân bổ cho các nhóm rủi ro như thế nào để giữ được nhiều doanh thu nhất?

Dữ liệu

Nguồn: Kaggle, IBM Telco Customer Churn. Đường dẫn: điền link trang dataset tại đây.
Quy mô: 7,043 bản ghi, 21 thuộc tính. Biến mục tiêu: Churn (Yes hoặc No).
Giấy phép và quyền sở hữu: điền theo thông tin ghi trên trang dataset.
Repo không chứa dữ liệu khách hàng nếu giấy phép không cho phép. Hãy tải CSV từ nguồn và đặt vào máy cục bộ.

Cấu trúc thư mục

sql: các script MySQL, chạy theo thứ tự số.
knime: workflow đã xuất (Week2_Data_Cleaning.knwf).
docs/screenshots: ảnh minh chứng.
data: ghi chú nguồn dữ liệu.

Yêu cầu môi trường

MySQL Server 8.0 trở lên và MySQL Workbench.
KNIME Analytics Platform 5.x.
Git.
Power BI Desktop (dùng từ Week 3).

Cách chạy lại pipeline Week 2

Bước 1. Tải file CSV từ Kaggle và lưu trên máy.
Bước 2. Trong MySQL Workbench, tạo schema dddm_telco_churn (câu lệnh: CREATE DATABASE dddm_telco_churn;).
Bước 3. Chạy sql/01_create_raw_table.sql đến hết lệnh CREATE TABLE. File chỉ tạo bảng nếu chưa có, nên chạy lại không làm mất dữ liệu.
Bước 4. Dùng Table Data Import Wizard để nạp CSV vào bảng raw_customer_data (Use existing table). Chạy phần kiểm tra cuối file 01, kết quả đúng là 7043 dòng.
Bước 5. Chạy sql/02_data_quality_before.sql để xem chất lượng dữ liệu trước làm sạch.
Bước 6. Chạy sql/03_create_cleaned_and_dq_log.sql để tạo bảng đích và ghi số liệu BEFORE.
Bước 7. Trong KNIME, chọn File, Import KNIME Workflow, chọn knime/Week2_Data_Cleaning.knwf.
Bước 8. Mở node Credentials Configuration (mysql_cred) và nhập user, mật khẩu MySQL của bạn. Repo không chứa mật khẩu. Kiểm tra MySQL Connector trỏ tới localhost:3306, database dddm_telco_churn.
Bước 9. Execute toàn bộ workflow. Kết quả ghi vào bảng cleaned_customer_data.
Bước 10. Chạy sql/04_verify_after_and_kpi.sql để kiểm tra, ghi số liệu AFTER và xem KPI.

Bảng trong database

raw_customer_data: dữ liệu thô, toàn bộ cột kiểu text, 7,043 dòng.
raw_customer_data_week1_backup: bản sao lưu dữ liệu thô, chỉ có trên máy chính (7,043 dòng). Máy khác không cần bảng này.
dim_contract: bảng tham chiếu loại hợp đồng, khóa chính contract_type.
cleaned_customer_data: dữ liệu sạch, khóa chính customerID, khóa ngoại Contract.
data_quality_log: nhật ký chất lượng dữ liệu trước và sau làm sạch.

Quy tắc làm sạch Week 2

TotalCharges trống (11 khách có tenure bằng 0): điền 0, giữ dòng.
customerID trùng: loại bỏ, giữ dòng đầu tiên (kết quả thực tế ghi trong data_quality_log).
Nhãn No internet service và No phone service: gộp về No.
Outlier IQR: phát hiện và giữ lại.
Thêm hai cột: churn_flag (1 nếu Churn là Yes) và tenure_group (bốn nhóm).

Trạng thái

Week 1: định nghĩa bài toán, kiến trúc, WBS. Hoàn thành.
Week 2: MySQL, KNIME, chất lượng dữ liệu, ghi kết quả về MySQL. Xem lịch sử commit.
Week 3: Logistic Regression, ghi dự đoán về MySQL, bản nháp Power BI.
Week 4: dashboard hoàn chỉnh, ba khuyến nghị, báo cáo và demo.

Giấy phép và liêm chính học thuật

Nhóm trích dẫn nguồn dữ liệu và công cụ theo chính sách liêm chính học thuật của VNUK.
