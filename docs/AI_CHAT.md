# Bếp Xinh AI — ghi chú proxy cũ

**Cập nhật 27/11/2026:** Chat và [Ước tính calo](NUTRITION.md) dùng chung
`AiModelClient`, cấu hình runtime/model/key và hạn mức. Lịch sử hai tính năng riêng,
dinh dưỡng tính từ bảng USDA sau xác nhận; không lấy số nutrient model tự bịa.

**Cập nhật 18/11/2026:** app/admin đã chuyển sang đọc cấu hình Firestore và gọi API
trực tiếp theo yêu cầu thử nghiệm. Xem [AI_DIRECT.md](../../admin_bep_xinh/docs/AI_DIRECT.md).
Các phần bên dưới là lịch sử proxy cũ, không phải điều kiện chạy hiện tại.

Theo lựa chọn của người dùng: hoàn thiện local trước, **không deploy Functions,
không bật billing, không thay Hosting/rules production** trong đợt này.
Project production kiểm tra ngày 17/11/2026 có `billingEnabled=false`.

**Cập nhật theo yêu cầu dùng dữ liệu thật:** lệnh `npm.cmd run dev:ai` trong repo
admin hiện dùng Auth/Firestore thật của `bepxinh-b0be7`, chỉ chạy máy chủ AI local;
không tạo demo, không deploy. Xem [hướng dẫn dữ liệu thật](../../admin_bep_xinh/docs/AI_CHAT.md)
để đăng nhập tài khoản hiện có, nhập API và chạy app `main.dart` cùng endpoint local.
Các lệnh `demo-bepxinh` và `main_local.dart` bên dưới chỉ dành cho kiểm thử cô lập.

## Chức năng

- Nhắn tin → thẻ Bếp Xinh AI → hội thoại riêng. Avatar đầu bếp robot màu cam.
- Hỏi cách dùng app, món ăn và nguyên liệu. Thông tin chức năng app nằm trong
  systemGuide phía server; không đưa API key hoặc dữ liệu chat người khác vào prompt.
- Gợi ý món từ tối đa 100 công thức đã duyệt gần nhất; xếp hạng tên/nguyên liệu,
  chọn 12 ứng viên. Model chỉ được chọn ID trong tập này. Server loại ID lạ/trùng
  và đọc lại trạng thái món trước khi trả tối đa 4 thẻ. Bấm thẻ mở chi tiết.
- Nếu không có món phù hợp trong dữ liệu, AI được hướng dẫn nói rõ và phân biệt
  ý tưởng nấu ăn chung với công thức trong app. Không tự thực hiện thao tác lưu/
  đăng món/đặt thực đơn. Không cam kết model luôn trả lời đúng; kiểm chứng nguyên liệu
  và hướng dẫn nấu ăn khi dùng. Không dùng AI để chẩn đoán y khoa.
- Lịch sử riêng theo UID, tải 40 tin gần nhất; gửi 8 tin gần nhất làm ngữ cảnh.
  Tin nhắn và câu trả lời được gửi tới provider do admin cấu hình. Không tự đọc tủ
  lạnh, chat người khác hoặc hồ sơ riêng để gửi sang provider.
- Admin → Cài đặt → Bếp Xinh AI: bật/tắt, kiểu API, endpoint, model, thay key,
  hạn mức mỗi người. Moderator không có form và server từ chối endpoint cấu hình.

## Chạy local (Windows, 3 terminal)

Yêu cầu Node.js 22, Flutter SDK của dự án, Java 21+, Firebase CLI 15.34.2.
Các cổng 9099/8080/5001 dành cho emulator; 5174 admin; 7591 app.

Terminal 1, tại `D:\quan\app_bep_xinh`:

```powershell
npm.cmd --prefix functions ci
node functions/tool/init-local.mjs
# JAVA_HOME cần trỏ JRE/JDK 21+ (không dùng Java 8/17).
# Máy hiện tại có bản tạm tại build/report_temp/java21/jdk-21.0.13+9-jre.
$env:JAVA_HOME=(Resolve-Path 'build/report_temp/java21/jdk-21.0.13+9-jre').Path
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
npm.cmd exec --package=firebase-tools@15.34.2 -- firebase emulators:start --only auth,firestore,functions --project demo-bepxinh --config firebase.ai.local.json
```

