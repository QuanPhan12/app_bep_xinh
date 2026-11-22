# Đăng và duyệt công thức

## Luồng và ranh giới

`Screen → RecipeEditorCubit → RecipeEditorService → uploader/repository`.
`FirestoreRecipeEditorService` điều phối validation, upload, codec và ghi dữ liệu;
`CloudinaryRecipeImageUploader` gọi HTTP, `FirestoreRecipeAuthoringRepository`
quản lý transaction. Service được tạo lại khi UID thay đổi. Cubit giữ form,
trạng thái thao tác và tiến độ; widget không gọi trực tiếp Firebase/Cloudinary.

1. Đăng nhập tài khoản active, mở nút `+`; tải danh mục và nháp đang có.
2. Lưu nháp kể cả chưa hoàn tất. Ảnh được upload trước, Firestore chỉ lưu URL/publicId.
3. Gửi: validate bằng model công thức và danh mục, upload ảnh còn thiếu, transaction
   tạo `pending` và xóa nháp. Mất phản hồi có thể thử lại cùng ID/hash.
4. Profile → Cài đặt → **Bài đã gửi**: xem chờ duyệt/đã duyệt/bị từ chối và lý do.
5. Admin/moderator active duyệt trong portal `../admin_bep_xinh`, hoặc người có IAM
   dùng công cụ bên dưới. Kết quả và audit được ghi trong cùng transaction.
6. `approved` được Home lấy realtime từ chính document đó, không sao chép bài.
7. Sửa bài bị từ chối tạo nháp với submission ID mới và `revisionOf` trỏ bài cũ;
   gửi lại vẫn phải duyệt. Không sửa lịch sử đã xét duyệt.
8. Profile → **Quản lý bài đăng** (hoặc Cài đặt → Bài đã gửi): chủ bài có thể
   ẩn bài đã duyệt, hiện lại bài tự ẩn hoặc xóa bài ở mọi trạng thái chưa xóa.
   Xóa cần xác nhận và chuyển thành `deleted`, không có khôi phục trong app.
   Nội dung, audit và subcollection được giữ để bảo toàn lịch sử; không phải xóa
   vật lý Firestore/Cloudinary và không thay thế quy trình xóa dữ liệu tài khoản.
9. Admin có quyền ẩn bài đã duyệt (bắt buộc lý do), tiếp nhận bài tác giả đang ẩn,
   và hiện lại bài do admin ẩn. Tác giả không được vượt quyết định ẩn của admin;
   admin không tự hiện lại bài tác giả đã ẩn hoặc xóa. Moderator không có quyền này.

## Hợp đồng Firestore

`RecipeContent.isBanner` là boolean, mặc định `false` cho bài mới/bài cũ thiếu trường.
Chỉ admin quyết định banner trên `recipes/{id}` qua portal (Rules kiểm tra role/status)
hoặc quyền IAM/trusted backend.
Màn Đăng món không có tùy chọn này; bản nháp không sở hữu trường quản trị.
Payload gửi duyệt luôn có `isBanner: false`; rules từ chối tác giả tự gửi `true`.
`isBanner` ở cấp gốc document là cờ duy nhất có hiệu lực; giá trị trong `content`
không được dùng để quyết định banner. Công cụ duyệt không thay đổi cờ admin đã chọn.
Admin active có thể đổi `recipes/{id}.isBanner` trong portal cho bài approved.
Moderator không được sửa banner. Console với quyền IAM vẫn có thể cập nhật trực tiếp.
Home query riêng `status == approved && isBanner == true`, mới nhất trước, tối đa
10 banner; dùng ảnh bìa, tên, mô tả và tổng thời gian chuẩn bị/nấu. Chạm banner mở
chi tiết đúng công thức. Không có bài đủ điều kiện thì ẩn carousel; production không
dùng banner mẫu local để thay thế. Query sắp xếp theo `submittedAt`, vốn đã có khi
gửi bài; admin không cần bổ sung `publishedAt`. Cần index status/isBanner/submittedAt.

Home dùng `PublishedRecipeSource.watchPublished()` và `watchBanners()` qua Firestore
`snapshots()`. Service kết hợp hai snapshot thành `HomeFeed`; Cubit cập nhật bài/banner
trong state hiện tại, giữ category và summary, không bật lại skeleton khi có bài mới.
Snapshot đến trong lúc tải/refresh được giữ để kết quả đọc cũ không ghi đè dữ liệu mới.
Thay tên/ảnh bài, admin bật/tắt banner và xóa bài đều cập nhật mà không kéo refresh.
Xóa hết kết quả query sẽ xóa đúng nội dung đang hiển thị; lỗi listener giữ dữ liệu cũ
và báo lỗi, không giả lập một danh sách rỗng. SDK tự quản lý kết nối lại khi mạng phục hồi.
Chuyển đổi async có revision để bỏ kết quả cũ; hủy listener khi Cubit đóng hoặc UID đổi.
Home production không dùng bài mẫu local; fixture vẫn dùng trong kiểm thử.

