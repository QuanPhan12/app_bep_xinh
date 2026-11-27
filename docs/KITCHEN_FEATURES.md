# Bàn giao 9 chức năng Bếp Xinh — 16/11/2026

Đã triển khai MVP mục 2–10 của FEATURE_ROADMAP_10.md. Cập nhật 27/11/2026:
thêm [bữa ăn nhiều món và giỏ đi chợ thật](MEAL_COOKING.md), thay thế phạm vi
giỏ mẫu của bản 16/11. Firestore rules/index của bản cũ
đã deploy ngày 16/11/2026; trạng thái xác minh xem [bàn giao production](FIRESTORE_DEPLOYMENT.md).
App web đã phát hành trong [đợt bổ sung quản lý bài](RECIPE_VISIBILITY.md).
Chưa duyệt đánh giá production hoặc phát hành APK/IPA trong đợt này.

## Luồng sử dụng

Bổ sung 27/11/2026: [Ước tính calo](NUTRITION.md) từ ảnh/mô tả/công thức/bữa,
xác nhận gram và lưu nhật ký ăn riêng. Dùng chung runtime model và hạn mức với
Chat AI. Rules + web đã phát hành và đọc lại khớp source.

Home có nút Góc bếp; Hồ sơ/Cài đặt có lối vào `/kitchen`. Không thêm tab chính.

| Chức năng | Điểm vào và hành vi |
|---|---|
| Thực đơn tuần | `/kitchen/meal-plan`: chọn ngày, lên bữa 1–6 món với khẩu phần chung; sửa trước khi bắt đầu, dùng lại thành bữa mới. Chi tiết bữa có nguyên liệu/giỏ thật/tiến độ nấu từng món. Sao chép ngày có ID ổn định khi retry. |
| Kho theo lô | `/kitchen/pantry`, nút trong Tủ lạnh: lượng/đơn vị/ngày tùy chọn; sửa/xóa, dùng bớt bằng transaction; lọc sắp hết hạn/quá ngày; tìm món theo nguyên liệu. Nhập lựa chọn cũ không giả định lượng. |
| Bộ sưu tập | `/kitchen/collections`: tạo/đổi tên/xóa, thêm/bỏ món trong chi tiết bộ sưu tập hoặc chi tiết món; riêng tư, không thay đổi mục yêu thích cũ. |
| Nhật ký | `/kitchen/journal`, nút sau Hoàn tất nấu: ngày/số người/ghi chú riêng; sửa/xóa/mở món; cùng cooking session ghi đè một document. Số Đã nấu ở hồ sơ lấy count server, lỗi thì hiện dấu gạch. |
| Hẹn giờ | `/kitchen/timers` hoặc từng bước: tối đa 8 timer, tạm dừng/tiếp tục/xóa; lưu deadline tuyệt đối và khôi phục sau khởi động. Hết giờ hiển thị trong app, chưa có chuông/notification khi app đóng. |
| Đọc offline | Chi tiết món → Tải offline, `/kitchen/offline`: lưu đủ nội dung/bước/ảnh Cloudinary, ảnh bundle dùng tài nguyên sẵn có. Xóa bản tải, kiểm tra công khai trực tuyến. Không chỉnh/sync công thức khi offline. |
| Theo dõi | Hồ sơ công khai tác giả → Theo dõi; Home → Đang theo dõi. Quản lý danh sách, bỏ theo dõi, feed bài đã duyệt phân trang. |
| Đánh giá | Chi tiết món công khai `r_*` → Đánh giá cộng đồng: 1–5 sao, nhận xét, sửa/xóa, báo cáo. Gửi/sửa về chờ duyệt; người khác chỉ đọc bản đã duyệt. Điểm fixture ghi rõ Điểm tham khảo, không trộn điểm cộng đồng. |
| Chia sẻ | Chi tiết món → share sheet hoặc Sao chép liên kết HTTPS. URL `/recipe/:id`; guest xem món công khai được. |