Terminal 2, tại `D:\quan\app_bep_xinh`, seed sau khi emulator sẵn sàng:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
node functions/tool/seed-local.mjs
flutter run -d chrome -t lib/main_local.dart --web-port=7591 --dart-define=AI_API_BASE_URL=http://127.0.0.1:5001/demo-bepxinh/asia-southeast1/bepXinhAi
```

`main_local.dart` chỉ cho phép web debug, project demo và API loopback. Giữ đầy đủ
Firebase Authentication + AccountGuard; không bỏ qua đăng nhập/quyền tài khoản.
Không dùng entry này để build release. `main.dart` production giữ cấu hình riêng.

Terminal 3, tại `D:\quan\admin_bep_xinh`:

```powershell
$env:VITE_USE_EMULATORS='true'
$env:VITE_AI_API_URL='http://127.0.0.1:5001/demo-bepxinh/asia-southeast1/bepXinhAi'
npm.cmd run dev -- --host 127.0.0.1 --port 5174 --strictPort
```

Mở admin tại http://127.0.0.1:5174. Tài khoản **chỉ có trong demo emulator**:

| Mục đích | Email | Mật khẩu demo |
| --- | --- | --- |
| Admin | local-admin@example.test | BepXinhLocal123! |
| App | local-cook@example.test | BepXinhLocal123! |

Seed chỉ tạo hai tài khoản và catalog nguyên liệu, không sao chép dữ liệu production,
không tạo phản hồi AI giả trong luồng sử dụng thật. Muốn có thẻ món gợi ý: đăng
công thức trong app local, duyệt bằng admin local. Các công thức mẫu bundled không
được coi là công thức Firestore đã duyệt để AI tự gắn ID.

Admin nhập API key trực tiếp vào form, chọn model còn hoạt động trên tài khoản
provider, bật AI rồi Kiểm tra và lưu. Không đặt key trong Flutter, Vite env hoặc Git.
Tự nhập key mới trong admin; key từ ảnh chat **không được chép vào source/file test**.
Khi AI chưa bật hoặc chưa có key, server trả trạng thái chưa kích hoạt, không giả lập
câu trả lời. Tắt các terminal để dừng local. Dữ liệu emulator không tự lưu sau tắt;
nếu muốn giữ, dùng export/import emulator và bảo vệ bản export vì có nội dung chat.

## API tương thích

| Kiểu | Giao thức |
| --- | --- |
| Gemini | POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent, x-goog-api-key, JSON output |
| OpenAI compatible | Base URL HTTPS + /chat/completions, Authorization Bearer, messages, response_format=json_object |

Không có nghĩa mọi API bất kỳ đều tương thích. Model cần hỗ trợ JSON object với
`{"reply":"...","recipeIds":["..."]}`. Server parse, giới hạn độ dài, lọc ID, kiểm
tra nguồn. Đổi provider/endpoint phải nhập key mới, không chuyển key cũ sang host mới.
Model mặc định Gemini là `gemini-2.5-flash`, có thể đổi khi provider ngừng/hạn chế model.
Adapter dùng `max_completion_tokens` với host api.openai.com; các endpoint tương
thích khác dùng `max_tokens`. Không ép temperature trên Chat Completions để tránh
lỗi với model reasoning. Provider cần hỗ trợ tham số tương ứng và JSON object.
Chưa gọi provider thật trong các bài kiểm tra; phải nhập key và kiểm tra trên local
để xác nhận quyền/model/quota của tài khoản API.

## Giới hạn và bảo mật

- Firebase ID token được verify gồm kiểm tra thu hồi, rồi kiểm tra `users/{uid}`
  đang active; config chỉ admin. CORS chỉ domain app/admin và loopback khi emulator.
- Key mã hóa AES-256-GCM trong `_ai_private/config`; master 32 byte ở Secret Manager
  khi deploy, `.secret.local` bị Git ignore khi local. Không đọc lại key trong admin.
  Không xoay master khi còn ciphertext cũ nếu chưa chuẩn bị nhập lại/re-encrypt key.
- Firestore client kể cả admin không được đọc/ghi `_ai_private`, `_ai_limits`,
  `_ai_admin_limits`, `_ai_requests`, `_ai_threads`. Proxy xác minh quyền từng lần.
- Endpoint HTTPS công khai cổng 443; chặn private/loopback/metadata/mapped IPv6,
  ghim DNS vào kết nối, không đi theo redirect. Không trả lỗi raw của provider.
- 5 lượt/phút/UID, mặc định 40/ngày/UID (admin đổi 1–100); tối đa 500/ngày và
  30/phút chung project. Lần gọi lỗi vẫn tính hạn mức. Config test tối đa 5/phút/admin.
  Đây là giới hạn số request, không phải trần hóa đơn theo tiền.
- Request ID + digest + lease ngăn gửi trùng, chặn đổi nội dung cùng ID, giữ kết quả
  để retry khi mất phản hồi. Mỗi UID chỉ có một request đang chạy. Client không gửi
  UID hoặc history tự dựng. Khóa tài khoản khi model đang chạy chặn commit trả lời.
- `expiresAt` chỉ là dữ liệu hỗ trợ cleanup; **chưa bật TTL policy**. Lịch sử và dữ liệu
  giới hạn/request vẫn cần quy trình lưu giữ/xóa dữ liệu trước phát hành production.

## Kiểm tra

```powershell
npm.cmd --prefix functions test
npm.cmd --prefix functions run check
flutter analyze --no-pub
flutter test --no-pub
# Với Java 21 ở PATH:
npm.cmd exec --package=firebase-tools@15.34.2 -- firebase emulators:exec --only auth,firestore,functions --project demo-bepxinh --config firebase.ai.local.json "node --test functions/test/*.test.mjs && node functions/tool/seed-local.mjs && node functions/tool/http-smoke.mjs && node ../admin_bep_xinh/tests/browser-emulator.cjs"
flutter test --no-pub test/features/ai_chat_visual_test.dart --dart-define=UI_CAPTURE_AI=true
```

Test dùng provider stub và tài khoản demo, không tiêu quota API thật. Ảnh kiểm tra
app tại `build/ui_ux/ai_chat/`, admin tại `node_modules/.cache/admin-smoke/` repo admin.

### Kết quả bàn giao local ngày 17/11/2026

- Flutter analyzer sạch; toàn bộ suite đạt 371 test, 4 test chụp ảnh bỏ qua theo cờ mặc định.
- Lượt kiểm tra tập trung cuối đạt 13 test AI và yêu cầu khách hàng.
- Bộ backend chạy trong emulator đạt 13 test; HTTP smoke đạt 11 kiểm tra.
- Admin build, lint trong phạm vi thay đổi và kiểm tra trình duyệt với emulator đạt.
- Build Flutter web debug với `lib/main_local.dart` thành công; ảnh AI đã kiểm tra
  ở light/dark, chiều rộng 390/800. Avatar và prompt nằm trong [AI_AVATAR.md](AI_AVATAR.md).
- Các test provider dùng stub. Chưa xác nhận key/model/endpoint thật; cần nhập key
  tại admin local rồi dùng chức năng kiểm tra kết nối. Không có dịch vụ local nào
  được giữ chạy sau kiểm thử; khởi động theo các lệnh phía trên.

## Khi chuyển production (chưa làm)

Chỉ sau khi project bật Blaze: tạo Secret Manager `AI_CONFIG_ENCRYPTION_KEY`, deploy
riêng codebase Functions `bep-xinh-ai` và rules đã kiểm thử; cấu hình key qua admin.
Kiểm tra IAM, TTL/lưu giữ dữ liệu, quota provider, model và endpoint live trước khi
phát hành app/admin. Không coi build local là bằng chứng API production chạy.

Tham khảo: [Gemini API](https://ai.google.dev/api),
[Firebase runtime](https://firebase.google.com/docs/functions/manage-functions),
[Firebase secrets](https://firebase.google.com/docs/functions/config-env).
Tham số Chat Completions: [OpenAI API reference](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create).