Xác minh realtime 09/11/2026: analyzer sạch, 222 test Flutter đạt. SDK Chrome với
emulator xác nhận admin đổi tên bài, bật banner, tắt banner và xóa bài đều cập nhật
`HomeCubit` qua listener mà không gọi lại `loadHome`/refresh. Test còn kiểm tra snapshot
đến trong refresh, kết quả async cũ, giữ bộ lọc, lỗi mạng và hủy subscription.
Không tạo hoặc sửa bài production trong bộ kiểm thử này.

Kiểm chứng trường banner: giao diện không có công tắc; payload tác giả mặc định
`false`, kể cả khi tạo bản sửa từ nội dung có `true`. Rules smoke chặn tác giả tự
gửi bài hoặc cập nhật bản công khai với `true`, cho phép trusted IAM đặt cờ.
SDK Chrome kiểm tra bài pending và bài chưa được admin chọn không vào query banner.
Mapping banner dùng đúng ID, ảnh Cloudinary và tổng thời gian.
Rules/index banner đã triển khai; truy vấn banner công khai trên production đã
chạy thành công ngày 09/11/2026 (hiện 0 bài phù hợp), không tạo bài thử production.

```text
users/{uid}/recipe_drafts/current
  schemaVersion: 1, authorId, submissionId, revision, revisionOf
  draft: null | RecipeDraftCodec map, updatedAt: server timestamp

recipes/{submissionId}
  schemaVersion: 2, id, authorId, status: pending | approved | rejected | hidden | deleted
  author: {id, name, handle}, isBanner: false | true
  revisionOf: null | rejectedSubmissionId
  content: RecipeContent map, contentHash: SHA256, catalogVersion
  submittedAt, reviewedAt, reviewedBy, reviewReason
  visibilityEventId?, visibilityActor?, visibilityRole?: author | admin
  visibilityReason?: null | string, visibilityAt?: server timestamp

recipes/{submissionId}/visibility_events/{eventId}
  actor, role: author | admin, reason: null | string
  fromStatus, toStatus, createdAt: server timestamp
  audit bất biến, chỉ tác giả và staff đọc; bắt buộc ghi cùng transaction đổi trạng thái

recipe_moderation_events/{submissionId}
  bản ghi quyết định do portal admin/moderator hoặc công cụ IAM tạo trong cùng transaction
```

Ảnh remote: `{id, name, url, publicId}`; chỉ HTTPS
`res.cloudinary.com/ddqouziau/image/upload/...`. Không lưu bytes/base64 vào Firestore.
Content bị giới hạn 400 KB để chừa khoảng trống dưới giới hạn document Firestore.
Nguyên liệu dùng ID/đơn vị từ danh mục; nguyên liệu tự nhập giữ ID danh mục null.

Mỗi tài khoản có một nháp hiện hành. Revision phát hiện xung đột giữa các phiên;
khi có xung đột phải mở lại trình soạn thay vì ghi đè. Lưu/gửi được tuần tự hóa
trong service. Transaction submit so sánh submission ID, revision và hash;
ảnh đã upload được tái sử dụng khi thử lại trong phiên.

Rules chỉ cho chủ tài khoản active ghi nháp và tạo bài pending với isBanner false.
Bài pending/rejected chỉ tác giả và staff active đọc; approved được đọc công khai.
Người dùng không được sửa nội dung, tự duyệt hoặc bật banner. Quyền đổi trạng thái
hiển thị chỉ chạm status/isBanner và metadata visibility, kèm audit trong cùng commit;
xóa vật lý vẫn bị từ chối. Tất cả hide/restore/delete đều đặt `isBanner: false`;
hiện lại không tự bật banner. Portal staff chỉ đổi metadata duyệt cùng audit;
admin được đổi cờ banner của bài approved và quản lý ẩn bài như trên.
Owner query loại `deleted` trước limit bằng status `whereIn`, dùng index sẵn có
`status/authorId/submittedAt`. Feed, banner, tìm kiếm và public profile chỉ lấy
`approved`; đọc trực tiếp bài/review/điểm của bài ẩn/xóa không được phép với guest.
Không thu hồi được nội dung/ảnh đã tải trước đó hay ảnh Cloudinary URL công khai.
`recipe_submissions` cũ không còn
được app đọc/ghi và bị rules mặc định từ chối.
Rules kiểm tra envelope, metadata và giới hạn cơ bản; validator tin cậy của công cụ
duyệt kiểm tra toàn bộ nhóm/nguyên liệu/bước/ảnh trước khi đổi status. Đổi trực tiếp
trong Console dùng quyền IAM sẽ bỏ qua validator của công cụ, nên admin phải tự kiểm tra dữ liệu.
Không dựa vào vai trò do client gửi để duyệt. Bản công khai đọc được không cần đăng nhập.
Hồ sơ `users` vẫn riêng tư; hồ sơ công khai dùng snapshot tác giả đã duyệt.

