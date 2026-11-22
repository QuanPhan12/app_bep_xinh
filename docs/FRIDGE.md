# Tủ lạnh remote

Production inject `RemoteFridgeService`; `MockFridgeService` và `assets/mock/fridge.json`
chỉ phục vụ fixture/test. Giao diện và `FridgeCubit` giữ nguyên contract `FridgeService`.

## Nguồn dữ liệu

- Danh mục: `catalogs/ingredients` qua `IngredientCatalogService`.
- Kho riêng: `users/{uid}/fridge/current` qua `FirestoreFridgeInventoryRepository`.
- Công thức: `PublishedRecipeSource.fetchPublished()`, chỉ query `recipes` có
  `status == approved`, cùng nguồn Firestore với Home. Tủ lạnh không gộp công thức mẫu local.

```text
users/{uid}/fridge/current
  schemaVersion: 1
  ingredientIds: { egg: true, tomato: true, ... }
  updatedAt: server timestamp
```

Document chưa tồn tại nghĩa là tủ trống, không tự gán nguyên liệu mẫu. Xóa hết ghi
map rỗng, nên mở lại vẫn trống. ID nguyên liệu đã bị gỡ khỏi catalog được bỏ qua
khi đọc. Kho không chứa bản sao công thức hay URL ảnh; món và ảnh lấy từ bài đã duyệt.
Nguyên liệu tự nhập trong công thức chưa có ID danh mục luôn được tính là thiếu,
hiển thị đúng tên; không âm thầm bỏ khỏi phép đối chiếu. Thời gian món là chuẩn bị + nấu;
bộ lọc chay dựa trên danh mục tác giả chọn, không tự khẳng định thành phần là món chay.

## Phiên và quyền truy cập

Repository gắn với UID, kiểm tra phiên trước/sau thao tác. Đổi UID tạo lại service,
không đưa kho tài khoản cũ vào tài khoản mới. Home khi chưa đăng nhập có kho trống;
không đọc kho riêng. Tủ lạnh yêu cầu đăng nhập qua router hiện hành.

Rules chỉ cho chủ tài khoản active đọc document của họ và ghi đúng `current`;
ghi yêu cầu hồ sơ đã tồn tại, schema đúng, tối đa 500 khóa nguyên liệu với giá trị
`true`, metadata chỉ có các trường trên và thời gian server. Không cho list hoặc delete.
Client đối chiếu ID với catalog trước khi ghi; rules giới hạn cấu trúc/map, không
duyệt từng ID với danh sách object của catalog. ID không còn hợp lệ không được dùng tính gợi ý.
Map nguyên liệu được miễn index vì không query từng field.

Lưu được tuần tự hóa; chỉ phát summary cho Home khi server xác nhận. Cubit dùng
optimistic UI và khôi phục dữ liệu đã xác nhận khi ghi lỗi. Đọc kho dùng server
để refresh không báo nhầm dữ liệu cache là kết quả mới nhất.

## Giới hạn

Dữ liệu được tải lại khi mở màn/refresh, chưa có listener realtime giữa thiết bị.
Nếu hai thiết bị cùng sửa kho, bản ghi được server nhận sau cùng thay thế danh sách
trước đó. Chưa lưu số lượng, ngày hết hạn hoặc lịch sử thay đổi; không suy đoán các
thông tin này từ lựa chọn nguyên liệu.

Gợi ý hiện dùng tối đa 100 công thức đã duyệt gần nhất, chưa phân trang hoặc tìm
kiếm gợi ý phía server. Nếu chưa có bài đã duyệt phù hợp, màn sẽ hiển thị trạng thái
rỗng. Công thức/bài pending và bài bị từ chối không được đưa vào nguồn gợi ý.

## Kiểm thử và triển khai

```powershell
flutter analyze --no-pub
flutter test --no-pub
# Emulator cần Java 21+, không tạo dữ liệu thử trên project thật.
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase emulators:start --only auth,firestore --project demo-bepxinh
# Terminal khác:
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
node tool/firebase_emulator_smoke.cjs
node tool/recipe_publishing_emulator_smoke.cjs
flutter build web --debug --no-wasm-dry-run --target tool/recipe_publishing_sdk_smoke.dart --output build/recipe-publishing-smoke-web
node tool/firebase_sdk_browser_smoke.cjs --publishing
# Sau khi kiểm thử, triển khai quyền và miễn index:
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase deploy --only firestore --project bepxinh-b0be7 --non-interactive
```

Service tests kiểm tra kho mới rỗng, đọc công thức remote/ảnh URL, nguyên liệu tự nhập,
lưu/khôi phục/xóa hết, ghi lỗi và ID lạ. Rules smoke kiểm tra truy cập chéo tài khoản,
khách, tài khoản khóa và payload sai. SDK Chrome smoke ghi kho, tạo service mới
đọc lại từ server, xóa hết và đọc lại; đối chiếu món đã duyệt với ảnh Cloudinary.

Xác minh 09/11/2026: analyzer sạch, 217 test Flutter đạt, 57 kiểm tra Auth/Firestore
và 23 kiểm tra duyệt bài đạt. SDK Chrome smoke đạt lưu/khôi phục/xóa kho và đọc gợi ý
đã duyệt. Rules và miễn index đã deploy lên `bepxinh-b0be7`; không tạo user hoặc
tồn kho thử trên production, không upload thêm ảnh Cloudinary trong lượt kiểm thử này.
