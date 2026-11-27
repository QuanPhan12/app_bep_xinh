# Nguồn tham chiếu dinh dưỡng

USDA FoodData Central, SR Legacy April 2018. Dữ liệu tải từ:
https://fdc.nal.usda.gov/download-datasets/

Archive: https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip

SHA-256 archive: `b80817294b8850530aaedf2e515c02593b1824f763a0ff356e5c2081643e6fd0`.

`usda_sr_legacy.json` trích 7.793 bản ghi có đủ Energy (1008), Protein (1003),
Total lipid (1004), Carbohydrate by difference (1005). Giá trị trên 100 g phần ăn
được, đơn vị kcal/g. Không tự điền nutrient bị thiếu. Không tự tính energy từ 4/9.
Giữ description tiếng Anh và FDC ID để kiểm tra đúng sống/chín và loại thực phẩm.
64 tên Việt là nhãn cho nhóm thường dùng, không thay số dinh dưỡng nguồn.

Tạo lại bằng `python tool/import_nutrition_reference.py PATH_TO_DOWNLOADED_ZIP`.
Không đưa archive/raw CSV hoặc API key vào repository. Tên món và gram do AI gợi ý
chưa phải số đo; người dùng xác nhận trước khi tính và ghi nhật ký.