Các màn dùng khung responsive hiện có, dialog cho tablet/sheet cho điện thoại,
scroll khi mở bàn phím. Có trạng thái đang tải/rỗng/lỗi và giữ input khi lưu thất bại.

## Contract và phân quyền

`KitchenSessionHost` tạo service theo UID; widget → Cubit → repository/service.
Không thêm nguồn xuất bản thay thế `recipes/{id}`.

| Path | Dữ liệu |
|---|---|
| `users/{uid}/meal_plans/{id}` | schema 1: một recipe; schema 2: day, slot, name, dishes `[{recipe,role}]`, servings, preparedKeys. Đọc được dữ liệu cũ. |
| `users/{uid}/meal_sessions/{mealId}` | Ảnh chụp tham chiếu bữa, selectedRecipeId, steps, done, completed, pantryConsumed; lưu tiến độ trên server. |
| `users/{uid}/shopping_batches/{mealId}` | title, linesJson tối đa 100 KB; codec kiểm tra tối đa 180 dòng, checkbox lưu theo tài khoản. |
| `users/{uid}/pantry_lots/{id}` | ingredientId, name, amount/unitId cùng có hoặc cùng null, expiresOn tùy chọn |
| `users/{uid}/recipe_collections/{id}` | name, recipeIds map `{id:true}`, tối đa 100 món khác nhau |
| `users/{uid}/cooking_logs/{sessionId}` | recipe, day, servings, note riêng |
| `users/{uid}/following/{authorId}` | name; không tự theo dõi, tác giả phải là tài khoản active |
| `recipes/{id}/user_reviews/{uid}` | uid, name, stars, body, status pending/approved/hidden, updatedAt |
| `recipes/{id}/ratings/summary` | sum, count, lastReviewerId, updatedAt; trung bình = sum/count |
| `recipes/{id}/user_reviews/{reviewer}/reports/{uid}` | reason, updatedAt; chỉ staff đọc |
| `user_review_moderation_events/{id}` | recipeId, reviewerId, decision, operator IAM dạng hash, createdAt; chỉ công cụ IAM ghi |

Các collection cá nhân thêm schemaVersion và updatedAt server timestamp (meal_plans mới dùng schema 2; các loại còn lại dùng schema 1). Chỉ chủ active
đọc/ghi; staff không được đọc nhật ký qua rules. Client không ghi `users.cookedCount`.
Các nhãn recipe/author trong dữ liệu riêng là tham chiếu hiển thị, không phải bằng chứng
công thức còn công khai. Khi mở món đã gỡ, màn chi tiết trả không khả dụng.

Review client không tự duyệt, không đánh giá bài của mình; tên lấy từ hồ sơ hiện tại.
Mọi create/edit/delete/approve/hide đi cùng aggregate trong một commit. Rules kiểm tra
delta từ trạng thái trước/sau của chính review; sửa review approved rút điểm cũ ngay.
Không cho ghi naked aggregate, điểm sai, đọc pending của người khác hoặc tự báo cáo.

Collection cá nhân hiển thị tối đa 500 mục cập nhật gần nhất; count nhật ký là count
toàn collection. Feed theo dõi hỗ trợ tối đa 50 tác giả trong UI, chia nhóm 10, hợp nhất
theo submittedAt và document ID giảm dần, 20 món/trang. Giới hạn theo dõi là giới hạn
ứng dụng, không phải quota chống lạm dụng cưỡng chế ở server. Review 20/trang dùng
cursor Timestamp seconds/nanoseconds + ID, không làm tròn mili giây.

## Local và offline

