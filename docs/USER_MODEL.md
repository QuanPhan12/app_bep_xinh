# Model user Bếp Xinh

Model chính: `lib/features/profile/models/user_profile.dart`.
`profile_data.dart` re-export model để các màn hiện tại giữ nguyên import/API.

## Schema 1

Document `users/{uid}` dùng Firebase Auth UID làm khóa; trường `id` phải trùng UID và document ID.
Email, mật khẩu, token và trạng thái xác minh email do Firebase Auth quản lý, không sao chép vào hồ sơ.

| Trường | Kiểu | Nguồn/quyền sửa |
| --- | --- | --- |
| schemaVersion | int = 1 | Khởi tạo, sau đó bất biến với client |
| id | string | UID Firebase Auth, bất biến |
| name | string, 1–60 ký tự | Người dùng |
| handle | string, tối đa 132 ký tự | Khởi tạo `bep_{uid đầy đủ}`, client không đổi |
| bio | string, tối đa 200 ký tự | Người dùng |
| showBio | bool | Người dùng |
| avatarUrl | HTTPS URL hoặc null | Dự trữ cho luồng ảnh; client hiện chưa có thao tác sửa |
| cookedCount | int >= 0 | Dữ liệu nghiệp vụ đáng tin cậy, client không tự tăng |
| role | user / moderator / admin | Backend/quản trị đáng tin cậy |
| status | active / locked | Backend/quản trị đáng tin cậy |
| createdAt | Timestamp | Server timestamp khi tạo |
| updatedAt | Timestamp | Server timestamp khi lưu |
| lastLoginAt | Timestamp hoặc null | Dự trữ cho backend Auth, hiện chưa tự cập nhật |
| lockedAt | Timestamp hoặc null | Backend/quản trị |
| lockReason | string tối đa 500 ký tự hoặc null | Lý do có thể hiển thị cho chủ tài khoản |

Handle mặc định dùng UID đầy đủ để tránh trùng do cắt tám ký tự đầu. Đây chưa phải luồng chọn username
cá nhân hay giữ chỗ username. Các handle cũ vẫn giữ nguyên khi đọc.

`avatarAsset` chỉ phục vụ fixture/mock và không nằm trong schema ghi Firestore.
Phần hiển thị avatar URL chưa được triển khai trong lần chuẩn hóa model này.

## Parse và serialize

- `UserProfile.fromJson` kiểm tra giới hạn trường, enum, schema và metadata thời gian.
- JSON dùng ISO-8601 có timezone; trong domain giữ `DateTime` UTC.
- `UserDocumentCodec` chuyển Firestore `Timestamp` và kiểm tra document ID. Model không import Firebase.
- `toJson()` phục vụ export/transport; **không dùng làm payload cập nhật toàn bộ document từ client**.
- `toProfileUpdateJson()` chỉ có `name`, `bio`, `showBio`. `copyWith` chỉ cho sửa các trường này,
  giữ nguyên role/status và metadata quản trị.
- Vai trò/trạng thái lạ hoặc schema mới chưa hỗ trợ bị từ chối, không tự quy về user đang hoạt động.

Khi `status == locked` phải có `lockedAt`. Khi `active`, `lockedAt` và `lockReason` phải null.
Model không giữ lịch sử khóa trong cùng document; ghi chú nội bộ và audit cho quản trị cần thiết kế riêng.

## Tương thích và tạo mới

Hồ sơ cũ thiếu `schemaVersion` đọc như schema 0: vai trò user, trạng thái active nếu không có metadata,
không bịa timestamp còn thiếu. Không tự ghi đè hay chạy migration trên tài khoản cũ.
Nếu hồ sơ cũ đã có role/status thì vẫn kiểm tra và giữ các giá trị đó.

Tài khoản mới được `FirestoreUserStore` tạo bằng transaction, role user/status active và các trường
chưa có dữ liệu để null. Đăng ký đợi hồ sơ Firestore được tạo trước khi báo thành công;
đăng nhập tạo bù nếu tài khoản Auth đã có nhưng thiếu document, không ghi đè hồ sơ cũ.
Sau khi tạo phải đọc lại timestamp đã được server xác nhận, không parse sentinel `FieldValue` thành ngày giờ.

