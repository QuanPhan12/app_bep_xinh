# Danh mục nguyên liệu Bếp Xinh

Nguồn bootstrap: [`data/catalogs/ingredients.v1.json`](../data/catalogs/ingredients.v1.json).
Portal `../admin_bep_xinh` có thể thêm/sửa và phát hành phiên bản mới trực tiếp vào
`catalogs/ingredients` bằng tài khoản admin active. JSON trong repo không tự cập nhật
ngược; cần đối chiếu version/hash trước khi chạy lại publisher để tránh ghi đè dữ liệu mới.
Đã xuất bản lên project `bepxinh-b0be7`, document **`catalogs/ingredients`**.
Phiên bản dữ liệu: `2026-11-09.v1`, schema `1`, locale `vi-VN`.

## Phân loại

| Mã nhóm | Nhóm | Số nguyên liệu |
| --- | --- | ---: |
| meat | Thịt đỏ | 13 |
| poultry | Gia cầm | 10 |
| seafood | Cá và hải sản | 22 |
| eggs_dairy | Trứng, sữa và chế phẩm | 11 |
| legumes | Đậu và các loại hạt | 12 |
| leafy_vegetables | Rau ăn lá | 16 |
| roots | Củ và rễ | 14 |
| fruit_vegetables | Rau ăn quả, hoa và thân | 22 |
| mushrooms | Nấm | 8 |
| herbs | Rau thơm và gia vị tươi | 16 |
| fruits | Trái cây | 15 |
| grains_noodles | Gạo, bột và mì bún | 20 |
| seasonings | Gia vị khô | 18 |
| oils_sauces | Dầu, nước chấm và xốt | 19 |
| processed | Thực phẩm chế biến và đồ khô | 15 |
| **Tổng** | | **231** |

Đây là danh mục khởi đầu cho nấu ăn gia đình Việt Nam, có thể bổ sung qua quy trình xuất bản.
Không gắn thời hạn bảo quản, dị ứng hoặc dinh dưỡng suy đoán vào dữ liệu này.

## Contract JSON

```json
{
  "schemaVersion": 1,
  "version": "2026-11-09.v1",
  "locale": "vi-VN",
  "categories": [{"id": "legumes", "name": "Đậu và các loại hạt", "sortOrder": 50}],
  "units": [{"id": "block", "label": "bìa", "type": "count"}],
  "ingredients": [{
    "id": "tofu",
    "name": "Đậu hũ",
    "categoryId": "legumes",
    "aliases": ["đậu phụ", "tàu hũ"],
    "unitIds": ["block", "piece", "g", "kg"],
    "defaultUnitId": "block"
  }]
}
```

Ví dụ minh họa cấu trúc, không phải file seed đầy đủ. Mỗi `unitId` phải có trong danh sách `units`.
Tên dùng Unicode NFC, có dấu, không có khoảng trắng thừa. ID ổn định dạng `snake_case` không dấu;
đổi tên hiển thị không đổi ID. `categoryId` tham chiếu một nhóm; UI lấy tên nhóm từ `categories`.
`sortOrder` xác định thứ tự nhóm, nguyên liệu xếp theo tên tiếng Việt trong mỗi nhóm.
`defaultUnitId` phải thuộc `unitIds`, là đơn vị chọn mặc định khi thêm nguyên liệu vào công thức.

18 đơn vị chia thành `mass`, `volume`, `count`, `kitchen`. Chưa tự quy đổi thìa/chén sang gram hoặc ml,
vì lượng thực tế phụ thuộc nguyên liệu và dụng cụ. “Bơ lạt” và “quả bơ”, “nước cốt dừa” và “nước dừa”
là các nguyên liệu riêng, không gộp thành alias của nhau.

Giữ 19 ID nguyên liệu cũ để công thức/tủ lạnh tiếp tục tham chiếu đúng. Đã sửa khoai tây dùng đơn vị
`bulb` (củ) thay cho `fruit` (quả), đồng thời cập nhật công thức và fixture tương ứng.

## Luồng trong ứng dụng