`shared_preferences` chỉ giữ cache công thức công khai và timer; không lưu token,
nhật ký hay danh sách riêng vào storage này. Namespace có SHA-256 UID; khi đổi tài khoản
xóa cache/timer của phiên cũ. Mỗi ghi kiểm tra phiên trước/sau, timer không phụ thuộc số tick.
Cache JSON tối đa 2 MiB mỗi UID, mỗi ảnh remote tối đa 800 KB, timeout 20 giây,
ảnh Cloudinary tối ưu 720 px/JPEG. Đầy cache báo lỗi và giữ bản cũ; không tự xóa bản khác.
Đây là cache có thể mất khi hệ điều hành/trình duyệt dọn dữ liệu, không phải bản sao lưu.

Trước và sau tải kiểm tra công thức còn công khai; nút Kiểm tra trực tuyến xóa bản
đã gỡ nếu xác minh thành công, lỗi mạng giữ bản tải. Khi hoàn toàn offline không thể
biết bài vừa bị gỡ. Web cần tải được app shell trước; chưa triển khai PWA cold-start offline.
Font Be Vietnam Pro được bundle kèm OFL từ google/fonts, không tải font lúc chạy.

## Duyệt và xử lý báo cáo

Công cụ mới dùng phiên Firebase CLI/IAM hiện có, transaction và audit; mặc định dry-run.
Không dùng client API key để duyệt. Chạy từ project app:

```powershell
npm.cmd exec --package=firebase-tools@15.34.2 -- node tool/moderate_user_review.cjs --project bepxinh-b0be7 --recipe r_ID --list
npm.cmd exec --package=firebase-tools@15.34.2 -- node tool/moderate_user_review.cjs --project bepxinh-b0be7 --recipe r_ID --reviewer UID --decision approve
# Thêm --apply sau khi kiểm tra đúng review để ghi thật; hide để ẩn và rút điểm.
```

Staff mở mục **Duyệt đánh giá** trên admin, chọn công thức hoặc nhập ID để xem
đánh giá chờ duyệt/đã duyệt/đã ẩn và các báo cáo. Duyệt/ẩn cập nhật tổng điểm trong
cùng transaction, chặn xử lý nhầm nội dung vừa sửa. Portal chưa ghi audit đánh giá
(collection audit vẫn chỉ cho IAM ghi); công cụ CLI phía trên vẫn có audit riêng.
Không sửa aggregate thủ công trong Console.

## Kiểm thử và phát hành

```powershell
flutter analyze --no-pub
flutter test
node --test tool/user_review_moderation_test.cjs
flutter build web --release
```

Harness rules `tool/kitchen_emulator_smoke.cjs` yêu cầu demo-bepxinh, Firestore
127.0.0.1:8180 và Auth 127.0.0.1:9199. Không chạy với project thật. Với Java 21+:

```powershell
# Tạo config riêng trong build; copy rules/index cùng thư mục để Firebase CLI chấp nhận.
Copy-Item firestore.rules build/firestore.rules
Copy-Item firestore.indexes.json build/firestore.indexes.json
$kitchenConfig = @{firestore=@{rules='firestore.rules';indexes='firestore.indexes.json'};emulators=@{auth=@{host='127.0.0.1';port=9199};firestore=@{host='127.0.0.1';port=8180};ui=@{enabled=$false};singleProjectMode=$true}}
$kitchenConfig | ConvertTo-Json -Depth 8 | Set-Content build/kitchen_emulator.json
npm.cmd exec --package=firebase-tools@15.34.2 -- firebase emulators:exec --config build/kitchen_emulator.json --project demo-bepxinh --only auth,firestore "node tool/kitchen_emulator_smoke.cjs"
flutter build web --release --target tool/kitchen_sdk_smoke.dart --output build/kitchen-smoke-web
npm.cmd exec --package=firebase-tools@15.34.2 -- firebase emulators:exec --config build/kitchen_emulator.json --project demo-bepxinh --only auth,firestore "node tool/kitchen_sdk_browser_smoke.cjs"
```