## Quyền và giới hạn hiện tại

Rules chỉ cho client tạo tài khoản của chính mình ở trạng thái active/role user.
Người dùng không được tự sửa role, status, dữ liệu khóa, handle, UID hoặc timestamp quản trị.
Tài khoản locked không được cập nhật hồ sơ hoặc đọc/ghi/xóa danh sách yêu thích;
vẫn được đọc hồ sơ của chính mình để có thể hiển thị trạng thái/lý do khóa.

Portal `../admin_bep_xinh` dùng role/status từ hồ sơ và Firestore Rules để kiểm tra
quyền tại database. Admin active được liệt kê tài khoản và sửa role/status/metadata khóa
của tài khoản khác; không được tự thay quyền hoặc khóa mình. Moderator chỉ được đọc
hồ sơ theo UID để kiểm tra bài, không liệt kê hoặc sửa tài khoản.
Chưa có API thu hồi token Firebase Auth hoặc khóa đăng nhập Auth; khóa hồ sơ chặn
thao tác dữ liệu theo Rules, không đồng nghĩa vô hiệu hóa tài khoản Authentication.

App dùng `AccountGuardAuthService` bọc Firebase Auth và
`FirestoreAccountAccessSource` theo dõi `users/{uid}` realtime. UID chỉ được đưa
cho router/service khi hồ sơ hợp lệ và server xác nhận `status == active`.
Áp dụng cả phiên khôi phục khi mở app, đăng ký và đăng nhập mới.
Khi đăng nhập/đăng ký, xác minh chạy trong thời gian form đang loading; không
chuyển sang màn kiểm tra trung gian. Chỉ khi xác nhận bị khóa hoặc có lỗi xác minh
mới rời form. Các route nội dung vẫn không được mở trước khi xác nhận active.
`locked` chuyển toàn bộ router sang `/account-access`, hiển thị lý do khóa và
nút đăng xuất; các service riêng được tạo lại theo UID để bỏ dữ liệu phiên trước.
Khi admin mở khóa, listener xác nhận active thì app mới mở lại phiên.

Cache active hoặc snapshot có pending writes không được dùng để cấp truy cập.
Nếu đang offline/chưa xác minh, app giữ ở màn kiểm tra; sau 15 giây có nút thử lại
và luôn có thể đăng xuất. Đây là chính sách cần xác nhận online cho tài khoản đã
đăng nhập, không hỗ trợ mở nội dung riêng bằng cache khi offline.
Firebase Auth có thể vẫn trả credential/token đúng cho tài khoản có hồ sơ locked;
guard chặn phiên ứng dụng, còn Rules chặn thao tác dữ liệu. Tắt Auth/revoke token
nếu cần phải thực hiện bằng backend tin cậy riêng.

Sau khi cập nhật `main.dart` cần Hot Restart/chạy lại ứng dụng, Hot Reload không
khởi tạo lại guard cho phiên đang chạy bản cũ. Artifact đã phát hành cũng phải build
và phát hành app mới; deploy Rules không tự thay code Flutter trên thiết bị.

## Xác minh

Test model kiểm tra JSON roundtrip, UTC, hồ sơ cũ, enum sai, metadata khóa, URL ảnh,
payload whitelist và document UID mismatch. Smoke emulator kiểm tra role/status không tự sửa được,
không thể tự mở khóa và các thao tác dữ liệu bị chặn khi locked; không khóa user production để thử.
Test `account_guard_auth_service_test.dart` kiểm tra cold start, khóa/mở realtime,
UID cũ, lỗi listener, timeout và router gỡ màn riêng khi locked.
`tool/account_access_sdk_smoke.dart` và browser runner `--account-access` kiểm tra
Firestore SDK thật và UI trên Chrome qua project demo, gồm cache offline.

Kết quả 09/11/2026: analyzer sạch, 201 test Flutter đạt, 43 kiểm tra emulator đạt;
SDK thật trên Chrome đọc/lưu user schema 1 thành công. Rules tương thích đã được deploy.