## Cloudinary

- Cloud name: `ddqouziau`; unsigned upload preset: `bep_xinh`.
- App không cần API secret. Hai định danh này là công khai, nằm trong uploader.
- Preset phải bật **Unsigned**, chỉ nhận ảnh jpg/jpeg/png/webp và giới hạn tối đa
  8 MB. Kiểm tra lại các giới hạn này trong Cloudinary Console; giới hạn client
  không bảo vệ trước người gọi API trực tiếp.
- Nên cấu hình folder, giới hạn kích thước ảnh, kiểm soát quota và cảnh báo chi phí
  tại Cloudinary. Không cho phép preset nhận kiểu tài nguyên khác.
- Upload production gắn tag `bep_xinh_recipe`; smoke thật gắn `bep_xinh_sdk_smoke`.

Unsigned upload không xác thực Firebase UID. Người biết preset có thể upload ngoài
app; đây chưa phải giải pháp chống lạm dụng upload. Khi cần kiểm soát theo tài khoản,
quota hoặc quyền sở hữu ảnh, chuyển sang endpoint ký upload có kiểm tra phiên phía server.
Ảnh Cloudinary có URL công khai kể cả khi bài còn pending; quyền riêng tư bài Firestore
không làm ảnh riêng tư. Không dùng luồng này cho ảnh nhạy cảm.

Upload thành công nhưng ghi nháp lỗi có thể để lại ảnh mồ côi. Chưa có worker dọn ảnh
hoặc API xóa ảnh; vận hành phải rà soát bằng Cloudinary Console/trusted backend,
đối chiếu publicId đang được tham chiếu trước khi xóa. Không đưa API secret vào Flutter.
Các ảnh smoke thật có thể dọn theo tag riêng sau kiểm thử.

## Duyệt bằng IAM

Cần Node.js, Firebase CLI login và quyền IAM đọc/ghi Firestore trên đúng project.
Đây là công cụ vận hành; không phân phối credentials IAM cùng app. Portal admin dùng
Firebase Auth client và Rules, không nhận credentials IAM trong browser.
Người duyệt phải tự xem toàn bộ nội dung/ảnh, an toàn thực phẩm và quyền sử dụng ảnh.
Validator schema không thay cho quyết định kiểm duyệt nội dung.

```powershell
# Đăng nhập bằng tài khoản vận hành của bạn
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase login
# Liệt kê tối đa 50 bài pending
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/review_recipe_submission.cjs --project bepxinh-b0be7 --list
# Kiểm tra cấu trúc, KHÔNG ghi dữ liệu (mặc định dry run)
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/review_recipe_submission.cjs --project bepxinh-b0be7 --id r_REPLACE --decision approve
# Chỉ chạy sau khi đã kiểm tra nội dung thật
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/review_recipe_submission.cjs --project bepxinh-b0be7 --id r_REPLACE --decision approve --apply
# Hoặc từ chối, bắt buộc nêu lý do
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/review_recipe_submission.cjs --project bepxinh-b0be7 --id r_REPLACE --decision reject --reason "Bổ sung định lượng và các bước còn thiếu" --apply
```

Công cụ đọc `recipes/{id}`, tác giả active và catalog trong transaction, kiểm tra schema,
ghi quyết định trên cùng document và audit nguyên tử. Precondition chặn duyệt hai lần;
retry tối đa ba lần khi xung đột. ReviewedBy là hash định danh người IAM đăng nhập.
Không ghi token, email người duyệt hay request body vào log.

Console có thể chỉ đổi `status: approved`; không bắt buộc metadata duyệt để Home
hiển thị. Khi cần lý do và audit rõ ràng, dùng công cụ duyệt. Để gỡ khỏi Home,
admin đổi sang `rejected`; muốn bỏ banner nhưng vẫn giữ bài, đặt `isBanner: false`.

## Chuyển dữ liệu cũ về một collection

```powershell
node tool/unified_recipe_migration_test.cjs
# Chỉ đọc và in kế hoạch
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/migrate_unified_recipes.cjs --project bepxinh-b0be7
# Chuyển dữ liệu sau khi triển khai rules/indexes mới
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/migrate_unified_recipes.cjs --project bepxinh-b0be7 --apply
```