SDK harness dùng Chrome headless/profile riêng; kiểm tra transaction repository, realtime
ack, count, đổi phiên, feed nhiều nhóm/trang và cursor review có phần nano giây.
Test Flutter mới có dữ liệu trên 390×844, 768×1024, 1024×768 với chữ 200%, dialog/bàn
phím, timer restart/pause/lỗi storage, cache đầy, tồn kho không âm và retry không trùng.

Phát hành cần triển khai rules và index `user_reviews(status, updatedAt DESC)` trước app,
đợi index sẵn sàng, rồi smoke trên môi trường phát hành. Không deploy config emulator.
Lệnh chuẩn bị phát hành (chỉ chạy khi quyết định đưa thay đổi lên môi trường thật):

```powershell
npm.cmd exec --package=firebase-tools@15.34.2 -- firebase deploy --only firestore --project bepxinh-b0be7
flutter build web --release --dart-define=PUBLIC_APP_URL=https://bepxinh-b0be7.web.app
npm.cmd exec --package=firebase-tools@15.34.2 -- firebase deploy --only hosting --project bepxinh-b0be7
```

App dùng site mặc định `bepxinh-b0be7`; admin có target/site riêng `bepxinh-admin`.
Kiểm tra lại đúng project/site và index trước các lệnh deploy. Lệnh deploy riêng
Firestore đã chạy ngày 16/11/2026; lệnh Hosting trong đoạn trên chưa chạy.

`firebase.json` có SPA rewrite cho deep URL. `PUBLIC_APP_URL` mặc định
`https://bepxinh-b0be7.web.app`, có thể đổi bằng dart-define sang domain HTTPS thực tế.
Android App Links đã được cấu hình cho host này và `/recipe/`; xem
[APP_LINKS.md](APP_LINKS.md) cho chứng chỉ, file xác minh, phát hành và kiểm tra
thiết bị. iOS Universal Links, OG preview và deferred links chưa cấu hình. Native share sheet,
Android/iOS release, và trải nghiệm trên thiết bị thật cần kiểm tra riêng; web release
build/SDK emulator không thay thế các kiểm tra nền tảng đó.

Kết quả ghi nhận trong workspace:

- Analyzer toàn dự án: sạch (`build/kitchen_analyze_final.log`).
- Flutter regression: 291 test đạt, 1 bài capture ảnh tùy chọn bị skip
  (`build/kitchen_full_final.log`); 3 test liên kết/router mới đạt riêng
  (`build/kitchen_navigation_test.log`).
- 73 assertions Rules emulator đạt (`build/kitchen_emulator.log`).
- 18 kiểm tra Flutter SDK thật trên Chrome/emulator đạt (`build/kitchen_sdk_emulator.log`).
- 3 test logic duyệt đánh giá Node đạt (`tool/user_review_moderation_test.cjs`).
- Web release đã build thành công (`build/kitchen_release_final.log`, artifact `build/web`).
- Android debug APK build thành công bằng Gradle (`build/kitchen_android_no_cache.log`,
  `build/app/outputs/flutter-apk/app-debug.apk`). Chưa cài/chạy trên thiết bị thật.

Lần `flutter build apk --debug` thông thường trên máy này lỗi Kotlin incremental cache
do Pub cache ở C: và project ở D:. Cờ môi trường không khắc phục được; lệnh Gradle
trực tiếp sau đã thành công, không sửa cấu hình Kotlin của project:

```powershell
Push-Location android
.\gradlew.bat --no-daemon '-Pkotlin.incremental=false' '-Pkotlin.compiler.execution.strategy=in-process' '-Ptarget-platform=android-arm,android-arm64,android-x64' assembleDebug
Pop-Location
```

Gradle vẫn có cảnh báo deprecation từ các plugin hiện có. APK debug không phải bản
release để phát hành; chưa kiểm thử native share sheet, notification nền hoặc iOS.

Log/build là artifact cục bộ bị Git bỏ qua, không chứa tài khoản production để kiểm thử.
