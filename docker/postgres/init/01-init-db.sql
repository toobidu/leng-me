-- ============================================================
--  Init script — chỉ chạy LẦN ĐẦU khi container tạo (volume rỗng)
-- ============================================================
--  Thêm CREATE DATABASE cho từng project ở đây.
--  Sau khi container đã chạy, file này KHÔNG còn được đọc nữa
--  → muốn tạo DB mới phải dùng:
--      docker exec -it postgres-dev psql -U dev -c "CREATE DATABASE <ten>"
-- ============================================================

CREATE DATABASE "leng-me";
-- CREATE DATABASE another_project;
-- CREATE DATABASE one_more_app;
