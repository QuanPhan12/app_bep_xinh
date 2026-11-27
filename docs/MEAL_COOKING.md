# Nấu một bữa — 27/11/2026

## Hiển thị lượng nguyên liệu không có thập phân — 27/11/2026

Lượng sau chia khẩu phần được làm tròn số nguyên khi trình bày ở nguyên liệu bữa,
phần cần mua, giỏ đi chợ, tổng hợp tuần và xác nhận trừ kho, thống nhất với chi tiết
công thức. Ví dụ 3,333 cái → 3 cái; 66,666 g → 67 g; 333,333 g → 333 g.
Lượng dương nhỏ hơn ngưỡng làm tròn hiển thị `<1`, không biến thành 0; Vừa đủ giữ nguyên.
Phép tính khẩu phần và giao dịch tồn kho vẫn dùng lượng chính xác. Chuỗi số lẻ trong
giỏ đã lưu được định dạng lại khi hiển thị, không migration hoặc xóa checkbox.
Thêm lại cùng lượng hiển thị không bỏ đánh dấu đã mua do khác định dạng cũ/mới.
Giỏ cũ và preview trừ kho đổi kg/l sang g/ml trước khi làm tròn, ví dụ 0,2 kg → 200 g.
Kiểm thử tái hiện đúng các số trong ảnh phản hồi và kiểm tra lượng tính nội bộ không
bị làm tròn. Analyzer phạm vi sửa không có issue; bộ bữa ăn + bếp cũ đã qua 29 test.
Sau bổ sung quy đổi preview/giỏ cũ, 13 test bữa ăn cuối đều qua. Web phát hành lúc
15:58 ngày 27/11/2026 (UTC+7), version `1037bd85ca53d9c0`; đã so hash app live
và Android association với build, khớp. Log: `build/meal-quantities-deploy.log`,
báo cáo: `build/meal-quantities-release.json`. Bản localhost cần hot reload/restart
để nhận code mới. Đợt này chỉ cập nhật Hosting app.

## Luồng và giao diện

Vào Bếp của tôi → Thực đơn tuần → chọn ngày/bữa → Lên bữa. Màn đầy đủ
cho phép đặt tên, ngày, sáng/trưa/tối, 1–50 người và 1–6 món khác nhau.
Vai trò món chính/canh/rau/cơm hoặc món kèm/món khác là nhãn tùy chọn.
Có thể bỏ, thêm lại món khác và đổi thứ tự bằng Đưa lên. Gợi ý lấy từ nguyên liệu
đã chọn trong Tủ lạnh, xếp ít nguyên liệu thiếu trước; không suy ra đủ số lượng.
Chi tiết công thức → Thêm vào thực đơn cho phép tạo bữa mới hoặc thêm vào bữa
chưa bắt đầu. Khi thêm vào bữa đã có, giữ khẩu phần/ngày của bữa đó.

Chi tiết bữa có ba tab dùng chung `AppTabs`: Bữa ăn / Nguyên liệu / Nấu bữa.
Không đóng khung từng hạng mục; icon đơn sắc. Nội dung cuộn riêng và hành động
chính nằm dưới cùng, còn thấy khi điện thoại xoay ngang hoặc phóng chữ.
Trước khi nấu có thể sửa/xóa. Sau khi bắt đầu, món/khẩu phần/ngày/tên được khóa;
Dùng lại bữa này tạo ID mới và chọn ngày mới, không sao chép tiến độ/checkbox.
Sao chép ngày không ghi đè bữa đích đã tồn tại khi thử lại.

## Nguyên liệu và đi chợ

`MealIngredients` nhân lượng mỗi công thức theo `meal.servings / recipe.servings`.
Chỉ gộp theo ingredientId canonical và đơn vị tương thích. Quy đổi g↔kg, ml↔l;
không đổi muỗng/miếng/quả thành khối lượng. Nguyên liệu tự nhập tách theo món + ID,
lượng vừa đủ/chưa xác định giữ riêng, không bịa số lượng.

Trừ lượng có trong `pantry_lots` cùng ingredientId/đơn vị, bỏ lô hết hạn và lô
chưa có số lượng; ưu tiên hạn gần hơn. Tủ lạnh chỉ cung cấp dấu hiệu hiện diện.
Checkbox “đã có đủ” do người dùng xác nhận sẽ loại dòng đó khỏi danh sách cần mua.
Checkbox không tự trừ kho sau khi nấu.