Script lưu bản sao nguồn trong `build/firestore-migrations/` trước khi ghi, giữ ID,
nội dung, trạng thái, thời điểm gửi và thông tin tác giả công khai. `published` cũ
được chuẩn hóa thành `approved`; pending/rejected giữ nguyên. Cờ banner chỉ lấy từ
cấp gốc do admin quản lý, không nâng cờ trong content của form cũ thành quyền admin.
Sao chép sang document chuẩn và xóa nguồn cũ trong cùng commit với precondition
updateTime; có xung đột thì dừng, không ghi đè. Kiểm tra lại dữ liệu sau commit.
Chạy lại bỏ qua document schema 2 đã chuyển xong. Bản sao trong build không lên Git.

Đã chuyển dữ liệu thật ngày 09/11/2026: một bài được giữ nguyên ID/nội dung, status
`published` cũ thành `approved`; collection cũ trống. Truy vấn bằng quyền khách
đọc được một bài approved với nội dung hợp lệ. Có bản sao trước chuyển trong build.
Analyzer sạch, 222 test Flutter và 29 kiểm tra rules/duyệt bài đạt; test chuyển dữ liệu
và SDK Chrome đạt. SDK xác nhận chỉ đổi `status` trên document pending thành approved
là stream lấy được bài, không thêm publishedAt hay tạo document thứ hai. Web release build đạt.

Triển khai rules/indexes trước khi chạy app:

```powershell
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase deploy --only firestore --project bepxinh-b0be7 --non-interactive
```

Indexes recipes: authorId/submittedAt, status/submittedAt, status/authorId/submittedAt
và status/isBanner/submittedAt. Chờ composite indexes READY trước khi phát hành.
Index publishedAt/recipe_submissions cũ tạm giữ cho việc chuyển đổi; app không dùng chúng.

## Kiểm thử

```powershell
flutter analyze --no-pub
flutter test --no-pub
# Terminal emulator cần Java 21+
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase emulators:start --only auth,firestore --project demo-bepxinh
# Terminal khác: seed catalog và kiểm tra rules/session, rồi kiểm tra duyệt bài
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
node tool/firebase_emulator_smoke.cjs
node tool/recipe_publishing_emulator_smoke.cjs
# Flutter SDK + Chrome thật, mặc định dùng uploader fixture
flutter build web --debug --no-wasm-dry-run --target tool/recipe_publishing_sdk_smoke.dart --output build/recipe-publishing-smoke-web
node tool/firebase_sdk_browser_smoke.cjs --publishing
```

Muốn kiểm tra Cloudinary thật, thêm `--dart-define=LIVE_CLOUDINARY_SMOKE=true` khi build
smoke. Lệnh này tạo ảnh thật có tag `bep_xinh_sdk_smoke`; Firebase vẫn cố định emulator
`demo-bepxinh`. Không deploy artifact smoke; app chính dùng entrypoint `lib/main.dart`.
Browser runner cần Python/Chrome, tự dùng profile mới rồi đóng tiến trình của nó.

Đã kiểm chứng SDK trên Chrome với upload Cloudinary thật: lưu/đọc URL ảnh,
khôi phục nháp, xung đột revision, submit thử lại, pending không xuất hiện công khai,
duyệt nguyên tử và đọc công thức đã duyệt. Firebase test không tạo user/bài production.

Kết quả ngày 09/11/2026: analyzer sạch, 213 test Flutter đạt, 43 kiểm tra Auth/Firestore
và 23 kiểm tra đăng/duyệt bài đạt trên emulator; app chính build web release thành công.
Rules/indexes đã deploy lên `bepxinh-b0be7`; các composite indexes ở trạng thái READY.

## Giới hạn hiện tại

Home/tìm kiếm đọc tối đa 100 bài đã duyệt mỗi lượt; Bài đã gửi đọc tối đa 50 bài.
Home có realtime cho bài/banner; tìm kiếm, Profile và Tủ lạnh hiện tải lại khi mở/refresh.
Chưa có pagination, sửa bài đã duyệt, thu hồi bài công khai qua UI hoặc thông báo
push/email khi có quyết định. Công thức mẫu trong bundle vẫn được gộp để giữ nội dung app.
Chưa có rate limit đăng bài phía server, App Check bắt buộc hay signed image upload.
Không gọi các giới hạn client là cơ chế chống spam. Android/iOS chưa được kiểm tra trên
thiết bị thật cho luồng mới; kết quả SDK ở đây là web Chrome + Firebase emulator.

Root `remix` tùy chọn ghi nguồn bản biến tấu; rules đối chiếu nguồn approved và tác giả/hash. Xem [RECIPE_REMIX.md](RECIPE_REMIX.md).