`AppBepXinh` inject `FirestoreIngredientCatalogService` qua `IngredientCatalogService`.
Tủ lạnh, chọn nguyên liệu khi đăng món, chi tiết món và tìm kiếm công thức cùng dùng service này.
Nguồn runtime là Firestore; JSON trong `assets/mock/ingredients.json` chỉ phục vụ test/mock.
File seed quản trị không được đóng gói làm dữ liệu dự phòng cho app.

Một document chứa toàn bộ snapshot để nhóm/đơn vị/nguyên liệu không lệch phiên bản.
Payload JSON hiện khoảng 32 KB; script chặn trên 750 KB để chừa khoảng cho encoding/metadata.
Các mảng không dùng truy vấn Firestore được miễn index. Khi danh mục vượt giới hạn này, cần nâng schema
và cách tải; không tiếp tục nhồi thêm dữ liệu vào cùng document.

Service gộp các request đồng thời, giữ cache 15 phút trong instance, tìm kiếm tại máy theo tên/alias
không phân biệt dấu, hoa/thường. Lần tải sau khi hết cache đọc lại Firestore; SDK có thể dùng cache
của nó khi offline. Dữ liệu thiếu/sai schema hoặc lỗi tải sẽ đi vào trạng thái lỗi/thử lại hiện có,
không tự thay bằng danh mục mock. Chưa triển khai cập nhật realtime khi đang mở một picker.

## Xuất bản

```powershell
# Kiểm tra schema, ID, đơn vị, danh tính cũ, kích thước và hash:
node tool/ingredient_catalog_data.cjs
# Đọc công khai từ project thật và đối chiếu toàn bộ dữ liệu với file nguồn:
node tool/verify_ingredient_catalog.cjs
# Dry run, không kết nối Firebase:
node tool/publish_ingredient_catalog.cjs
# Đã đăng nhập Firebase CLI; ghi bằng quyền IAM của tài khoản quản trị:
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/publish_ingredient_catalog.cjs --project bepxinh-b0be7 --apply
# Triển khai rules/indexes:
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase deploy --only firestore --project bepxinh-b0be7 --non-interactive
```

Publisher ghi atomic một document, dùng precondition theo `updateTime`/document chưa tồn tại để tránh
ghi đè thay đổi đồng thời. Trùng hash thì bỏ qua ghi. Cùng version nhưng nội dung khác sẽ bị từ chối;
muốn cập nhật phải tăng `version`. Đọc lại hash sau ghi để xác minh. Không xóa dữ liệu người dùng.
Metadata Firestore có thêm `contentHash`, `updatedAt` bằng server timestamp.

Rules cho phép mọi client đọc đúng `catalogs/ingredients`, không cho liệt kê collection hoặc ghi/xóa.
Các document khác trong `catalogs` vẫn bị chặn. Không đưa credentials quản trị vào Flutter.

## Kiểm tra

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Các test kiểm tra quan hệ nhóm/đơn vị, schema sai, cache/TTL, lỗi và thử lại, tìm kiếm alias,
chia sẻ identity với tủ lạnh. `tool/firebase_emulator_smoke.cjs` nạp seed bằng quyền emulator,
kiểm tra đọc công khai và chặn ghi từ client; `tool/firebase_sdk_smoke.dart` tải danh mục bằng SDK thật.
Xem cách chạy emulator/Chrome trong [FIREBASE.md](FIREBASE.md).

Thiết kế dựa trên [Firestore limits](https://firebase.google.com/docs/firestore/quotas)
và [index exemptions](https://firebase.google.com/docs/firestore/best-practices).

## Xác minh 09/11/2026

- Document production đọc công khai thành công; toàn bộ nội dung khớp file nguồn.
- Publisher chạy lại cùng hash không ghi thêm dữ liệu.
- Rules/index exemptions đã triển khai. Emulator đạt 30 kiểm tra, gồm đọc danh mục
  khi chưa đăng nhập và từ chối client sửa danh mục.
- SDK thật trên Chrome tải được 231 nguyên liệu và giải tên nhóm từ `categoryId`.
- Analyzer sạch; bộ hồi quy Flutter đạt 195 test.