Cập nhật giỏ tải lại kho trước khi tính thiếu. Mỗi bữa có một `shopping_batches`
với ID bằng mealId, vì vậy thêm lại không nhân đôi. Giao dịch giữ checkbox của dòng
không đổi lượng; đổi lượng thì bỏ check. `/cart` đọc/ghi dữ liệu riêng theo tài khoản,
không có dữ liệu mẫu runtime. Giỏ phân nhóm theo bữa, không gộp chéo bữa để giữ
nguồn nhu cầu rõ ràng. Dữ liệu mẫu chỉ được truyền trong test.

## Phiên nấu, lịch sử và kho

`meal_sessions/{mealId}` schema 1 lưu `plan` (tham chiếu món + metadata,
không chứa nội dung công thức), selectedRecipeId, map steps 0–19, done,
completed và pantryConsumed. Tạo phiên bằng transaction create-if-absent:
mở lại/bấm lại không đặt lại tiến độ. Chuyển món và đổi bước dùng transaction;
snapshot từ server cập nhật màn hình. Không hỗ trợ bắt đầu/ghi tiến độ khi offline.
Nếu món bị ẩn hoặc mất kết nối, tải thất bại và có nút Thử lại/Sửa bữa hoặc Dùng lại; không dùng fallback
công thức giả để tiếp tục. Nội dung công thức được tải lại khi mở bữa, không cố định
phiên bản nội dung; nếu tác giả sửa thì bước hiện tại được giới hạn theo số bước mới.

Thứ tự gợi ý chỉ dựa trên tổng thời gian chuẩn bị+nấu của từng món giảm dần.
Không quảng cáo tổng thời gian bữa hay lịch nấu song song tối ưu vì chưa có metadata
chờ/dụng cụ. Timer dùng SHA-256(mealId/recipeId/stepId), groupId=mealId, có nhãn món
và bước; bấm lại không khởi động lại cùng timer. Lưu deadline theo UID, giữ nhóm khi
tạm dừng/tiếp tục; có thể dừng từng timer. Tối đa 8 timer toàn app. Hết giờ chỉ hiện
trong app, chưa có chuông hệ thống/notification khi đóng app.

Đánh dấu Xong món ở bước cuối; có thể mở lại món trước khi hoàn tất bữa. Khi tất cả
món xong, Hoàn tất bữa xác nhận dừng timer của đúng bữa. Một transaction ghi trạng thái
completed và một CookingLog/món, ID SHA-256(mealId/recipeId). Retry hoặc hai thiết bị
hoàn tất đồng thời không nhân đôi nhật ký. Không tự tăng trường users.cookedCount.
Timer local dừng sau commit server; nếu ghi local lỗi vẫn có nút dừng từng timer.

Sau hoàn tất, người dùng chọn Xem lượng đã dùng và trừ kho. Dialog tải kho mới và
liệt kê từng lô/lượng. Chỉ sau xác nhận mới chạy một transaction đọc phiên+tất cả lô,
kiểm tra lượng/đơn vị/ingredientId/hạn còn khớp preview rồi ghi các lô cùng cờ
pantryConsumed. Nếu một lô đổi, toàn giao dịch bị hủy và cần mở preview lại.
Lặp lệnh/đồng thời chỉ trừ một lần. Không suy ra lượng cho nguyên liệu vừa đủ hoặc
đơn vị khác; người dùng cập nhật những phần đó trong kho. Màn preview phản ánh
lượng theo công thức, người dùng chỉ xác nhận khi đúng lượng đã dùng thực tế.

## Contract và rules

`meal_plans` schema 1 cũ giữ nguyên khả năng đọc. Schema 2:
`{day,slot,name,servings,dishes:[{recipe:{id,title,authorId},role}],preparedKeys}`.
Document server có thêm schemaVersion và updatedAt=request.time. Dữ liệu cũ được
đọc thành bữa một món, ghi lại dạng mới khi cần. Không chạy migration database.

Rules kiểm schema/giới hạn, role hợp lệ, recipeId không trùng, phiên đầu khớp bữa
hiện tại, steps/done chỉ chứa món của bữa. Sau khi có phiên, bữa chỉ sửa preparedKeys
hoặc nâng schema cũ mà giữ nguyên nội dung. Không xóa bữa/phiên đã bắt đầu. Cờ completed
và pantryConsumed không được quay lại false. Bữa/phiên/giỏ chỉ chủ tài khoản active
được đọc/ghi; staff không được đọc thay người dùng. Không cần index mới.

Giỏ dùng `linesJson` string giới hạn 100 KB trong rules; ứng dụng parse và kiểm tra
tối đa 180 dòng có key/name/quantity/checked, key duy nhất. Rules không phân tích
ngữ nghĩa JSON bên trong. Đây là payload riêng, không dùng để ghi dữ liệu công khai
hoặc tài khoản khác. Các số lượng trong kho và lịch sử vốn do chủ tài khoản quản lý;
idempotency của hoàn tất/trừ kho do transaction repository, không phải dịch vụ đặc quyền.
Không triển khai Cloud Functions, không nâng Spark lên Blaze.

## Xác minh và phát hành

- `flutter analyze --no-pub` (ghi riêng các cảnh báo tồn tại trước).
- `flutter test --no-pub`; test mới `test/features/meal_planner_test.dart` kiểm
  tương thích cũ, đơn vị, kho hết hạn, checkbox, khôi phục tiến độ, timer và layout.
- Build SDK demo: `flutter build web --release --no-pub --no-wasm-dry-run --target tool/firebase_sdk_smoke.dart --output build/firebase-smoke-web`.
- JRE 21+, chạy `firebase emulators:exec --only auth,firestore --project demo-bepxinh "node tool/meal_emulator_smoke.cjs"`.
  Runner kiểm rules cũ/counters/bữa, rồi Chrome headless riêng với SDK demo. SDK kiểm
  hoàn tất đồng thời, trừ kho một lần, rollback khi preview cũ, giỏ và nâng schema.
  Không dùng profile Chrome đã đăng nhập hoặc tài khoản production.
- Phát hành rules trước app mới; app cũ vẫn ghi bữa schema 1 khi chưa bắt đầu phiên.
  Không rollback rules về bản không biết schema 2 sau khi đã có bữa mới.
- Build app web với target `lib/main.dart`, giữ `.well-known/assetlinks.json`, chỉ deploy
  Firestore rules và Hosting của `bepxinh-b0be7`; không deploy admin/functions.

Kết quả local:

- Toàn suite: 422 passed, 4 skipped (`build/meal-flutter-tests.log`), trước các chỉnh
  cuối về trạng thái phục hồi và trình bày. Các kiểm thử tập trung đã qua: 12 test bữa ăn và 16 test
  bếp cũ; test bữa ăn bao gồm sáng/tối, 390×844, 844×390, 1024×768,
  chữ 200% và inset bàn phím. Không gọi đây là một lần chạy toàn suite cuối mới.
- Analyzer không có error và không thêm vấn đề mới; còn 4 vấn đề có sẵn ở AI chat,
  login và messages. Đã dọn import không dùng trong widget Bếp hôm nay được sửa.
- Emulator: 57 kiểm tra auth/Firestore + 28 counters + 31 schema/quyền/vòng đời bữa;
  SDK Flutter web thực xác minh tiến độ, hoàn tất đồng thời, trừ kho một lần,
  rollback preview cũ, giỏ và nâng dữ liệu cũ. Nhật ký: `build/meal-emulator.log`.
- Đã kiểm tra ảnh editor/chi tiết ở `build/ui_ux/meal-editor` và
  `build/ui_ux/meal-detail` trên ba kích thước. Build release web thành công.
- Chưa build/phát hành APK/IPA hoặc kiểm thử timer khi hệ điều hành đóng app.

Phát hành production đã hoàn tất ngày 27/11/2026 lúc 15:29 (UTC+7):

- Web: https://bepxinh-b0be7.web.app, Hosting version `6f209ce2c9fc528f`.
- Firestore ruleset: `bcb98d1d-9b15-420a-bf1e-0ef182dd56ad`, server update
  `2026-11-27T08:29:34.223261Z`.
- SHA-256 rules chuẩn hóa LF:
  `31c7f77fa40c716ef41922652ed7d3ef1dd405c49ca5404503ef8890132406a1`.
- Đã đọc lại Rules API, so khớp nội dung với source. Đã tải public index.html,
  main.dart.js và `.well-known/assetlinks.json`, hash khớp build local. Đường dẫn
  `/kitchen/meal-plan` trả app shell đúng; association Android giữ HTTP 200/JSON.
- Báo cáo cục bộ `build/meal-release.json`, log deploy `build/meal-deploy.log`.
  Có thể đọc kiểm lại bằng `npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/verify_meal_release.cjs`.
- Chỉ deploy Firestore rules và Hosting app; không deploy admin, functions, index
  hoặc chạy migration dữ liệu. Luồng ghi thực được kiểm trên emulator; không tạo
  tài khoản, bữa thử hay trừ kho thử của người dùng production.
